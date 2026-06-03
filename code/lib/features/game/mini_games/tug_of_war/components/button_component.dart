import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Nút tap lớn chiếm nửa màn hình để người chơi bấm liên tục.
class TapButtonComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onTap;
  bool _pressed = false;

  TapButtonComponent({
    required this.onTap,
    required super.size,
    super.position,
  });

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
    onTap();
  }

  @override
  void onTapUp(TapUpEvent event) => _pressed = false;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = _pressed ? const Color(0x446C63FF) : const Color(0x226C63FF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(24),
      ),
      paint,
    );
  }
}
