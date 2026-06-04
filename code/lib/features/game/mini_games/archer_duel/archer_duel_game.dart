import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/game_packet.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';
import 'components/archer_player.dart';
import 'components/arrow.dart';

class ArcherDuelGame extends BaseMiniGame with PanDetector {
  ArcherDuelGame(super.gameProvider);

  @override
  String get gameId => GameIds.archerDuel;

  late ArcherPlayer localPlayer;
  late ArcherPlayer remotePlayer;

  Vector2? _dragStart;
  Vector2? _dragCurrent;

  int _localHp = 3;
  int _remoteHp = 3;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final isHost = gameProvider.lobbyProvider.isHost;

    // Host ở bên trái, Client ở bên phải
    localPlayer = ArcherPlayer(isLeft: isHost);
    remotePlayer = ArcherPlayer(isLeft: !isHost);

    localPlayer.position = Vector2(isHost ? 100 : size.x - 100, size.y - 150);
    remotePlayer.position = Vector2(!isHost ? 100 : size.x - 100, size.y - 150);

    add(localPlayer);
    add(remotePlayer);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (gameProvider.isSeriesOver || _localHp <= 0 || _remoteHp <= 0) return;
    _dragStart = info.eventPosition.global;
    _dragCurrent = _dragStart;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_dragStart == null) return;
    _dragCurrent = info.eventPosition.global;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (_dragStart == null || _dragCurrent == null) return;
    final dragVector = _dragStart! - _dragCurrent!;
    _dragStart = null;
    _dragCurrent = null;

    if (dragVector.length < 20) return; // Bỏ qua nếu kéo quá ngắn

    final velocity = dragVector * 4.0; // Hệ số lực
    _shootArrow(localPlayer.position.clone()..y -= 20, velocity, isLocal: true);
  }

  void _shootArrow(
    Vector2 position,
    Vector2 velocity, {
    required bool isLocal,
  }) {
    final arrow = Arrow(
      position: position,
      velocity: velocity,
      isLocal: isLocal,
    );
    add(arrow);
  }

  void handleArrowOutOfBounds(Arrow arrow) {
    if (!arrow.isLocal) {
      arrow.removeFromParent();
      return;
    }

    // Gửi packet sang máy kia
    final localId = gameProvider.lobbyProvider.localPlayer?.id;
    gameProvider.lobbyProvider.sendGamePacket(
      GamePacket(
        type: PacketType.gameData,
        gameId: gameId,
        senderId: localId,
        payload: {
          'action': 'arrow_transfer',
          'x': arrow.position.x,
          'y': arrow.position.y,
          'vx': arrow.velocity.x,
          'vy': arrow.velocity.y,
          'screenWidth': size.x,
        },
      ),
    );

    arrow.removeFromParent();
  }

  void handleArrowHit(Arrow arrow) {
    arrow.removeFromParent();
    if (arrow.isLocal) {
      // local arrow hit remote player
    } else {
      // remote arrow hit local player
      _localHp--;
      gameProvider.triggerSyncHaptic();

      final localId = gameProvider.lobbyProvider.localPlayer?.id;
      gameProvider.lobbyProvider.sendGamePacket(
        GamePacket(
          type: PacketType.gameData,
          gameId: gameId,
          senderId: localId,
          payload: {'action': 'hit'},
        ),
      );

      if (_localHp <= 0) {
        _endGame(localLost: true);
      }
    }
  }

  void _endGame({required bool localLost}) {
    final localId = gameProvider.lobbyProvider.localPlayer?.id ?? 'p1';
    final remoteId = gameProvider.lobbyProvider.players
        .firstWhere(
          (p) => p.id != localId,
          orElse: () => gameProvider.lobbyProvider.players.first,
        )
        .id;

    final scores = {localId: localLost ? 0 : 1, remoteId: localLost ? 1 : 0};
    endMiniGame(scores);
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'hit') {
      _remoteHp--;
      gameProvider.triggerSyncHaptic();
      if (_remoteHp <= 0) {
        _endGame(localLost: false);
      }
      return;
    }

    if (action == 'arrow_transfer') {
      final senderWidth = (payload['screenWidth'] as num).toDouble();
      final rx = (payload['x'] as num).toDouble();
      final ry = (payload['y'] as num).toDouble();
      final rvx = (payload['vx'] as num).toDouble();
      final rvy = (payload['vy'] as num).toDouble();

      double newX;
      if (rx > senderWidth - 10) {
        newX = 0; // Bay từ trái sang phải
      } else {
        newX = size.x; // Bay từ phải sang trái
      }

      _shootArrow(Vector2(newX, ry), Vector2(rvx, rvy), isLocal: false);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Drag Line
    if (_dragStart != null && _dragCurrent != null) {
      final paint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 4;

      final dragVector = _dragStart! - _dragCurrent!;
      final endPoint = localPlayer.position + dragVector;
      canvas.drawLine(
        localPlayer.position.toOffset(),
        endPoint.toOffset(),
        paint,
      );
    }

    // Draw HP
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Local HP
    textPainter.text = TextSpan(
      text: 'HP: $_localHp',
      style: const TextStyle(
        color: Colors.green,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(localPlayer.position.x - 30, localPlayer.position.y - 60),
    );

    // Remote HP
    textPainter.text = TextSpan(
      text: 'HP: $_remoteHp',
      style: const TextStyle(
        color: Colors.red,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(remotePlayer.position.x - 30, remotePlayer.position.y - 60),
    );
  }
}
