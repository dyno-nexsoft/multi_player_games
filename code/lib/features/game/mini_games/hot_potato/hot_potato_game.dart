import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/gen/assets.gen.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Bảo Mìn Hẹn Giờ — quả bom đếm ngược, vuốt để ném sang đối thủ.
/// Ai cầm bom khi hết giờ → thua.
/// 30% xác suất bom bị "khóa" — phải tap 3 nút màu đúng thứ tự mới ném được.
class HotPotatoGame extends BaseMiniGame {
  static const double _roundDuration = 15.0;
  static const double _minDuration = 8.0;
  static const double _maxDuration = 20.0;
  static const double _lockChance = 0.35;

  HotPotatoGame(super.gameProvider);

  @override
  String get gameId => GameIds.hotPotato;

  // ── State ──────────────────────────────────────────────────────────────────

  String _holderId = ''; // player id currently holding the bomb
  double _timeLeft = _roundDuration;
  double _roundStartDuration = _roundDuration;
  double get timeLeft => _timeLeft;
  double get roundStartDuration => _roundStartDuration;

  bool _gameOver = false;
  bool _exploding = false;

  // Lock mechanic
  bool _locked = false;
  bool get locked => _locked;
  List<int> _lockSequence = []; // sequence of color indices to tap
  List<int> get lockSequence => List.unmodifiable(_lockSequence);
  int _lockProgress = 0;
  int get lockProgress => _lockProgress;
  bool _penaltyActive = false; // brief delay after wrong tap
  double _penaltyTimer = 0;

  // Throw swipe state
  bool _throwing = false;

  String _statusText = '';
  String get statusText => _statusText;

  final Map<String, int> _scores = {};

  void _notify() => notifyOverlay();

  bool get iHoldBomb =>
      _holderId == (gameProvider.lobbyProvider.localPlayer?.id ?? '');

