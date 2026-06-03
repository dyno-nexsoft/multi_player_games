import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/base_mini_game.dart';

/// Húc Bóng Sinh Tồn — Host authoritative physics, Client gửi input joystick.
class SumoGame extends BaseMiniGame {
  static const double _arenaRadius = 160.0;
  static const double _ballRadius = 24.0;
  static const double _syncRate = 1 / 30;
  static const double _force = 180.0;
  static const Offset _arenaCenter = Offset(200, 400);

  Vector2 _p1Pos = Vector2(120, 400);
  Vector2 _p2Pos = Vector2(280, 400);
  Vector2 _p1Vel = Vector2.zero();
  Vector2 _p2Vel = Vector2.zero();

  double _syncTimer = 0;
  bool _gameOver = false;

  SumoGame(super.gameProvider);

  @override
  String get gameId => 'sumo_bumper';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 800);
    world.add(_SumoRenderer(game: this));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !gameProvider.lobbyProvider.isHost) return;

    _p1Vel.scale(0.92);
    _p2Vel.scale(0.92);
    _p1Pos += _p1Vel * dt;
    _p2Pos += _p2Vel * dt;
    _resolveCollision();

    _syncTimer += dt;
    if (_syncTimer >= _syncRate) {
      _syncTimer = 0;
      gameProvider.sendGameData(gameId, {
        'action': 'sync',
        'p1': [_p1Pos.x, _p1Pos.y],
        'p2': [_p2Pos.x, _p2Pos.y],
      });
    }

    _checkElimination();
  }

  void _resolveCollision() {
    final diff = _p2Pos - _p1Pos;
    final dist = diff.length;
    if (dist < _ballRadius * 2 && dist > 0) {
      final normal = diff.normalized();
      final overlap = _ballRadius * 2 - dist;
      _p1Pos -= normal * (overlap / 2);
      _p2Pos += normal * (overlap / 2);
      final relVel = (_p2Vel - _p1Vel).dot(normal);
      if (relVel < 0) {
        _p1Vel -= normal * relVel;
        _p2Vel += normal * relVel;
      }
    }
  }

  void _checkElimination() {
    final p1Center = Offset(_p1Pos.x, _p1Pos.y);
    final p2Center = Offset(_p2Pos.x, _p2Pos.y);
    final p1Out = (p1Center - _arenaCenter).distance > _arenaRadius;
    final p2Out = (p2Center - _arenaCenter).distance > _arenaRadius;

    if (p1Out || p2Out) {
      _gameOver = true;
      final players = gameProvider.lobbyProvider.players;
      final scores = <String, int>{};
      for (final p in players) {
        final isP1 = p.isHost;
        scores[p.id] = (isP1 && !p1Out) || (!isP1 && !p2Out) ? 100 : 0;
      }
      endMiniGame(scores);
    }
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'input' && gameProvider.lobbyProvider.isHost) {
      final angle = (payload['angle'] as num).toDouble();
      final forceMag = (payload['force'] as num).toDouble();
      _p2Vel += Vector2(
        forceMag * _force * (angle * 0.1),
        forceMag * _force * (angle * 0.1),
      );
    } else if (action == 'sync') {
      final p1 = payload['p1'] as List;
      final p2 = payload['p2'] as List;
      _p1Pos = Vector2((p1[0] as num).toDouble(), (p1[1] as num).toDouble());
      _p2Pos = Vector2((p2[0] as num).toDouble(), (p2[1] as num).toDouble());
    }
  }

  // Expose state for renderer
  Offset get p1Offset => Offset(_p1Pos.x, _p1Pos.y);
  Offset get p2Offset => Offset(_p2Pos.x, _p2Pos.y);
}

class _SumoRenderer extends Component with HasGameReference<SumoGame> {
  _SumoRenderer({required SumoGame game}) {
    this.game = game;
  }

  @override
  void render(Canvas canvas) {
    const center = SumoGame._arenaCenter;

    canvas.drawCircle(
      center,
      SumoGame._arenaRadius,
      Paint()..color = const Color(0xFF2D2D44),
    );
    canvas.drawCircle(
      center,
      SumoGame._arenaRadius,
      Paint()
        ..color = const Color(0xFF6C63FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    canvas.drawCircle(
      game.p1Offset,
      SumoGame._ballRadius,
      Paint()..color = const Color(0xFF6C63FF),
    );
    canvas.drawCircle(
      game.p2Offset,
      SumoGame._ballRadius,
      Paint()..color = const Color(0xFFFF6584),
    );
  }
}
