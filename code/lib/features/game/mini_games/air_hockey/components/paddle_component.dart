import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PaddleComponent extends PositionComponent {
  static const double paddleW = 90.0;
  static const double paddleH = 18.0;
  static const double cornerR = 9.0;

  final Color color;

  PaddleComponent({required Vector2 position, required this.color})
    : super(
        position: position,
        size: Vector2(paddleW, paddleH),
        anchor: Anchor.center,
      );

  @override
  void render(Canvas canvas) {
    // Glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4, -4, size.x + 8, size.y + 8),
        const Radius.circular(cornerR + 4),
      ),
      Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(cornerR),
      ),
      Paint()..color = color,
    );
  }
}
