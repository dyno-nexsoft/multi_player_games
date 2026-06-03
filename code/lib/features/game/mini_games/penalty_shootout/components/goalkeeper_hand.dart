import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GoalkeeperHand extends PositionComponent {
  GoalkeeperHand({super.position})
      : super(size: Vector2(60, 40), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFFFD700),
    );
  }
}