  String get holderName => playerNameFor(_holderId);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
    if (gameProvider.lobbyProvider.isHost) {
      _startRound();
    } else {
      _statusText = 'Chờ bắt đầu...';
    }
  }

  void _startRound() {
    final rng = Random();
    _timeLeft = _minDuration + rng.nextDouble() * (_maxDuration - _minDuration);
    _roundStartDuration = _timeLeft;

    // Host always starts with the bomb
    final players = gameProvider.lobbyProvider.players;
    _holderId = players
        .firstWhere((p) => p.isHost, orElse: () => players.first)
        .id;

    final hasLock = rng.nextDouble() < _lockChance;
    _lockSequence = hasLock ? List.generate(3, (_) => rng.nextInt(4)) : [];
    _locked = hasLock;
    _lockProgress = 0;

    gameProvider.sendGameData(gameId, {
      'action': 'round_start',
      'holder_id': _holderId,
      'time_left': _timeLeft,
      'lock_sequence': _lockSequence,
    });

    _statusText = iHoldBomb
        ? (_locked ? '🔒 Mở khóa rồi ném!' : '💣 Ném ngay!')
        : '$holderName đang cầm bom!';
    _updateTickingSound();
    _notify();
  }

  /// Phát/tắt tiếng tick dựa trên việc thiết bị này có đang giữ bom không.
  /// Chỉ loa của người đang giữ bom mới phát tiếng — Spatial Synced Audio.
  void _updateTickingSound() {
    if (iHoldBomb && !_gameOver) {
      AppAudio.startLoop(Assets.audio.countdownBeep);
    } else {
      AppAudio.stopLoop();
    }
  }

  // ── Timer (host) ───────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !gameProvider.lobbyProvider.isHost) return;

    if (_penaltyActive) {
      _penaltyTimer -= dt;
      if (_penaltyTimer <= 0) _penaltyActive = false;
      _notify();
      return;
    }

    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _explode();
      return;
    }
    _notify();
  }

  void _explode() {
    if (_gameOver) return;
    _gameOver = true;
    _exploding = true;

    AppAudio.playLose();
    HapticFeedback.heavyImpact();

    // Loser is the current holder
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = p.id == _holderId ? 0 : 100;
    }

    gameProvider.sendGameData(gameId, {
      'action': 'explode',
      'loser_id': _holderId,
      'scores': Map<String, dynamic>.from(_scores),
    });

    _statusText = _holderId == gameProvider.lobbyProvider.localPlayer?.id
        ? '💥 BOM NỔ! Bạn thua!'
        : '🎉 Đối thủ bị nổ! Bạn thắng!';
    _notify();

    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(Map.from(_scores));
    });
  }

  // ── Lock mechanic ──────────────────────────────────────────────────────────

  void tapLockColor(int colorIndex) {
    if (!_locked || _penaltyActive || !iHoldBomb) return;
    if (_lockProgress >= _lockSequence.length) return;

    if (_lockSequence[_lockProgress] == colorIndex) {
      _lockProgress++;
      HapticFeedback.lightImpact();
      if (_lockProgress >= _lockSequence.length) {
        _locked = false;
        AppAudio.playGoal();
        _statusText = '💣 Ném ngay!';
      }
    } else {
      // Wrong — 1.5s penalty
      _penaltyActive = true;
      _penaltyTimer = 1.5;
      _lockProgress = 0;
      HapticFeedback.heavyImpact();
      AppAudio.playLose();
      _statusText = '❌ Sai! Thử lại...';
    }
    _notify();
  }

  // ── Throw ─────────────────────────────────────────────────────────────────

  void onSwipe(DismissDirection direction) {
    if (!iHoldBomb || _locked || _gameOver || _throwing) return;
    _throwing = true;

    HapticFeedback.mediumImpact();
    AppAudio.playPuckHit();

    if (gameProvider.lobbyProvider.isHost) {
      // Host picks a random recipient from all non-holders
      _transferBomb(_pickNextHolder());
    } else {
      // Client requests throw — host decides target
      gameProvider.sendGameData(gameId, {'action': 'throw_request'});
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _throwing = false;
    });
  }

  String _pickNextHolder() {
    final players = gameProvider.lobbyProvider.players
        .where((p) => p.id != _holderId)
        .toList();
    if (players.isEmpty) return _holderId;
    return players[Random().nextInt(players.length)].id;
  }

  void _transferBomb(String newHolderId) {
    _holderId = newHolderId;
    final rng = Random();
    final hasLock = rng.nextDouble() < _lockChance;
    _lockSequence = hasLock ? List.generate(3, (_) => rng.nextInt(4)) : [];
    _locked = hasLock;
    _lockProgress = 0;

    gameProvider.sendGameData(gameId, {
      'action': 'bomb_transfer',
      'holder_id': newHolderId,
      'lock_sequence': _lockSequence,
    });

    _statusText = iHoldBomb
        ? (_locked ? '🔒 Mở khóa rồi ném!' : '💣 Ném ngay!')
        : '$holderName đang cầm bom!';
    _updateTickingSound();
    _notify();
  }

  // ── Network ───────────────────────────────────────────────────────────────

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'round_start':
        _holderId = payload['holder_id'] as String;
        _timeLeft = (payload['time_left'] as num).toDouble();
        _roundStartDuration = _timeLeft;
        final seq = (payload['lock_sequence'] as List?)?.cast<int>() ?? <int>[];
        _lockSequence = seq;
        _locked = seq.isNotEmpty;
        _lockProgress = 0;
        _statusText = iHoldBomb
            ? (_locked ? '🔒 Mở khóa rồi ném!' : '💣 Ném ngay!')
            : '$holderName đang cầm bom!';
        _notify();

      case 'throw_request':
        if (gameProvider.lobbyProvider.isHost) {
          _transferBomb(_pickNextHolder());
        }

      case 'bomb_transfer':
        _holderId = payload['holder_id'] as String;
        final seq = (payload['lock_sequence'] as List?)?.cast<int>() ?? <int>[];
        _lockSequence = seq;
        _locked = seq.isNotEmpty;
        _lockProgress = 0;
        _statusText = iHoldBomb
            ? (_locked ? '🔒 Mở khóa rồi ném!' : '💣 Ném ngay!')
            : '$holderName đang cầm bom!';
        HapticFeedback.heavyImpact();
        AppAudio.playPuckHit();
        _updateTickingSound();
        _notify();

      case 'explode':
        if (!_gameOver) {
          _gameOver = true;
          _exploding = true;
          final loserId = payload['loser_id'] as String;
          final raw = payload['scores'] as Map;
          raw.forEach((k, v) => _scores[k.toString()] = (v as num).toInt());
          final iLose = loserId == gameProvider.lobbyProvider.localPlayer?.id;
          _statusText = iLose ? '💥 BOM NỔ! Bạn thua!' : '🎉 Đối thủ bị nổ!';
          AppAudio.stopLoop(); // dừng tick khi bom nổ
          HapticFeedback.heavyImpact();
          iLose ? AppAudio.playLose() : AppAudio.playWin();
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!cancelled) endMiniGame(Map.from(_scores));
          });
        }
    }
  }

  @override
  void onDetach() {
    AppAudio.stopLoop();
    super.onDetach();
  }

  Widget buildOverlay(BuildContext context) => _HotPotatoOverlay(game: this);
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _HotPotatoOverlay extends StatefulWidget {
  final HotPotatoGame game;
  const _HotPotatoOverlay({required this.game});

  @override
  State<_HotPotatoOverlay> createState() => _HotPotatoOverlayState();
}

