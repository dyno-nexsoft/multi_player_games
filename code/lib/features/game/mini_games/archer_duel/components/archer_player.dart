import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ArcherPlayer extends PositionComponent {
  final bool isLeft;

  ArcherPlayer({required this.isLeft})
    : super(size: Vector2(60, 60), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = isLeft ? Colors.blue : Colors.red;
    canvas.drawRect(size.toRect(), paint);

    // Vẽ cây cung đơn giản
    final bowPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final bowRect = Rect.fromLTWH(
      isLeft ? size.x : -10,
      size.y / 2 - 20,
      10,
      40,
    );
    canvas.drawArc(bowRect, isLeft ? -1.57 : 1.57, 3.14, false, bowPaint);
  }
}
