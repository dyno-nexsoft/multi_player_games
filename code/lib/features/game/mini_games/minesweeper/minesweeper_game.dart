import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Minesweeper Race — 8×8 board, 10 mines, 60 giây.
/// Cả 2 tap cùng board → host validate → broadcast reveal.
/// Chạm mìn = -3 điểm. Reveal nhiều ô trống hơn thắng.
class MinesweeperGame extends BaseMiniGame {
  static const int _cols = 8;
  static const int _rows = 8;
  static const int _mines = 10;
  static const double _gameDuration = 60.0;

  MinesweeperGame(super.gameProvider);

  @override
  String get gameId => GameIds.minesweeper;

  // ── Board state ────────────────────────────────────────────────────────────
  late List<List<int>> _board; // -1 = mine, 0-8 = adjacent mines
  late List<List<bool>> _revealed;

  // ── Score per player ───────────────────────────────────────────────────────
  final Map<String, int> _scores = {};

  // ── Timer ──────────────────────────────────────────────────────────────────
  double _timeLeft = _gameDuration;
  bool _gameOver = false;

  String _statusText = 'Tap để reveal ô trống!';

  void _notify() => notifyOverlay();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (gameProvider.lobbyProvider.isHost) {
      _generateBoard();
      _broadcast();
    } else {
      _initEmptyBoard();
      _statusText = 'Chờ board...';
    }
  }

  void _initEmptyBoard() {
    _board = List.generate(_rows, (_) => List.filled(_cols, 0));
    _revealed = List.generate(_rows, (_) => List.filled(_cols, false));
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
  }

  void _generateBoard() {
    _initEmptyBoard();
    final rng = Random();
    int placed = 0;
    while (placed < _mines) {
      final r = rng.nextInt(_rows);
      final c = rng.nextInt(_cols);
      if (_board[r][c] != -1) {
        _board[r][c] = -1;
        placed++;
      }
    }
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_board[r][c] == -1) continue;
        _board[r][c] = _countAdjacentMines(r, c);
      }
    }
  }

  int _countAdjacentMines(int r, int c) {
    int count = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols) {
          if (_board[nr][nc] == -1) count++;
        }
      }
    }
    return count;
  }

  void _broadcast() {
    final flat = _board.expand((row) => row).toList();
    gameProvider.sendGameData(gameId, {'action': 'board_init', 'board': flat});
    _statusText = 'Tap để reveal ô trống!';
    _notify();
  }

  // ── Timer (host only) ─────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      if (gameProvider.lobbyProvider.isHost) {
        _finishGame();
      }
    }
    _notify();
  }

  // ── Input ─────────────────────────────────────────────────────────────────

  void onCellTap(int row, int col) {
    if (_gameOver || _revealed[row][col]) return;
    final localId = gameProvider.lobbyProvider.localPlayer!.id;
    if (gameProvider.lobbyProvider.isHost) {
      _processReveal(row, col, localId);
    } else {
      gameProvider.sendGameData(gameId, {
        'action': 'tap',
        'row': row,
        'col': col,
        'player_id': localId,
      });
    }
  }

  void _processReveal(int row, int col, String playerId) {
    if (_revealed[row][col] || _gameOver) return;
    _revealed[row][col] = true;

    if (_board[row][col] == -1) {
      _scores[playerId] = (_scores[playerId] ?? 0) - 3;
      AppAudio.playLose();
      HapticFeedback.heavyImpact();
    } else {
      _scores[playerId] = (_scores[playerId] ?? 0) + 1;
      AppAudio.playTap();
      HapticFeedback.lightImpact();
    }

    gameProvider.sendGameData(gameId, {
      'action': 'reveal',
      'row': row,
      'col': col,
      'player_id': playerId,
      'value': _board[row][col],
      'scores': _scores,
    });
    _notify();

    // Check all safe cells revealed
    final totalSafe = _rows * _cols - _mines;
    final revealed = _revealed.expand((r) => r).where((v) => v).length;
    if (revealed >= totalSafe) _finishGame();
  }

  void _finishGame() {
    if (_gameOver) return;
    _gameOver = true;
    _statusText = 'Hết giờ!';
    _notify();
    gameProvider.sendGameData(gameId, {
      'action': 'game_over',
      'scores': _scores,
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(Map.from(_scores));
    });
  }

  // ── Network ───────────────────────────────────────────────────────────────

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'board_init':
        final flat = (payload['board'] as List).cast<int>();
        for (int r = 0; r < _rows; r++) {
          for (int c = 0; c < _cols; c++) {
            _board[r][c] = flat[r * _cols + c];
          }
        }
        _statusText = 'Tap để reveal ô trống!';
        _notify();
      case 'tap':
        if (gameProvider.lobbyProvider.isHost) {
          _processReveal(
            payload['row'] as int,
            payload['col'] as int,
            payload['player_id'] as String,
          );
        }
      case 'reveal':
        _revealed[payload['row'] as int][payload['col'] as int] = true;
        if (payload['scores'] != null) {
          final rawScores = payload['scores'] as Map<String, dynamic>;
          rawScores.forEach((k, v) => _scores[k] = v is num ? v.toInt() : 0);
        }
        _notify();
      case 'game_over':
        if (!_gameOver) {
          _gameOver = true;
          if (payload['scores'] != null) {
            final rawScores = payload['scores'] as Map<String, dynamic>;
            rawScores.forEach((k, v) => _scores[k] = v is num ? v.toInt() : 0);
          }
          _statusText = 'Hết giờ!';
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!cancelled) endMiniGame(Map.from(_scores));
          });
        }
    }
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  Widget buildOverlay(BuildContext context) => _MinesweeperOverlay(game: this);
}

