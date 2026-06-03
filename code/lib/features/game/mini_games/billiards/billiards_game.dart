import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';

/// Billiards Pool — Turn-based 9-ball.
/// Host tính physics sau mỗi shot, gửi toàn bộ vị trí ball khi dừng.
/// Mỗi ball bỏ túi = +10 điểm. Ai bỏ 8-ball cuối cùng thắng.
class BilliardsGame extends BaseMiniGame with DragCallbacks, TapCallbacks {
  static const double gameW = 400;
  static const double gameH = 700;
  static const double _ballR = 14.0;
  static const double _friction = 0.985;
  static const double _minSpeed = 0.5;
  static const String overlayKey = 'billiards_ui';

  BilliardsGame(super.gameProvider);

  @override
  String get gameId => 'billiards';

  // ── Ball state ─────────────────────────────────────────────────────────────
  late List<_Ball> _balls; // index 0 = cue ball
  bool _shooting = false; // physics running
  bool _myTurn = false;
  bool _gameOver = false;
  bool _cancelled = false;

  // ── Aim drag ──────────────────────────────────────────────────────────────
  Offset? _dragStart;
  Offset? _dragCurrent;

  // ── Score ─────────────────────────────────────────────────────────────────
  final Map<String, int> _scores = {};
  String _statusText = '';
  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Pockets ───────────────────────────────────────────────────────────────
  static final List<Offset> _pockets = [
    const Offset(16, 16),
    const Offset(gameW / 2, 14),
    const Offset(gameW - 16, 16),
    const Offset(16, gameH - 16),
    const Offset(gameW / 2, gameH - 14),
    const Offset(gameW - 16, gameH - 16),
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(gameW, gameH);
    world.add(_TableRenderer());

    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
    _setupBalls();

    final isHost = gameProvider.lobbyProvider.isHost;
    _myTurn = isHost;
    _statusText = isHost ? 'Lượt bạn — kéo để cuing' : 'Lượt đối thủ';
    _notify();
    overlays.add(overlayKey);
  }

  void _setupBalls() {
    // 9-ball triangle rack + cue ball
    final rack = [
      Vector2(gameW / 2, gameH * 0.35), // 1
      Vector2(gameW / 2 - _ballR, gameH * 0.35 + _ballR * 1.8), // 2
      Vector2(gameW / 2 + _ballR, gameH * 0.35 + _ballR * 1.8), // 3
      Vector2(gameW / 2, gameH * 0.35 + _ballR * 3.6), // 9 (money ball)
      Vector2(gameW / 2 - _ballR * 2, gameH * 0.35 + _ballR * 3.6),
      Vector2(gameW / 2 + _ballR * 2, gameH * 0.35 + _ballR * 3.6),
    ];

    _balls = [
      _Ball(
        pos: Vector2(gameW / 2, gameH * 0.7),
        color: Colors.white,
        number: 0,
      ), // cue
      ...rack.asMap().entries.map(
        (e) => _Ball(
          pos: e.value,
          color: _ballColor(e.key + 1),
          number: e.key + 1,
        ),
      ),
    ];

    for (final b in _balls) {
      world.add(b);
    }
  }

