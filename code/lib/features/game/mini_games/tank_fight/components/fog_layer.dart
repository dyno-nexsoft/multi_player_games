import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../tank_game.dart';

class FogLayer extends Component with HasGameReference<TankGame> {
  @override
  void render(Canvas canvas) {
    if (!game.isHost) return;

    final rect = game.camera.visibleWorldRect;

    // Save layer to support blend mode dstOut
    canvas.saveLayer(rect, Paint());

    // Fill screen with darkness
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.95),
    );

    final clearPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (final p in game.players.values) {
      if (p.hp <= 0) continue;

      // Bán kính mặc định nhỏ
      double radius = 70.0;

      // Nếu vừa mới bắn, hé lộ vòng lớn hơn (tia chớp súng)
      if (p.timeSinceLastShot < 0.2) {
        radius = 200.0;
      } else if (p.timeSinceLastShot < 0.5) {
        radius = 120.0;
      }

      canvas.drawCircle(p.position.toOffset(), radius, clearPaint);
    }

    canvas.restore();
  }
}
