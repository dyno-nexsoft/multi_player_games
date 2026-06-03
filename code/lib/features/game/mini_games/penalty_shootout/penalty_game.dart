import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../../domain/base_mini_game.dart';
import 'components/soccer_ball.dart';
import 'components/goalkeeper_hand.dart';

/// Sút Phạt Đền — người sút (Host) kéo để chọn góc, thủ môn (Client) trượt để cản.
class PenaltyGame extends BaseMiniGame with TapCallbacks {
  late SoccerBall _ball;
  late GoalkeeperHand _hand;
  late TextComponent _shootLabelText;

  Vector2 _ballVelocity = Vector2.zero();
  bool _shooting = false;
  bool _roundOver = false;
  int _score = 0;
  int _round = 0;
  static const _maxRounds = 3;

  PenaltyGame(super.gameProvider);

  @override
  String get gameId => 'penalty_shootout';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 800);

    _ball = SoccerBall(position: Vector2(200, 640));
    _hand = GoalkeeperHand(position: Vector2(200, 180));

    world.add(_ball);
    world.add(_hand);

    _shootLabelText = TextComponent(
      text: 'Tap to shoot!',
      position: Vector2(200, 720),
      anchor: Anchor.center,
    );
    world.add(_shootLabelText);
  }

  @override
  void onMount() {
    super.onMount();
    if (buildContext != null) {
      final l10n = AppLocalizations.of(buildContext!);
      if (l10n != null) {
        _shootLabelText.text = l10n.penaltyTapToShoot;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_shooting || _roundOver) return;
    if (gameProvider.lobbyProvider.isHost) {
      final tapX = event.canvasPosition.x;
      final dx = (tapX - 200) / 200; // normalize -1..1
      _ballVelocity = Vector2(dx * 80, -300);
      _shooting = true;
      AppAudio.playKick();
      HapticFeedback.mediumImpact();
      gameProvider.sendGameData(gameId, {'action': 'shoot', 'dx': dx});
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_shooting) return;

    _ball.position += _ballVelocity * dt;

    if (_ball.position.y < 200) {
      _checkGoal();
    }
  }

  void _checkGoal() {
    _shooting = false;
    final ballX = _ball.position.x;
    final handX = _hand.position.x;
    final saved = (ballX - handX).abs() < 50;

    if (!saved) {
      _score++;
      AppAudio.playGoal();
    }
    _round++;

    if (_round >= _maxRounds) {
      _finishGame();
    } else {
      _ball.position = Vector2(200, 640);
      _ballVelocity = Vector2.zero();
    }
  }

  void _finishGame() {
    _roundOver = true;
    if (!gameProvider.lobbyProvider.isHost) return;
    final players = gameProvider.lobbyProvider.players;
    final scores = <String, int>{};
    for (final p in players) {
      scores[p.id] = p.isHost ? _score * 33 : ((_maxRounds - _score) * 33);
    }
    endMiniGame(scores);
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'slide') {
      final x = (payload['x'] as num).toDouble();
      _hand.position = Vector2(x * 400, 180);
    } else if (action == 'shoot') {
      final dx = (payload['dx'] as num).toDouble();
      _ballVelocity = Vector2(dx * 80, -300);
      _shooting = true;
    }
  }
}
