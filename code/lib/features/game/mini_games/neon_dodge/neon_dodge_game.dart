import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flutter/material.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/network/game_packet.dart';

import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Neon Dodge — game Console Mode: Host là màn hình, mỗi Client là một tay cầm.
///
/// Mỗi client điều khiển một entity bằng joystick (trục X) trên màn hình Host.
/// Obstacles rơi xuống từ trên; va chạm → rung tay cầm đó, -1 mạng.
/// Thắng = sống lâu nhất hoặc còn mạng khi hết giờ 60s.
class NeonDodgeGame extends BaseMiniGame {
  static const double gameW = 400;
  static const double gameH = 720;
  static const double _gameDuration = 60.0;
  static const int _startLives = 3;
  static const double _entityRadius = 22;
  static const double _obstacleW = 54;
  static const double _obstacleH = 18;
  static const double _entitySpeed = 260; // px/s horizontal

  NeonDodgeGame(super.gameProvider);

  @override
  String get gameId => GameIds.neonDodge;

  // ── State ──────────────────────────────────────────────────────────────────
  final Map<String, _PlayerEntity> _entities = {};
  final Map<String, double> _joystickX = {}; // playerId → -1..1
  final Map<String, int> _livesMap = {};
  double _timeLeft = _gameDuration;
  double _spawnTimer = 0;
  double _spawnInterval = 2.2;
  bool _gameOver = false;
  bool _cancelled = false;

  late TextComponent _timerText;
  final _rng = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameW, gameH),
    );

    world.add(_NeonArena());

    // Một entity cho mỗi client (non-host)
    final players = gameProvider.lobbyProvider.players;
    final clients = players.where((p) => !p.isHost).toList();
    final count = clients.length;

    for (var i = 0; i < count; i++) {
      final p = clients[i];
      final x = (gameW / (count + 1)) * (i + 1);
      final entity = _PlayerEntity(
        playerId: p.id,
        color: Color(p.color),
        startPos: Vector2(x, gameH * 0.82),
        radius: _entityRadius,
        name: p.name,
      );
      _entities[p.id] = entity;
      _livesMap[p.id] = _startLives;
      _joystickX[p.id] = 0;
      world.add(entity);
    }

    // Nói với mỗi tay cầm: chỉ dùng joystick (không dùng nút), không gyro.
    if (gameProvider.lobbyProvider.isHost) {
      gameProvider.sendControllerInit(gameId, {
        'joystick_enabled': true,
        'gyro_hint': false,
        'labels': {'A': '', 'B': '', 'X': '', 'Y': ''},
        'highlight': '',
      });
    }

    _timerText = TextComponent(
      text: '60',
      position: Vector2(gameW / 2, 16),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    world.add(_timerText);
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !gameProvider.lobbyProvider.isHost) return;

    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _finish();
      return;
    }
    _timerText.text = _timeLeft.ceil().toString();

    // Move entities
    for (final entry in _entities.entries) {
      final entity = entry.value;
      final jx = _joystickX[entry.key] ?? 0;
      entity.position.x = (entity.position.x + jx * _entitySpeed * dt).clamp(
        _entityRadius,
        gameW - _entityRadius,
      );
    }

    // Spawn obstacles
    _spawnTimer += dt;
    _spawnInterval = (2.2 - (_gameDuration - _timeLeft) / _gameDuration * 1.4)
        .clamp(0.6, 2.2);
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnObstacle();
    }

    // Collision detection
    _checkCollisions();
  }

  void _spawnObstacle() {
    final x = _obstacleW / 2 + _rng.nextDouble() * (gameW - _obstacleW);
    final speed = 140 + _rng.nextDouble() * 120;
    world.add(
      _Obstacle(position: Vector2(x, -_obstacleH), speed: speed, game: this),
    );
  }

  void _checkCollisions() {
    final obstacles = world.children.whereType<_Obstacle>().toList();
    for (final obs in obstacles) {
      for (final entry in _entities.entries) {
        final entity = entry.value;
        if (_circleRectCollision(
          entity.position,
          _entityRadius,
          obs.position,
          _obstacleW,
          _obstacleH,
        )) {
          obs.removeFromParent();
          _hitPlayer(entry.key);
        }
      }
    }
  }

  bool _circleRectCollision(
    Vector2 circle,
    double r,
    Vector2 rectCenter,
    double rw,
    double rh,
  ) {
    final nearX = circle.x.clamp(rectCenter.x - rw / 2, rectCenter.x + rw / 2);
    final nearY = circle.y.clamp(rectCenter.y - rh / 2, rectCenter.y + rh / 2);
    final dx = circle.x - nearX;
    final dy = circle.y - nearY;
    return dx * dx + dy * dy < r * r;
  }

  void _hitPlayer(String playerId) {
    AppAudio.playBump();
    _livesMap[playerId] = (_livesMap[playerId] ?? 0) - 1;
    _entities[playerId]?.flash();

    // Feedback rung + chớp đỏ tới tay cầm của player đó
    gameProvider.sendControllerFeedback(
      playerId,
      hapticType: 'heavy',
      flashColor: Colors.red.toARGB32(),
    );

    // Broadcast cập nhật lives tới clients
    gameProvider.sendGameData(gameId, {
      'action': 'lives_update',
      'player_id': playerId,
      'lives': _livesMap[playerId],
    });

    if ((_livesMap[playerId] ?? 0) <= 0) {
      _entities[playerId]?.removeFromParent();
      _entities.remove(playerId);

      gameProvider.sendGameData(gameId, {
        'action': 'player_out',
        'player_id': playerId,
      });

      if (_entities.isEmpty) _finish();
    }
  }

  void _finish() {
    if (_gameOver) return;
    _gameOver = true;

    final players = gameProvider.lobbyProvider.players;
    final scores = <String, int>{};
    for (final p in players) {
      if (p.isHost) continue;
      final lives = _livesMap[p.id] ?? 0;
      scores[p.id] = lives * 33;
    }
    // Host không có điểm trong console mode
    for (final p in players) {
      if (p.isHost) scores[p.id] = 0;
    }

    gameProvider.sendGameData(gameId, {
      'action': 'game_over',
      'scores': scores,
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(scores);
    });
  }

  // ── Network ────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    // Host nhận input từ các tay cầm
    if (payload['type'] == PacketType.controllerInput ||
        (payload.containsKey('j') && payload.containsKey('b'))) {
      final j = payload['j'] as List?;
      if (j != null) {
        _joystickX[senderId] = (j[0] as num).toDouble();
      }
      return;
    }

    // Client nhận cập nhật từ host
    switch (payload['action'] as String?) {
      case 'lives_update':
        final pid = payload['player_id'] as String?;
        final lives = payload['lives'] as int?;
        if (pid != null && lives != null) _livesMap[pid] = lives;
      case 'player_out':
        final pid = payload['player_id'] as String?;
        if (pid != null) {
          _entities[pid]?.removeFromParent();
          _entities.remove(pid);
        }
      case 'game_over':
        if (!_gameOver) {
          _gameOver = true;
          final raw = payload['scores'] as Map?;
          if (raw != null) {
            final scores = raw.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (!_cancelled) endMiniGame(scores);
            });
          }
        }
    }
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }
}

