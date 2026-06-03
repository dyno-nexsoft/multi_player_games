import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SoccerBall extends PositionComponent {
  SoccerBall({super.position})
    : super(size: Vector2(30, 30), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