class _HotPotatoOverlayState extends State<_HotPotatoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
      if (widget.game.iHoldBomb && widget.game.timeLeft < 5) {
        _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final timeRatio = (g.timeLeft / g.roundStartDuration).clamp(0.0, 1.0);
    final urgentColor = Color.lerp(Colors.green, Colors.red, 1 - timeRatio)!;
    final bgColor = g._exploding
        ? Colors.red.shade900
        : g.iHoldBomb
        ? const Color(0xFF2A1A0A)
        : AppTheme.bgDeep;

    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity!.abs() > 400) {
          g.onSwipe(
            d.primaryVelocity! < 0
                ? DismissDirection.up
                : DismissDirection.down,
          );
        }
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity!.abs() > 400) {
          g.onSwipe(
            d.primaryVelocity! < 0
                ? DismissDirection.startToEnd
                : DismissDirection.endToStart,
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  g.statusText,
                  style: TextStyle(
                    color: g.iHoldBomb ? Colors.orange : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Bomb + timer ring
              _BombWidget(
                timeRatio: timeRatio,
                urgentColor: urgentColor,
                iHoldBomb: g.iHoldBomb,
                exploding: g._exploding,
                timeLeft: g.timeLeft,
                shake: g.iHoldBomb && g.timeLeft < 5,
              ),

              const SizedBox(height: 32),

              // Lock mechanic
              if (g.iHoldBomb && g._locked && !g._exploding)
                _LockPanel(game: g),

              // Swipe hint
              if (g.iHoldBomb && !g._locked && !g._exploding) ...[
                const SizedBox(height: 16),
                const Text(
                  '← vuốt để ném →',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bomb widget ────────────────────────────────────────────────────────────

class _BombWidget extends StatelessWidget {
  final double timeRatio;
  final Color urgentColor;
  final bool iHoldBomb;
  final bool exploding;
  final double timeLeft;
  final bool shake;

  const _BombWidget({
    required this.timeRatio,
    required this.urgentColor,
    required this.iHoldBomb,
    required this.exploding,
    required this.timeLeft,
    required this.shake,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Countdown ring
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: timeRatio,
              strokeWidth: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(urgentColor),
            ),
          ),
          // Bomb emoji (shake when urgent)
          AnimatedScale(
            scale: shake ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 60),
            child: Text(
              exploding ? '💥' : '💣',
              style: TextStyle(fontSize: iHoldBomb ? 72 : 56),
            ),
          ),
          // Timer text
          Positioned(
            bottom: 20,
            child: Text(
              timeLeft.ceil().toString(),
              style: TextStyle(
                color: urgentColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Lock panel ─────────────────────────────────────────────────────────────

class _LockPanel extends StatelessWidget {
  final HotPotatoGame game;
  const _LockPanel({required this.game});

  static const _lockColors = [
    Color(0xFFE53935), // red
    Color(0xFF43A047), // green
    Color(0xFF1E88E5), // blue
    Color(0xFFFFB300), // amber
  ];

  static const _lockLabels = ['🔴', '🟢', '🔵', '🟡'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(game.lockSequence.length, (i) {
            final done = i < game.lockProgress;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? _lockColors[game.lockSequence[i]]
                    : Colors.white24,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          '🔒 Tap đúng thứ tự để mở khóa',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        // Color buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return GestureDetector(
              onTap: () => game.tapLockColor(i),
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _lockColors[i],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _lockColors[i].withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _lockLabels[i],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
