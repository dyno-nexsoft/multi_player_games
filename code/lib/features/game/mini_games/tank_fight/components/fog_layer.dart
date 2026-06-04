import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../tank_game.dart';

class FogLayer extends Component with HasGameReference<TankGame> {
  @override
  void render(Canvas canvas) {
    final lobby = game.gameProvider.lobbyProvider;
    final localId = lobby.localPlayer?.id;

    final rect = game.camera.visibleWorldRect;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.95),
    );

    final clearPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (final p in game.players.values) {
      if (p.hp <= 0) continue;
      // Console mode: TV is the audience — reveal all tanks.
      // P2P mode: each device only reveals its own tank's vicinity.
      if (!lobby.isConsoleMode && p.playerId != localId) continue;

      double radius = 70.0;
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
