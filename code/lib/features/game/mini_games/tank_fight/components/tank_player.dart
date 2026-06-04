import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TankPlayer extends PositionComponent {
  final String playerId;
  final Color color;

  double targetAngle = 0;
  bool isMoving = false;
  int hp = 3;

  double timeSinceLastShot = 99;

  TankPlayer({required this.playerId, required this.color})
    : super(size: Vector2(40, 40), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    timeSinceLastShot += dt;

    if (isMoving) {
      double diff = targetAngle - angle;
      diff = (diff + pi) % (2 * pi) - pi;
      angle += diff * 12 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (hp <= 0) return; // Không vẽ nếu đã chết

    final paint = Paint()..color = color;

    // Thân xe
    canvas.drawRect(Rect.fromLTWH(0, 4, size.x, size.y - 8), paint);

    // Bánh xích
    final trackPaint = Paint()..color = Colors.black87;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, 6), trackPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.y - 6, size.x, 6), trackPaint);

    // Nòng súng (hướng về phía phải, góc 0)
    final gunPaint = Paint()..color = Colors.grey;
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2, size.y / 2 - 4, size.x / 2 + 12, 8),
      gunPaint,
    );

    // Nắp tháp pháo
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      12,
      Paint()..color = Colors.black45,
    );
  }
}
