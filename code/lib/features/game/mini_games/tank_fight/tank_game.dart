import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';
import 'components/tank_player.dart';
import 'components/tank_bullet.dart';
import 'components/fog_layer.dart';

class TankGame extends BaseMiniGame {
  TankGame(super.gameProvider);

  @override
  String get gameId => GameIds.tankFight;

  bool get isHost => gameProvider.lobbyProvider.isHost;

  final Map<String, TankPlayer> players = {};

  double _syncTimer = 0;
  static const double _syncRate = 1 / 30; // 30Hz

  bool _gameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (isHost) {
      gameProvider.sendControllerInit(gameId, {
        'joystick_enabled': true,
        'labels': {'A': 'Bắn'},
        'highlight': 'A',
      });
    }

    final lobbyPlayers = gameProvider.lobbyProvider.players;

    int i = 0;
    for (final p in lobbyPlayers) {
      final color = Color(p.color);
      final tank = TankPlayer(playerId: p.id, color: color);
      // Vị trí spawn ở 4 góc
      if (i == 0) {
        // Top-Left
        tank.position = Vector2(80, 80);
        tank.angle = pi / 4;
      } else if (i == 1) {
        // Bottom-Right
        tank.position = Vector2(size.x - 80, size.y - 80);
        tank.angle = -pi * 3 / 4;
      } else if (i == 2) {
        // Top-Right
        tank.position = Vector2(size.x - 80, 80);
        tank.angle = pi * 3 / 4;
      } else {
        // Bottom-Left
        tank.position = Vector2(80, size.y - 80);
        tank.angle = -pi / 4;
      }
      tank.targetAngle = tank.angle;

      players[p.id] = tank;
      add(tank);
      i++;
    }

    // Add Fog of War
    add(FogLayer()..priority = 100);
  }

  void _broadcastState() {
    final state = {};
    for (final p in players.values) {
      state[p.playerId] = {
        'x': p.position.x,
        'y': p.position.y,
        'a': p.angle,
        'hp': p.hp,
        't': p.timeSinceLastShot,
      };
    }

    gameProvider.sendGameData(gameId, {'action': 'sync', 'state': state});
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    if (_gameOver) return;

    final action = payload['action'] as String?;

    if (action == 'sync' && !isHost) {
      final state = payload['state'] as Map?;
      if (state == null) return;

      for (final pId in state.keys) {
        final pData = state[pId] as Map;
        final tank = players[pId.toString()];
        if (tank != null) {
          tank.position = Vector2(
            (pData['x'] as num).toDouble(),
            (pData['y'] as num).toDouble(),
          );
          tank.angle = (pData['a'] as num).toDouble();
          tank.hp = (pData['hp'] as num).toInt();
          tank.timeSinceLastShot = (pData['t'] as num).toDouble();
        }
      }
    }

    if (action == 'shoot' && !isHost) {
      final x = (payload['x'] as num).toDouble();
      final y = (payload['y'] as num).toDouble();
      final vx = (payload['vx'] as num).toDouble();
      final vy = (payload['vy'] as num).toDouble();

      AppAudio.playBump();
      add(
        TankBullet(
          position: Vector2(x, y),
          velocity: Vector2(vx, vy),
          shooterId: payload['shooterId'].toString(),
        ),
      );
    }

    if (action == 'controller' && isHost) {
      final tank = players[senderId];
      if (tank != null && tank.hp > 0) {
        final j = payload['j'] as List?;
        if (j != null && j.length >= 2) {
          final dx = (j[0] as num).toDouble();
          final dy = (j[1] as num).toDouble();
          final mag = sqrt(dx * dx + dy * dy);

          if (mag > 0.1) {
            tank.isMoving = true;
            tank.targetAngle = atan2(dy, dx);
            tank.position += Vector2(dx, dy) * 150 * dtCache;
            // Giới hạn trong màn hình
            tank.position.clamp(Vector2.zero(), size);
          } else {
            tank.isMoving = false;
          }
        }

        final b = payload['b'] as Map?;
        if (b != null && b['A'] == true) {
          if (tank.timeSinceLastShot >= 1.0) {
            tank.timeSinceLastShot = 0;
            _shoot(senderId, tank.position, tank.angle);
          }
        }
      }
    }
  }

  double dtCache = 0.016;

  @override
  void update(double dt) {
    dtCache = dt;
    super.update(dt);
    if (_gameOver) return;

    if (isHost) {
      _syncTimer += dt;
      if (_syncTimer >= _syncRate) {
        _syncTimer = 0;
        _broadcastState();
      }
    }
  }

  void _shoot(String shooterId, Vector2 position, double angle) {
    AppAudio.playBump();
    final velocity = Vector2(cos(angle), sin(angle)) * 400;

    // Spawn bullet local (Host)
    add(
      TankBullet(
        position: position.clone()..add(Vector2(cos(angle), sin(angle)) * 30),
        velocity: velocity,
        shooterId: shooterId,
      ),
    );

    // Broadcast shoot to clients for sound/visual
    gameProvider.sendGameData(gameId, {
      'action': 'shoot',
      'shooterId': shooterId,
      'x': position.x,
      'y': position.y,
      'vx': velocity.x,
      'vy': velocity.y,
    });
  }

  void handleHit(String hitPlayerId) {
    if (!isHost || _gameOver) return;
    final tank = players[hitPlayerId];
    if (tank != null && tank.hp > 0) {
      tank.hp--;
      gameProvider.sendControllerFeedback(
        hitPlayerId,
        hapticType: 'heavy',
        flashColor: 0xFFFF0000,
      );
      AppAudio.playLose();

      if (tank.hp <= 0) {
        _checkGameOver();
      }
    }
  }

  void _checkGameOver() {
    int aliveCount = 0;
    String? winnerId;
    for (final p in players.values) {
      if (p.hp > 0) {
        aliveCount++;
        winnerId = p.playerId;
      }
    }

    if (aliveCount <= 1) {
      _gameOver = true;
      final scores = <String, int>{};
      for (final p in players.values) {
        scores[p.playerId] = (p.playerId == winnerId) ? 10 : 0;
      }
      endMiniGame(scores);
    }
  }
}
