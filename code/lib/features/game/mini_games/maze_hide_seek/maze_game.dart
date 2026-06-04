import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';
import 'components/maze_player.dart';
import 'components/maze_map.dart';
import 'components/fog_layer.dart';

class MazeGame extends BaseMiniGame {
  MazeGame(super.gameProvider);

  @override
  String get gameId => GameIds.mazeHideSeek;

  bool get isHost => gameProvider.lobbyProvider.isHost;

  final Map<String, MazePlayer> players = {};

  double _syncTimer = 0;
  static const double _syncRate = 1 / 30;

  bool _gameOver = false;
  double timeRemaining = 60.0;

  double radarActiveTime = 0;
  double radarCooldown = 0;

  double dtCache = 0.016;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 600);
    camera.viewfinder.position = Vector2(200, 300);
    camera.viewfinder.anchor = Anchor.center;

    if (isHost) {
      // Seeker is Host (P1) and gets Radar.
      // Hider is Client (P2) and gets Dash.
      // But we broadcast the identical layout. The labels can be generic.
      gameProvider.sendControllerInit(gameId, {
        'joystick_enabled': true,
        'labels': {'A': 'Kỹ Năng'},
        'highlight': 'A',
      });
    }

    world.add(MazeMap());

    final lobbyPlayers = gameProvider.lobbyProvider.players;

    int i = 0;
    final hiderSpawns = [
       Vector2(340, 540),
       Vector2(340, 60),
       Vector2(60, 540),
    ];
    for (final p in lobbyPlayers) {
      final isSeeker = i == 0;
      final tank = MazePlayer(playerId: p.id, isSeeker: isSeeker);

      if (isSeeker) {
        tank.position = Vector2(60, 60);
      } else {
        tank.position = hiderSpawns[(i - 1) % hiderSpawns.length];
      }

      players[p.id] = tank;
      world.add(tank);
      i++;
    }

    world.add(FogLayer()..priority = 100);
  }

  @override
  void update(double dt) {
    dtCache = dt;
    super.update(dt);
    if (_gameOver) return;

    if (radarActiveTime > 0) radarActiveTime -= dt;
    if (radarCooldown > 0) radarCooldown -= dt;

    if (isHost) {
      timeRemaining -= dt;
      if (timeRemaining <= 0) {
        timeRemaining = 0;
        _endGame(hiderWins: true);
        return;
      }

      _syncTimer += dt;
      if (_syncTimer >= _syncRate) {
        _syncTimer = 0;
        _broadcastState();
      }

      for (final p in players.values) {
        if (p.eliminated) continue;
        if (p.velocity.length2 > 0) {
          final ds =
              p.velocity * (p.dashTime > 0 ? p.speed * 2.5 : p.speed) * dt;

          p.position.x += ds.x;
          if (MazeMap.isWall(p.toRect())) {
            p.position.x -= ds.x;
          }

          p.position.y += ds.y;
          if (MazeMap.isWall(p.toRect())) {
            p.position.y -= ds.y;
          }

          p.position.clamp(Vector2(12, 12), Vector2(400 - 12, 600 - 12));
        }
      }

      MazePlayer? seeker;
      int aliveHiders = 0;
      for (final p in players.values) {
        if (p.isSeeker) {
          seeker = p;
        } else if (!p.eliminated) {
          aliveHiders++;
        }
      }

      if (seeker != null) {
         for (final p in players.values) {
            if (!p.isSeeker && !p.eliminated) {
               if (seeker.toRect().overlaps(p.toRect())) {
                  p.eliminated = true;
                  aliveHiders--;
                  AppAudio.playLose();
                  gameProvider.sendControllerFeedback(p.playerId, hapticType: 'heavy', flashColor: 0xFFFF0000);
               }
            }
         }
      }
      
      if (aliveHiders == 0) {
         _endGame(hiderWins: false);
      }
    }
  }

  void _broadcastState() {
    final state = {};
    for (final p in players.values) {
      state[p.playerId] = {
        'x': p.position.x,
        'y': p.position.y,
        'dash': p.dashTime > 0,
        'e': p.eliminated,
      };
    }

    gameProvider.sendGameData(gameId, {
      'action': 'sync',
      'state': state,
      'time': timeRemaining,
      'radar': radarActiveTime > 0,
    });
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    if (_gameOver) return;

    final action = payload['action'] as String?;

    if (action == 'sync' && !isHost) {
      timeRemaining = (payload['time'] as num).toDouble();
      radarActiveTime = (payload['radar'] as bool) ? 1.0 : 0.0;

      final state = payload['state'] as Map?;
      if (state == null) return;

      for (final pId in state.keys) {
        final pData = state[pId] as Map;
        final p = players[pId.toString()];
        if (p != null) {
          p.position = Vector2(
            (pData['x'] as num).toDouble(),
            (pData['y'] as num).toDouble(),
          );
          if (pData['dash'] as bool) {
            p.dashTime = 0.1;
          }
          p.eliminated = pData['e'] as bool;
        }
      }
    }

    if (action == 'controller' && isHost) {
      final p = players[senderId];
      if (p != null) {
        final j = payload['j'] as List?;
        if (j != null && j.length >= 2) {
          final dx = (j[0] as num).toDouble();
          final dy = (j[1] as num).toDouble();
          p.velocity = Vector2(dx, dy);
        }

        final b = payload['b'] as Map?;
        if (b != null && b['A'] == true) {
          if (p.isSeeker) {
            if (radarCooldown <= 0) {
              radarActiveTime = 1.0;
              radarCooldown = 10.0;
              AppAudio.playBump();
              gameProvider.sendControllerFeedback(
                senderId,
                hapticType: 'heavy',
              );
            }
          } else {
            if (p.dashCooldown <= 0 && p.velocity.length2 > 0) {
              p.dashTime = 0.3;
              p.dashCooldown = 5.0;
              AppAudio.playBump();
              gameProvider.sendControllerFeedback(
                senderId,
                hapticType: 'heavy',
              );
            }
          }
        }
      }
    }
  }

  void _endGame({required bool hiderWins}) {
    if (_gameOver) return;
    _gameOver = true;

    final scores = <String, int>{};
    for (final p in players.values) {
      if (p.isSeeker) {
         scores[p.playerId] = hiderWins ? 0 : 10;
      } else {
         scores[p.playerId] = (!p.eliminated) ? 10 : 0;
      }
    }
    endMiniGame(scores);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tp = TextPainter(
      text: TextSpan(
        text: '00:${timeRemaining.ceil().toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Scale the canvas for UI render to not depend on camera
    tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, 40));
  }
}