// ── Overlay Widget ─────────────────────────────────────────────────────────

class _MinesweeperOverlay extends StatefulWidget {
  final MinesweeperGame game;
  const _MinesweeperOverlay({required this.game});

  @override
  State<_MinesweeperOverlay> createState() => _MinesweeperOverlayState();
}

class _MinesweeperOverlayState extends State<_MinesweeperOverlay> {
  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final localId = g.gameProvider.lobbyProvider.localPlayer?.id;
    final timeColor = g._timeLeft <= 10 ? Colors.red : Colors.white;

    return Container(
      color: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 56, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    g._statusText,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '${g._timeLeft.ceil()}s',
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Scores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: g.gameProvider.lobbyProvider.players.map((p) {
                  final score = g._scores[p.id] ?? 0;
                  final isMe = p.id == localId;
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(p.color),
                        child: Text(
                          p.name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score',
                        style: TextStyle(
                          color: isMe ? Colors.yellow : Colors.white70,
                          fontSize: 16,
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Board
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MinesweeperGame._cols,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                    itemCount: MinesweeperGame._rows * MinesweeperGame._cols,
                    itemBuilder: (_, index) {
                      final row = index ~/ MinesweeperGame._cols;
                      final col = index % MinesweeperGame._cols;
                      return _Cell(
                        revealed: g._revealed[row][col],
                        value: g._board[row][col],
                        onTap: () => g.onCellTap(row, col),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final bool revealed;
  final int value;
  final VoidCallback onTap;

  const _Cell({
    required this.revealed,
    required this.value,
    required this.onTap,
  });

  static const _numberColors = [
    Colors.transparent, // 0
    Color(0xFF2196F3), // 1
    Color(0xFF4CAF50), // 2
    Color(0xFFE53935), // 3
    Color(0xFF9C27B0), // 4
    Color(0xFFFF5722), // 5
    Color(0xFF00BCD4), // 6
    Color(0xFF000000), // 7
    Color(0xFF607D8B), // 8
  ];

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF6C63FF), width: 0.5),
          ),
        ),
      );
    }
    if (value == -1) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A1515),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Center(child: Text('💣', style: TextStyle(fontSize: 14))),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: value > 0
            ? Text(
                '$value',
                style: TextStyle(
                  color: _numberColors[value.clamp(0, 8)],
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}
