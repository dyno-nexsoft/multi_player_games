import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Phản Xạ Thần Tốc — Host ra hiệu ngẫu nhiên, cả 2 tap ngay.
/// Host đo thời gian từ lúc gửi 'flash' đến khi nhận 'tap'.
/// Ai tap nhanh hơn thắng vòng đó. 5 vòng → tổng điểm.
class ReactionTapGame extends BaseMiniGame {
  static const int _totalRounds = 5;
  static const double _minDelay = 2.0;
  static const double _maxDelay = 5.0;

  ReactionTapGame(super.gameProvider);

  @override
  String get gameId => GameIds.reactionTap;

  // ── State ──────────────────────────────────────────────────────────────────

  int _currentRound = 0;
  bool _waitingForTap = false;
  bool _gameOver = false;
  double _flashSentTime = 0; // milliseconds when flash was sent
  double _waitTimer = 0;
  double _waitDuration = 0;

  final Map<String, int> _wins = {}; // playerId → wins
  final Map<String, double> _lastReactionTime = {}; // playerId → ms

  // Results for display
  String _statusText = '';
  String _resultText = '';
  Color _bgColor = const Color(0xFF1A1A2E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (gameProvider.lobbyProvider.isHost) {
      _scheduleNextRound();
    } else {
      _statusText = 'Chờ hiệu lệnh...';
    }
  }

  // ── Host logic ─────────────────────────────────────────────────────────────

  void _scheduleNextRound() {
    _waitingForTap = false;
    _bgColor = const Color(0xFF1A1A2E);
    _waitDuration = _minDelay + Random().nextDouble() * (_maxDelay - _minDelay);
    _waitTimer = 0;
    _statusText = 'Sẵn sàng...';
    _lastReactionTime.clear();
    _notify();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !gameProvider.lobbyProvider.isHost) return;
    if (_waitingForTap) return;

