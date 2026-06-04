import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../archer_duel_game.dart';

class Arrow extends PositionComponent with HasGameReference<ArcherDuelGame> {
  Vector2 velocity;
  final bool isLocal;
  static const gravity = 980.0;

  Arrow({
    required Vector2 position,
    required this.velocity,
    required this.isLocal,
  }) : super(position: position, size: Vector2(20, 4), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    velocity.y += gravity * dt;
    position += velocity * dt;

    // Quay mũi tên theo hướng bay
    angle = atan2(velocity.y, velocity.x);

    // Kiểm tra va chạm với bản thân (Local Player)
    // Nếu đây là mũi tên của địch bắn sang, và trúng mình -> handleHit
    if (!isLocal) {
      if (toRect().overlaps(game.localPlayer.toRect())) {
        game.handleArrowHit(this);
        return;
      }
    }

    // Kiểm tra bay ra khỏi màn hình
    if (position.x < 0 || position.x > game.size.x) {
      game.handleArrowOutOfBounds(this);
    }

    // Rớt xuống đất quá xa thì xóa
    if (position.y > game.size.y + 100) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(0, 2), Offset(size.x, 2), paint);

    final headPaint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(size.x, 2), 3, headPaint);
  }
}
