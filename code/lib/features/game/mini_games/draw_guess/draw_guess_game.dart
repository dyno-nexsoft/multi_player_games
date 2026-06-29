import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Vẽ & Đoán — người vẽ dùng ngón tay, người kia gõ đáp án.
/// 5 từ, xen kẽ vai trò. Đoán đúng = +10 người đoán, +5 người vẽ.
/// Stroke data throttled 30 Hz qua network.
class DrawGuessGame extends BaseMiniGame {
  static const int _totalWords = 5;
  static const double _roundDuration = 60.0;
  static const double _strokeInterval = 1 / 30;

  DrawGuessGame(super.gameProvider);

  @override
  String get gameId => GameIds.drawGuess;

  // ── State ──────────────────────────────────────────────────────────────────

  bool _myTurnToDraw = false;
  bool get myTurnToDraw => _myTurnToDraw;

  String _currentWord = '';
  String get currentWord => _currentWord;

  String _wordHint = '';
  String get wordHint => _wordHint;

  int _wordIndex = 0;
  double _timeLeft = _roundDuration;
  double get timeLeft => _timeLeft;

  bool _roundActive = false;
  bool _gameOver = false;

  final Map<String, int> _scores = {};
  Map<String, int> get scores => Map.unmodifiable(_scores);

  // Strokes: list of polylines (normalised 0–1 coordinates)
  final List<List<Offset>> _strokes = [];
  List<List<Offset>> get strokes => _strokes;

  List<Offset> _currentStroke = [];
  double _throttleTimer = 0;

  String _statusText = '';
  String get statusText => _statusText;

  String _resultText = '';
  String get resultText => _resultText;

  Color _resultColor = Colors.transparent;
  Color get resultColor => _resultColor;

  void _notify() => notifyOverlay();

  // ── Word list ─────────────────────────────────────────────────────────────

  static const _words = [
    'cat',
    'dog',
    'house',
    'tree',
    'car',
    'sun',
    'moon',
    'fish',
    'bird',
    'hat',
    'book',
    'cake',
    'star',
    'boat',
    'rain',
    'shoe',
    'door',
    'ball',
    'fire',
    'ship',
    'key',
    'cup',
    'lamp',
    'clock',
    'flower',
  ];

