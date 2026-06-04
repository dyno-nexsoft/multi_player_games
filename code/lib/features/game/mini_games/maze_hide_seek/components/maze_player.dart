import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MazePlayer extends PositionComponent {
  final String playerId;
  final bool isSeeker;

  Vector2 velocity = Vector2.zero();
  double speed = 120.0;

  double dashTime = 0;
  double dashCooldown = 0;

  bool eliminated = false;

  MazePlayer({required this.playerId, required this.isSeeker})
    : super(size: Vector2(24, 24), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (dashTime > 0) dashTime -= dt;
    if (dashCooldown > 0) dashCooldown -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = isSeeker ? Colors.redAccent : Colors.lightBlueAccent;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.x / 3, size.y / 3), 3, eyePaint);
    canvas.drawCircle(Offset(size.x * 2 / 3, size.y / 3), 3, eyePaint);

    if (isSeeker) {
      canvas.drawLine(
        Offset(size.x / 4, size.y / 4),
        Offset(size.x / 2 - 2, size.y / 3),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(size.x * 3 / 4, size.y / 4),
        Offset(size.x / 2 + 2, size.y / 3),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }
  }
}
