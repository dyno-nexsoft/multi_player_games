import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../maze_game.dart';

class FogLayer extends Component with HasGameReference<MazeGame> {
  @override
  void render(Canvas canvas) {
    final lobby = game.gameProvider.lobbyProvider;
    final localId = lobby.localPlayer?.id;

    final rect = game.camera.visibleWorldRect;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: 0.98),
    );

    final clearPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    for (final p in game.players.values) {
      if (p.eliminated) continue;
      // Console mode: TV audience sees all. P2P mode: each device sees only its player.
      if (!lobby.isConsoleMode && p.playerId != localId) continue;

      double radius = p.isSeeker ? 120.0 : 90.0;

      // Radar ability expands the seeker's vision circle.
      if (p.isSeeker && game.radarActiveTime > 0) {
        radius = 200.0;
      }

      canvas.drawCircle(p.position.toOffset(), radius, clearPaint);
    }

    canvas.restore();

    if (game.radarActiveTime > 0) {
      canvas.drawRect(
        rect,
        Paint()..color = Colors.blue.withValues(alpha: 0.15),
      );
    }
  }
}