    _waitTimer += dt;
    if (_waitTimer >= _waitDuration) {
      _sendFlash();
    }
  }

  void _sendFlash() {
    _currentRound++;
    _waitingForTap = true;
    _flashSentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    _bgColor = Colors.yellow;
    _statusText = 'TAP!';
    _notify();
    AppAudio.playCountdownGo();
    HapticFeedback.heavyImpact();
    gameProvider.sendGameData(gameId, {
      'action': 'flash',
      'round': _currentRound,
      'flash_time': _flashSentTime,
    });
  }

  void _onLocalTap() {
    if (!_waitingForTap || _gameOver) return;
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final reactionMs = now - _flashSentTime;

    final localId = gameProvider.lobbyProvider.localPlayer!.id;
    _recordTap(localId, reactionMs, isLocal: true);

    gameProvider.sendGameData(gameId, {
      'action': 'tap',
      'round': _currentRound,
      'reaction_ms': reactionMs,
    });
  }

  void _recordTap(String playerId, double reactionMs, {bool isLocal = false}) {
    _lastReactionTime[playerId] = reactionMs;

    // Cần cả 2 người tap mới so sánh
    final players = gameProvider.lobbyProvider.players;
    if (_lastReactionTime.length < players.length) return;

    // Tìm người nhanh nhất
    final fastest = _lastReactionTime.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );

    _wins[fastest.key] = (_wins[fastest.key] ?? 0) + 1;
    _waitingForTap = false;

    // Broadcast kết quả vòng
    gameProvider.sendGameData(gameId, {
      'action': 'round_result',
      'round': _currentRound,
      'winner_id': fastest.key,
      'times': _lastReactionTime.map((k, v) => MapEntry(k, v)),
    });

    _showRoundResult(fastest.key);

    if (_currentRound >= _totalRounds) {
      _finishGame();
    } else {
      Future.delayed(const Duration(seconds: 2), _scheduleNextRound);
    }
  }

  void _showRoundResult(String winnerId) {
    final localId = gameProvider.lobbyProvider.localPlayer?.id;
    final iWin = winnerId == localId;
    _bgColor = iWin ? const Color(0xFF1B5E20) : const Color(0xFF4A1515);
    final winnerName = gameProvider.lobbyProvider.players
        .firstWhere(
          (p) => p.id == winnerId,
          orElse: () => gameProvider.lobbyProvider.localPlayer!,
        )
        .name;
    _resultText = '$winnerName thắng vòng này!';
    _statusText = 'Vòng $_currentRound/$_totalRounds';
    _notify();
  }

  void _finishGame() {
    _gameOver = true;
    final players = gameProvider.lobbyProvider.players;
    final scores = <String, int>{};
    for (final p in players) {
      scores[p.id] = (_wins[p.id] ?? 0) * 20;
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(scores);
    });
  }

  bool _cancelled = false;
  void Function()? onStateChanged;

  void _notify() => onStateChanged?.call();

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  // ── Client/shared ─────────────────────────────────────────────────────────

  void _onFlashReceived(double flashTime) {
    _flashSentTime = flashTime;
    _waitingForTap = true;
    _bgColor = Colors.yellow;
    _statusText = 'TAP!';
    _notify();
    AppAudio.playCountdownGo();
    HapticFeedback.heavyImpact();
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    switch (action) {
      case 'flash':
        final ft = (payload['flash_time'] as num).toDouble();
        _onFlashReceived(ft);
      case 'tap':
        if (gameProvider.lobbyProvider.isHost) {
          final ms = (payload['reaction_ms'] as num).toDouble();
          _recordTap(senderId, ms);
        }
      case 'round_result':
        if (!gameProvider.lobbyProvider.isHost) {
          final winnerId = payload['winner_id'] as String;
          _wins[winnerId] = (_wins[winnerId] ?? 0) + 1;
          _waitingForTap = false;
          _showRoundResult(winnerId);
          _currentRound = (payload['round'] as int?) ?? _currentRound;
          _statusText = 'Vòng $_currentRound/$_totalRounds';
          if (_currentRound >= _totalRounds) {
            _gameOver = true;
          } else {
            Future.delayed(const Duration(seconds: 2), () {
              _bgColor = const Color(0xFF1A1A2E);
              _statusText = 'Chờ hiệu lệnh...';
              _resultText = '';
            });
          }
        }
    }
  }

  // ── Overlay builder ───────────────────────────────────────────────────────

  Widget buildOverlay(BuildContext context) {
    return _ReactionTapOverlay(game: this, onTap: _onLocalTap);
  }
}

/// Flutter overlay widget cho ReactionTapGame.
class _ReactionTapOverlay extends StatefulWidget {
  final ReactionTapGame game;
  final VoidCallback onTap;

  const _ReactionTapOverlay({required this.game, required this.onTap});

  @override
  State<_ReactionTapOverlay> createState() => _ReactionTapOverlayState();
}

class _ReactionTapOverlayState extends State<_ReactionTapOverlay> {
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
    final game = widget.game;
    final localId = game.gameProvider.lobbyProvider.localPlayer?.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: game._bgColor,
      child: GestureDetector(
        onTapDown: (_) => widget.onTap(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  game._statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (game._resultText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    game._resultText,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                // Wins per player
                ...game.gameProvider.lobbyProvider.players.map((p) {
                  final wins = game._wins[p.id] ?? 0;
                  final isMe = p.id == localId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(p.color),
                          child: Text(
                            p.name.isNotEmpty ? p.name[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.name}${isMe ? ' (bạn)' : ''}: $wins vòng',
                          style: TextStyle(
                            color: isMe ? Colors.yellow : Colors.white70,
                            fontSize: 16,
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 60),
                if (game._waitingForTap)
                  const Text(
                    'TAP NGAY!',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                else
                  const Text(
                    'Chờ...',
                    style: TextStyle(color: Colors.white30, fontSize: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