  late List<String> _shuffled;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
    if (gameProvider.lobbyProvider.isHost) {
      _shuffled = List.of(_words)..shuffle(Random());
      _startWord();
    } else {
      _statusText = 'Chờ từ...';
    }
  }

  // wordIndex % 2 == 0 → host draws; % 2 == 1 → client draws
  bool _hostDrawsThisWord(int idx) => idx % 2 == 0;

  void _startWord() {
    if (_wordIndex >= _totalWords) {
      _finishGame();
      return;
    }
    _strokes.clear();
    _currentStroke = [];
    _timeLeft = _roundDuration;
    _roundActive = true;
    _resultText = '';
    _resultColor = Colors.transparent;

    final drawerIsHost = _hostDrawsThisWord(_wordIndex);
    _myTurnToDraw = drawerIsHost; // host sets own flag directly
    _currentWord = _shuffled[_wordIndex];
    _wordHint = _buildHint(_currentWord);

    _statusText = _myTurnToDraw
        ? 'Vẽ: "$_currentWord"'
        : 'Đoán từ: ${_wordHint.trim()}';

    gameProvider.sendGameData(gameId, {
      'action': 'new_word',
      'word_index': _wordIndex,
      'word': _currentWord,
      'word_hint': _wordHint,
      'drawer_is_host': drawerIsHost,
    });
    _notify();
  }

  static String _buildHint(String word) =>
      word.split('').map((_) => '_').join(' ');

  // ── Timer ─────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !_roundActive) return;

    _timeLeft = (_timeLeft - dt).clamp(0, _roundDuration);

    if (_myTurnToDraw && _throttleTimer > 0) {
      _throttleTimer = (_throttleTimer - dt).clamp(0, _strokeInterval);
    }

    if (gameProvider.lobbyProvider.isHost && _timeLeft <= 0) {
      _onWordTimeUp();
      return;
    }
    _notify();
  }

  void _onWordTimeUp() {
    if (!_roundActive) return;
    _roundActive = false;
    _resultText = 'Hết giờ! Từ là: "$_currentWord"';
    _resultColor = Colors.orange;
    _notify();

    gameProvider.sendGameData(gameId, {
      'action': 'word_over',
      'word_index': _wordIndex,
      'word': _currentWord,
    });

    _wordIndex++;
    Future.delayed(const Duration(seconds: 3), _startWord);
  }

  // ── Drawing input ─────────────────────────────────────────────────────────

  void onDrawStart(Offset normalised) {
    if (!_myTurnToDraw || !_roundActive) return;
    _currentStroke = [normalised];
    _strokes.add(_currentStroke);
    _sendStroke(normalised, isNewStroke: true);
    _notify();
  }

  void onDrawUpdate(Offset normalised) {
    if (!_myTurnToDraw || !_roundActive || _currentStroke.isEmpty) return;
    _currentStroke.add(normalised);
    _notify();
    if (_throttleTimer <= 0) {
      _throttleTimer = _strokeInterval;
      _sendStroke(normalised, isNewStroke: false);
    }
  }

  void clearCanvas() {
    if (!_myTurnToDraw) return;
    _strokes.clear();
    _currentStroke = [];
    gameProvider.sendGameData(gameId, {'action': 'clear_canvas'});
    _notify();
  }

  void _sendStroke(Offset pos, {required bool isNewStroke}) {
    gameProvider.sendGameData(gameId, {
      'action': 'stroke_point',
      'x': pos.dx,
      'y': pos.dy,
      'is_new_stroke': isNewStroke,
    });
  }

  // ── Guess input ───────────────────────────────────────────────────────────

  void submitGuess(String text) {
    if (_myTurnToDraw || !_roundActive || _gameOver) return;
    final guess = text.trim().toLowerCase();
    if (guess.isEmpty) return;

    if (gameProvider.lobbyProvider.isHost) {
      _checkGuess(guess, gameProvider.lobbyProvider.localPlayer!.id);
    } else {
      gameProvider.sendGameData(gameId, {'action': 'guess', 'text': guess});
    }
  }

  void _checkGuess(String guess, String guesserId) {
    if (!_roundActive || _gameOver) return;
    if (guess != _currentWord.toLowerCase()) return;

    _roundActive = false;
    final drawerIsHost = _hostDrawsThisWord(_wordIndex);
    final players = gameProvider.lobbyProvider.players;
    final drawerId = drawerIsHost
        ? players.firstWhere((p) => p.isHost, orElse: () => players.first).id
        : players.firstWhere((p) => !p.isHost, orElse: () => players.last).id;

    _scores[guesserId] = (_scores[guesserId] ?? 0) + 10;
    _scores[drawerId] = (_scores[drawerId] ?? 0) + 5;

    AppAudio.playGoal();
    HapticFeedback.lightImpact();

    gameProvider.sendGameData(gameId, {
      'action': 'guess_correct',
      'word_index': _wordIndex,
      'word': _currentWord,
      'guesser_id': guesserId,
      'drawer_id': drawerId,
      'scores': Map<String, dynamic>.from(_scores),
    });

    _resultText = 'Đúng! Từ là "$_currentWord" 🎉';
    _resultColor = Colors.green;
    _notify();

    _wordIndex++;
    Future.delayed(const Duration(seconds: 2), _startWord);
  }

  void _finishGame() {
    if (_gameOver) return;
    _gameOver = true;
    _roundActive = false;
    _statusText = 'Kết thúc!';
    _notify();

    gameProvider.sendGameData(gameId, {
      'action': 'game_over',
      'scores': Map<String, dynamic>.from(_scores),
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(Map.from(_scores));
    });
  }

  // ── Network ───────────────────────────────────────────────────────────────

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'new_word':
        final drawerIsHost = payload['drawer_is_host'] as bool;
        _wordIndex = payload['word_index'] as int;
        _myTurnToDraw = gameProvider.lobbyProvider.isHost
            ? drawerIsHost
            : !drawerIsHost;
        // Only give the actual word to the drawer; guesser sees hint only
        _currentWord = _myTurnToDraw ? payload['word'] as String : '';
        _wordHint = payload['word_hint'] as String? ?? '';
        _strokes.clear();
        _currentStroke = [];
        _timeLeft = _roundDuration;
        _roundActive = true;
        _resultText = '';
        _resultColor = Colors.transparent;
        _statusText = _myTurnToDraw
            ? 'Vẽ: "$_currentWord"'
            : 'Đoán từ: ${_wordHint.trim()}';
        _notify();

      case 'stroke_point':
        if (!_myTurnToDraw) {
          final x = (payload['x'] as num).toDouble();
          final y = (payload['y'] as num).toDouble();
          final isNew = payload['is_new_stroke'] as bool? ?? false;
          final pos = Offset(x, y);
          if (isNew || _strokes.isEmpty) {
            _strokes.add([pos]);
          } else {
            _strokes.last.add(pos);
          }
          _notify();
          // Host relays drawer's strokes to other clients (future 3+ player support)
          if (gameProvider.lobbyProvider.isHost) {
            gameProvider.sendGameData(gameId, payload);
          }
        }

      case 'clear_canvas':
        _strokes.clear();
        _notify();

      case 'guess':
        if (gameProvider.lobbyProvider.isHost) {
          _checkGuess(payload['text'] as String, senderId);
        }

      case 'guess_correct':
        if (!gameProvider.lobbyProvider.isHost) {
          _roundActive = false;
          final raw = payload['scores'] as Map?;
          raw?.forEach(
            (k, v) => _scores[k.toString()] = v is num ? v.toInt() : 0,
          );
          final word = payload['word'] as String;
          _resultText = 'Đúng! Từ là "$word" 🎉';
          _resultColor = Colors.green;
          _wordIndex = (payload['word_index'] as int) + 1;
          AppAudio.playGoal();
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!cancelled) _afterWordClient();
          });
        }

      case 'word_over':
        if (!gameProvider.lobbyProvider.isHost) {
          _roundActive = false;
          final word = payload['word'] as String;
          _resultText = 'Hết giờ! Từ là: "$word"';
          _resultColor = Colors.orange;
          _wordIndex = (payload['word_index'] as int) + 1;
          _notify();
          Future.delayed(const Duration(seconds: 3), () {
            if (!cancelled) _afterWordClient();
          });
        }

      case 'game_over':
        if (!_gameOver) {
          _gameOver = true;
          _roundActive = false;
          final raw = payload['scores'] as Map?;
          raw?.forEach(
            (k, v) => _scores[k.toString()] = v is num ? v.toInt() : 0,
          );
          _statusText = 'Kết thúc!';
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!cancelled) endMiniGame(Map.from(_scores));
          });
        }
    }
  }

  // Called on client after a word ends (either time up or correct guess)
  void _afterWordClient() {
    _strokes.clear();
    _resultText = '';
    if (_wordIndex >= _totalWords) {
      _gameOver = true;
      _statusText = 'Kết thúc!';
      _notify();
      Future.delayed(const Duration(seconds: 1), () {
        if (!cancelled) endMiniGame(Map.from(_scores));
      });
    } else {
      _statusText = 'Chờ từ tiếp theo...';
      _notify();
    }
  }


  Widget buildOverlay(BuildContext context) => _DrawGuessOverlay(game: this);
}

