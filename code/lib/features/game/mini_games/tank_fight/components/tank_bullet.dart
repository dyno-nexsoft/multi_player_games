import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../tank_game.dart';

class TankBullet extends PositionComponent with HasGameReference<TankGame> {
  final String shooterId;
  final Vector2 velocity;

  TankBullet({
    required Vector2 position,
    required this.velocity,
    required this.shooterId,
  }) : super(position: position, size: Vector2(8, 8), anchor: Anchor.center) {
    angle = atan2(velocity.y, velocity.x);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (game.isHost) {
      if (position.x < -50 ||
          position.x > game.size.x + 50 ||
          position.y < -50 ||
          position.y > game.size.y + 50) {
        removeFromParent();
        return;
      }

      // Host check collision
      for (final p in game.players.values) {
        if (p.playerId != shooterId && p.hp > 0) {
          if (toRect().overlaps(p.toRect())) {
            game.handleHit(p.playerId);
            removeFromParent();
            return;
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      4,
      Paint()..color = Colors.yellow,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      2,
      Paint()..color = Colors.white,
    );
  }
}
