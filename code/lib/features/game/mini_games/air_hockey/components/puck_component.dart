import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PuckComponent extends PositionComponent {
  static const double radius = 22;

  PuckComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    // Glow
    canvas.drawCircle(
      Offset(radius, radius),
      radius + 6,
      Paint()
        ..color = const Color(0x3300F0FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Body
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()
        ..color = const Color(0xFF00F0FF)
        ..style = PaintingStyle.fill,
    );
    // Shine
    canvas.drawCircle(
      Offset(radius * 0.65, radius * 0.55),
      radius * 0.3,
      Paint()..color = Colors.white.withAlpha(120),
    );
  }
}