// ── Overlay widget ─────────────────────────────────────────────────────────

class _DrawGuessOverlay extends StatefulWidget {
  final DrawGuessGame game;
  const _DrawGuessOverlay({required this.game});

  @override
  State<_DrawGuessOverlay> createState() => _DrawGuessOverlayState();
}

class _DrawGuessOverlayState extends State<_DrawGuessOverlay> {
  final _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    _guessController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Container(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            _Header(game: g),
            Expanded(child: _Canvas(game: g)),
            _Footer(game: g, controller: _guessController),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DrawGuessGame game;
  const _Header({required this.game});

  @override
  Widget build(BuildContext context) {
    final timeColor = game.timeLeft <= 10 ? Colors.red : Colors.white;
    final localId = game.gameProvider.lobbyProvider.localPlayer?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Scores
          Expanded(
            child: Row(
              children: game.gameProvider.lobbyProvider.players.map((p) {
                final score = game.scores[p.id] ?? 0;
                final isMe = p.id == localId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(p.color),
                        child: Text(
                          p.name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: isMe ? Colors.yellow : Colors.white70,
                          fontSize: 14,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Timer
          Text(
            '${game.timeLeft.ceil()}s',
            style: TextStyle(
              color: timeColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Canvas ─────────────────────────────────────────────────────────────────

class _Canvas extends StatelessWidget {
  final DrawGuessGame game;
  const _Canvas({required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // White drawing surface
        GestureDetector(
          onPanStart: (e) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final size = box.size;
            final pos = e.localPosition;
            game.onDrawStart(Offset(pos.dx / size.width, pos.dy / size.height));
          },
          onPanUpdate: (e) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final size = box.size;
            final pos = e.localPosition;
            game.onDrawUpdate(
              Offset(pos.dx / size.width, pos.dy / size.height),
            );
          },
          child: Container(
            color: Colors.white,
            child: CustomPaint(
              painter: _StrokePainter(game.strokes),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Status / result overlay
        if (game.resultText.isNotEmpty)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: game.resultColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                game.resultText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        // Word / status chip
        Positioned(
          bottom: 8,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              game.statusText,
              style: TextStyle(
                color: game.myTurnToDraw ? Colors.yellow : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Clear button for drawer
        if (game.myTurnToDraw)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: game.clearCanvas,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stroke painter ─────────────────────────────────────────────────────────

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  const _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          final pt = Offset(
            stroke[0].dx * size.width,
            stroke[0].dy * size.height,
          );
          canvas.drawCircle(pt, 2, Paint()..color = Colors.black);
        }
        continue;
      }
      final path = Path();
      path.moveTo(stroke[0].dx * size.width, stroke[0].dy * size.height);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * size.width, stroke[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

// ── Footer ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final DrawGuessGame game;
  final TextEditingController controller;
  const _Footer({required this.game, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (game.myTurnToDraw) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Bạn đang vẽ — đối thủ đang đoán!',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập đáp án...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2D2D44),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                game.submitGuess(v);
                controller.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              game.submitGuess(controller.text);
              controller.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Gửi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