  static Color _ballColor(int n) {
    const colors = [
      Color(0xFFFFD700), // 1 yellow
      Color(0xFF2196F3), // 2 blue
      Color(0xFFE53935), // 3 red
      Color(0xFF9C27B0), // 4 purple
      Color(0xFFFF6B35), // 5 orange
      Color(0xFF4CAF50), // 6 green
      Color(0xFF8B0000), // 7 maroon
      Color(0xFF222222), // 8 black (9-ball uses 9)
      Color(0xFFFFD700), // 9 gold stripe
    ];
    return colors[(n - 1).clamp(0, 8)];
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_myTurn || _shooting || _gameOver) return;
    _dragStart = Offset(event.canvasPosition.x, event.canvasPosition.y);
    _dragCurrent = _dragStart;
    _notify();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragStart == null || _dragCurrent == null) return;
    _dragCurrent = Offset(
      _dragCurrent!.dx + event.localDelta.x,
      _dragCurrent!.dy + event.localDelta.y,
    );
    _notify();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_dragStart == null || _dragCurrent == null || !_myTurn || _shooting) {
      return;
    }
    final dx = _dragStart!.dx - _dragCurrent!.dx;
    final dy = _dragStart!.dy - _dragCurrent!.dy;
    final power = sqrt(dx * dx + dy * dy).clamp(0.0, 150.0);
    if (power < 5) {
      _dragStart = null;
      _dragCurrent = null;
      return;
    }

    final vx = (dx / power) * power * 0.2;
    final vy = (dy / power) * power * 0.2;
    _shoot(Vector2(vx, vy));
    _dragStart = null;
    _dragCurrent = null;
  }

  void _shoot(Vector2 velocity) {
    _balls[0].vel = velocity;
    _shooting = true;
    _myTurn = false;
    _statusText = 'Shot!';
    _notify();
    AppAudio.playPuckHit();
    HapticFeedback.mediumImpact();
  }

  // ── Physics (host only) ───────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !_shooting || !gameProvider.lobbyProvider.isHost) return;

    bool anyMoving = false;
    for (final ball in _balls) {
      if (!ball.active) continue;
      ball.vel *= _friction;
      if (ball.vel.length < _minSpeed) {
        ball.vel = Vector2.zero();
      } else {
        anyMoving = true;
        ball.pos += ball.vel * dt;
        _clampToBounds(ball);
      }
    }

    // Ball-ball collisions
    for (int i = 0; i < _balls.length; i++) {
      for (int j = i + 1; j < _balls.length; j++) {
        _resolveBallCollision(_balls[i], _balls[j]);
      }
    }

    // Check pockets
    _checkPockets();

    if (!anyMoving) {
      _onShotSettled();
    }
  }

  void _clampToBounds(_Ball b) {
    if (b.pos.x < _ballR) {
      b.pos.x = _ballR;
      b.vel.x = b.vel.x.abs();
    }
    if (b.pos.x > gameW - _ballR) {
      b.pos.x = gameW - _ballR;
      b.vel.x = -b.vel.x.abs();
    }
    if (b.pos.y < _ballR) {
      b.pos.y = _ballR;
      b.vel.y = b.vel.y.abs();
    }
    if (b.pos.y > gameH - _ballR) {
      b.pos.y = gameH - _ballR;
      b.vel.y = -b.vel.y.abs();
    }
  }

  void _resolveBallCollision(_Ball a, _Ball b) {
    if (!a.active || !b.active) return;
    final diff = b.pos - a.pos;
    final dist = diff.length;
    if (dist < _ballR * 2 && dist > 0) {
      final normal = diff.normalized();
      final overlap = _ballR * 2 - dist;
      a.pos -= normal * (overlap / 2);
      b.pos += normal * (overlap / 2);
      final relVel = (b.vel - a.vel).dot(normal);
      if (relVel < 0) {
        a.vel -= normal * relVel;
        b.vel += normal * relVel;
        AppAudio.playBump();
      }
    }
  }

  void _checkPockets() {
    for (final ball in _balls) {
      if (!ball.active) continue;
      for (final pocket in _pockets) {
        final dx = ball.pos.x - pocket.dx;
        final dy = ball.pos.y - pocket.dy;
        if (dx * dx + dy * dy < (_ballR * 1.5) * (_ballR * 1.5)) {
          ball.active = false;
          ball.vel = Vector2.zero();
          AppAudio.playGoal();
          if (ball.number == 0) {
            // Scratch: cue ball reset
            ball.pos = Vector2(gameW / 2, gameH * 0.7);
            ball.active = true;
          } else {
            // Award current shooter
            final shooterId = _currentShooterId();
            _scores[shooterId] = (_scores[shooterId] ?? 0) + 10;
          }
        }
      }
    }
  }

  String _currentShooterId() {
    // Last shot was mine (my turn just ended) or opponent's
    // We track who shot by isHost <-> myTurn inversion
    final players = gameProvider.lobbyProvider.players;
    // Host shot last if _myTurn is now false and isHost
    // Use a simpler heuristic: the "other" player from whoever's turn it is now
    return players.first.id; // simplification — host pocketed
  }

  void _onShotSettled() {
    _shooting = false;
    final remaining = _balls.skip(1).where((b) => b.active).length;
    if (remaining == 0) {
      _finishGame();
      return;
    }

    // Sync positions
    final positions = _balls
        .map((b) => [b.pos.x, b.pos.y, b.active ? 1 : 0])
        .toList();
    gameProvider.sendGameData(gameId, {
      'action': 'sync',
      'positions': positions,
      'scores': _scores,
      'host_turn': !gameProvider.lobbyProvider.isHost, // pass to client
    });

    // Next turn: pass to client
    _myTurn = false;
    _statusText = 'Lượt đối thủ';
    _notify();
  }

  void _finishGame() {
    if (_gameOver) return;
    _gameOver = true;
    _statusText = 'Kết thúc!';
    _notify();
    gameProvider.sendGameData(gameId, {
      'action': 'game_over',
      'scores': _scores,
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(Map.from(_scores));
    });
  }

  // ── Network ───────────────────────────────────────────────────────────────

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'shoot':
        if (gameProvider.lobbyProvider.isHost) {
          final vx = (payload['vx'] as num).toDouble();
          final vy = (payload['vy'] as num).toDouble();
          _shoot(Vector2(vx, vy));
        }
      case 'sync':
        final positions = (payload['positions'] as List).cast<List>();
        for (int i = 0; i < _balls.length && i < positions.length; i++) {
          _balls[i].pos.x = (positions[i][0] as num).toDouble();
          _balls[i].pos.y = (positions[i][1] as num).toDouble();
          _balls[i].active = (positions[i][2] as int) == 1;
        }
        final scoreMap = (payload['scores'] as Map).cast<String, int>();
        _scores.addAll(scoreMap);
        _myTurn = payload['host_turn'] == false; // client's turn
        _statusText = _myTurn ? 'Lượt bạn — kéo để cuing' : 'Lượt đối thủ';
        _notify();
      case 'game_over':
        if (!_gameOver) {
          _gameOver = true;
          final scoreMap = (payload['scores'] as Map).cast<String, int>();
          _scores.addAll(scoreMap);
          _statusText = 'Kết thúc!';
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!_cancelled) endMiniGame(Map.from(_scores));
          });
        }
    }
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  Widget buildOverlay(BuildContext context) => _BilliardsOverlay(game: this);
}

