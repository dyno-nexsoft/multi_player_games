import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Component vẽ sợi dây kéo co. position là giá trị từ -1.0 (Client thắng) đến 1.0 (Host thắng).
class RopeComponent extends PositionComponent {
  double ropePosition; // -1.0 đến 1.0

  RopeComponent({this.ropePosition = 0.0});

  @override
  void render(Canvas canvas) {
    final screenW = size.x;
    final screenH = size.y;
    final centerX = screenW / 2 + (ropePosition * screenW * 0.3);

    // Vẽ dây thừng
    final ropePaint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, screenH * 0.5),
      Offset(screenW, screenH * 0.5),
      ropePaint,
    );

    // Vẽ vạch trung tâm (di chuyển theo ropePosition)
    final markerPaint = Paint()..color = Colors.red;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, screenH * 0.5),
        width: 16,
        height: 48,
      ),
      markerPaint,
    );

    // Vạch giữa cố định
    final centerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(screenW / 2, screenH * 0.5 - 32),
      Offset(screenW / 2, screenH * 0.5 + 32),
      centerPaint,
    );
  }
}
