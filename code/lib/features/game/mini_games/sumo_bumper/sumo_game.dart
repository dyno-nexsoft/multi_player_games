import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../../domain/base_mini_game.dart';

class SumoBumperData {
  final String id;
  final Color color;
  Vector2 pos;
  Vector2 vel = Vector2.zero();
  bool eliminated = false;

  SumoBumperData(this.id, this.color, this.pos);
}

class SumoGame extends BaseMiniGame {
  static const double _arenaRadius = 160.0;
  static const double _ballRadius = 24.0;
  static const double _syncRate = 1 / 30;
  static const double _force = 180.0;
  static const Offset _arenaCenter = Offset(200, 400);

  final Map<String, SumoBumperData> bumpers = {};

  double _syncTimer = 0;
  bool _gameOver = false;

  SumoGame(super.gameProvider);

  @override
  String get gameId => 'sumo_bumper';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 800);

    final players = gameProvider.lobbyProvider.players;
    final spawnPoints = [
      Vector2(120, 400), // Left
      Vector2(280, 400), // Right
      Vector2(200, 320), // Top
      Vector2(200, 480), // Bottom
    ];

    for (int i = 0; i < players.length; i++) {
      final p = players[i];
      final pt = spawnPoints[i % spawnPoints.length];
      bumpers[p.id] = SumoBumperData(p.id, Color(p.color), pt.clone());
    }

    world.add(_SumoRenderer(game: this));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || !gameProvider.lobbyProvider.isHost) return;

    for (final b in bumpers.values) {
      if (b.eliminated) continue;
      b.vel.scale(0.92);
      b.pos += b.vel * dt;
    }

    _resolveCollisions();

    _syncTimer += dt;
    if (_syncTimer >= _syncRate) {
      _syncTimer = 0;
      final syncState = {};
      for (final b in bumpers.values) {
        syncState[b.id] = {'x': b.pos.x, 'y': b.pos.y, 'e': b.eliminated};
      }
      gameProvider.sendGameData(gameId, {'action': 'sync', 'state': syncState});
    }

    _checkElimination();
  }

  void _resolveCollisions() {
    final activeBumpers = bumpers.values.where((b) => !b.eliminated).toList();
    for (int i = 0; i < activeBumpers.length; i++) {
      for (int j = i + 1; j < activeBumpers.length; j++) {
        final b1 = activeBumpers[i];
        final b2 = activeBumpers[j];

        final diff = b2.pos - b1.pos;
        final dist = diff.length;
        if (dist < _ballRadius * 2 && dist > 0) {
          final normal = diff.normalized();
          final overlap = _ballRadius * 2 - dist;
          b1.pos -= normal * (overlap / 2);
          b2.pos += normal * (overlap / 2);

          final relVel = (b2.vel - b1.vel).dot(normal);
          if (relVel < 0) {
            AppAudio.playBump();
            HapticFeedback.mediumImpact();
            b1.vel -= normal * relVel;
            b2.vel += normal * relVel;
          }
        }
      }
    }
  }

  void _checkElimination() {
    int aliveCount = 0;
    String? winnerId;

    for (final b in bumpers.values) {
      if (b.eliminated) continue;

      final pCenter = Offset(b.pos.x, b.pos.y);
      if ((pCenter - _arenaCenter).distance > _arenaRadius) {
        b.eliminated = true;
      } else {
        aliveCount++;
        winnerId = b.id;
      }
    }

    if (aliveCount <= 1 && bumpers.length > 1) {
      _gameOver = true;
      final scores = <String, int>{};
      for (final b in bumpers.values) {
        scores[b.id] = (b.id == winnerId && aliveCount == 1) ? 100 : 0;
      }
      endMiniGame(scores);
    }
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'input' && gameProvider.lobbyProvider.isHost) {
      final bumper = bumpers[senderId];
      if (bumper != null && !bumper.eliminated) {
        final angle = (payload['angle'] as num).toDouble();
        final forceMag = ((payload['force'] as num).toDouble()).clamp(0.0, 1.0);
        bumper.vel += Vector2(
          forceMag * _force * math.cos(angle) * 0.1,
          forceMag * _force * math.sin(angle) * 0.1,
        );
      }
    } else if (action == 'sync') {
      final state = payload['state'] as Map?;
      if (state == null) return;
      for (final pId in state.keys) {
        final data = state[pId] as Map;
        final bumper = bumpers[pId.toString()];
        if (bumper != null) {
          bumper.pos = Vector2(
            (data['x'] as num).toDouble(),
            (data['y'] as num).toDouble(),
          );
          bumper.eliminated = data['e'] as bool;
        }
      }
    }
  }
}

class _SumoRenderer extends Component with HasGameReference<SumoGame> {
  _SumoRenderer({required SumoGame game}) {
    this.game = game;
  }

  @override
  void render(Canvas canvas) {
    const center = SumoGame._arenaCenter;

    canvas.drawCircle(
      center,
      SumoGame._arenaRadius,
      Paint()..color = const Color(0xFF2D2D44),
    );
    canvas.drawCircle(
      center,
      SumoGame._arenaRadius,
      Paint()
        ..color = const Color(0xFF6C63FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    for (final b in game.bumpers.values) {
      if (b.eliminated) continue;
      canvas.drawCircle(
        Offset(b.pos.x, b.pos.y),
        SumoGame._ballRadius,
        Paint()..color = b.color,
      );
    }
  }
}