// ── Player Entity ─────────────────────────────────────────────────────────────

class _PlayerEntity extends PositionComponent with HasGameReference {
  final String playerId;
  final Color color;
  final double radius;
  final String name;
  double _flashTimer = 0;

  _PlayerEntity({
    required this.playerId,
    required this.color,
    required Vector2 startPos,
    required this.radius,
    required this.name,
  }) : super(
         position: startPos,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  void flash() => _flashTimer = 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) _flashTimer -= dt;
  }

  @override
  void render(Canvas canvas) {
    final isFlashing = _flashTimer > 0;
    final paint = Paint()..color = isFlashing ? Colors.white : color;

    // Glow
    canvas.drawCircle(
      Offset(radius, radius),
      radius + 4,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Name label
    final tp = TextPainter(
      text: TextSpan(
        text: name.length > 6 ? '${name.substring(0, 5)}…' : name,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(radius - tp.width / 2, radius * 2 + 3));
  }
}

// ── Obstacle ──────────────────────────────────────────────────────────────────

class _Obstacle extends PositionComponent with HasGameReference<NeonDodgeGame> {
  final double speed;
  static const _colors = [
    Color(0xFFFF6584),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
  ];
  late Color _color;

  _Obstacle({
    required Vector2 position,
    required this.speed,
    required NeonDodgeGame game,
  }) : super(
         position: position,
         size: Vector2(NeonDodgeGame._obstacleW, NeonDodgeGame._obstacleH),
         anchor: Anchor.center,
       ) {
    _color = _colors[Random().nextInt(_colors.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > NeonDodgeGame.gameH + 20) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, NeonDodgeGame._obstacleW, NeonDodgeGame._obstacleH),
        const Radius.circular(6),
      ),
      Paint()..color = _color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, NeonDodgeGame._obstacleW, NeonDodgeGame._obstacleH),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

// ── Arena ─────────────────────────────────────────────────────────────────────

class _NeonArena extends Component {
  @override
  void render(Canvas canvas) {
    const w = NeonDodgeGame.gameW;
    const h = NeonDodgeGame.gameH;

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF080810),
    );

    // Danger zone at bottom (player area)
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()..color = const Color(0xFF0A0A1E),
    );
    canvas.drawLine(
      Offset(0, h * 0.72),
      Offset(w, h * 0.72),
      Paint()
        ..color = const Color(0x336C63FF)
        ..strokeWidth = 1,
    );
  }
}