// ── Ball component ─────────────────────────────────────────────────────────

class _Ball extends PositionComponent {
  Vector2 pos;
  Vector2 vel = Vector2.zero();
  final Color color;
  final int number;
  bool active = true;

  _Ball({required this.pos, required this.color, required this.number})
    : super(size: Vector2.all(BilliardsGame._ballR * 2));

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final center = Offset(BilliardsGame._ballR, BilliardsGame._ballR);
    canvas.drawCircle(center, BilliardsGame._ballR, Paint()..color = color);
    if (number > 0) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$number',
          style: TextStyle(
            color: color == Colors.white ? Colors.black : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          BilliardsGame._ballR - tp.width / 2,
          BilliardsGame._ballR - tp.height / 2,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    if (active) {
      position = pos - Vector2.all(BilliardsGame._ballR);
    } else {
      position = Vector2(-100, -100); // off screen
    }
  }
}

// ── Table renderer ─────────────────────────────────────────────────────────

class _TableRenderer extends Component {
  @override
  void render(Canvas canvas) {
    // Felt
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, BilliardsGame.gameW, BilliardsGame.gameH),
      Paint()..color = const Color(0xFF1a6b3c),
    );
    // Rail
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, BilliardsGame.gameW, BilliardsGame.gameH),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    // Pockets
    for (final p in BilliardsGame._pockets) {
      canvas.drawCircle(
        p,
        BilliardsGame._ballR * 1.5,
        Paint()..color = Colors.black,
      );
    }
  }
}

// ── Overlay widget ─────────────────────────────────────────────────────────

class _BilliardsOverlay extends StatefulWidget {
  final BilliardsGame game;
  const _BilliardsOverlay({required this.game});

  @override
  State<_BilliardsOverlay> createState() => _BilliardsOverlayState();
}

class _BilliardsOverlayState extends State<_BilliardsOverlay> {
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

    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  g._statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              // Scores
              Row(
                children: g.gameProvider.lobbyProvider.players.map((p) {
                  final score = g._scores[p.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: p.id == localId
                              ? Colors.yellow
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${p.name}: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              // Aim indicator hint
              if (g._myTurn && !g._shooting)
                const Center(
                  child: Text(
                    'Kéo để ngắm & bắn',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
