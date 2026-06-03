import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';

import '../../domain/base_mini_game.dart';
import 'components/paddle_component.dart';
import 'components/puck_component.dart';

/// Khúc Côn Cầu Chéo Màn Hình — mỗi điện thoại là một nửa sân.
///
/// Cơ chế Physics Ownership Transfer:
///   - Tại một thời điểm, chỉ thiết bị OWNER mới tính toán vật lý puck.
///   - Khi puck vượt ranh giới trên (y < 0) → chuyển giao cho đối thủ.
///   - Khi puck vượt ranh giới dưới (y > gameH) → ghi bàn, reset.
///
/// Hệ tọa độ chuẩn hóa khi chuyển giao:
///   x_recv = 1.0 − x_send   (đảo trái-phải vì hai máy úp vào nhau)
///   vy_recv = |vy| * scale   (puck đi vào từ trên xuống)
///   vx_recv = −vx_send       (đảo hướng ngang)
class AirHockeyGame extends BaseMiniGame with DragCallbacks {
  // ── Kích thước sân ảo ────────────────────────────────────────────────────
  static const double gameW = 400;
  static const double gameH = 720;

  // ── Hằng số vật lý ───────────────────────────────────────────────────────
  static const double _wallBounce = 0.85; // hệ số giữ vận tốc khi va tường
  static const double _paddleBounce = 1.05; // puck tăng tốc nhẹ khi chạm paddle
  static const double _maxSpeed = 600.0;
  static const double _minTransferSpeed = 150.0;
  static const int _maxScore = 5;
  static const double _syncHz = 1 / 20; // 20Hz position sync

  // ── Trạng thái puck ──────────────────────────────────────────────────────
  Vector2 _puckPos = Vector2(gameW / 2, gameH / 2);
  Vector2 _puckVel = Vector2.zero();
  bool _isPuckOwner = false; // Host bắt đầu là owner

  // ── Paddle ───────────────────────────────────────────────────────────────
  late PaddleComponent _myPaddle;
  late PaddleComponent _opponentPaddle;

  // ── Điểm số ──────────────────────────────────────────────────────────────
  int _myScore = 0;
  int _opponentScore = 0;

  // ── Timers ───────────────────────────────────────────────────────────────
  double _syncTimer = 0;
  double _resetTimer = -1; // >= 0 → đang đếm reset sau khi ghi bàn
  double _paddleSyncTimer = 0;
  double? _pendingPaddleX; // buffered by onDragUpdate, flushed at 20Hz
  static const double _paddleSyncHz = 1 / 20;

  // ── Components ───────────────────────────────────────────────────────────
  late PuckComponent _puckComp;
  late TextComponent _myScoreText;
  late TextComponent _oppScoreText;
  late TextComponent _goalText;

  bool _isGameOver = false;

  AirHockeyGame(super.gameProvider);

  @override
  String get gameId => 'air_hockey';

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(gameW, gameH);

    // Host sở hữu puck lúc đầu, đặt ở phần sân mình
    _isPuckOwner = gameProvider.lobbyProvider.isHost;
    _puckPos = Vector2(gameW / 2, gameH * 0.65);

    if (_isPuckOwner) {
      _puckVel = Vector2(
        (math.Random().nextDouble() - 0.5) * 200,
        -200, // hướng về phía đối thủ (lên trên)
      );
    }

    // Vẽ sân
    world.add(_ArenaRenderer());

    // Paddle của mình (dưới), đối thủ (trên)
    _myPaddle = PaddleComponent(
      position: Vector2(gameW / 2, gameH * 0.85),
      color: const Color(0xFF6C63FF),
    );
    _opponentPaddle = PaddleComponent(
      position: Vector2(gameW / 2, gameH * 0.15),
      color: const Color(0xFFFF6584),
    );
    world.add(_myPaddle);
    world.add(_opponentPaddle);

    // Puck
    _puckComp = PuckComponent(position: _puckPos.clone());
    world.add(_puckComp);

    // HUD
    _myScoreText = TextComponent(
      text: '0',
      position: Vector2(gameW * 0.85, gameH * 0.7),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 52,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _oppScoreText = TextComponent(
      text: '0',
      position: Vector2(gameW * 0.85, gameH * 0.3),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF6584),
          fontSize: 52,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    _goalText = TextComponent(
      text: '',
      position: Vector2(gameW / 2, gameH / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    world.add(_myScoreText);
    world.add(_oppScoreText);
    world.add(_goalText);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_isGameOver) return;
    // canvasStartPosition là pixel màn hình → chuyển sang toạ độ ảo 400×720
    final worldX = event.canvasStartPosition.x / canvasSize.x * gameW;
    final x = worldX.clamp(
      PaddleComponent.paddleW / 2,
      gameW - PaddleComponent.paddleW / 2,
    );
    _myPaddle.position.x = x;
    _pendingPaddleX = x / gameW; // buffer — flushed at 20Hz in update()
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    // Đếm ngược reset sau ghi bàn
    if (_resetTimer >= 0) {
      _resetTimer -= dt;
      if (_resetTimer < 0) _doReset();
      return;
    }

    // Paddle position — rate-limited to 20Hz
    if (_pendingPaddleX != null) {
      _paddleSyncTimer += dt;
      if (_paddleSyncTimer >= _paddleSyncHz) {
        _paddleSyncTimer = 0;
        gameProvider.sendGameData(gameId, {'action': 'paddle', 'x': _pendingPaddleX!});
        _pendingPaddleX = null;
      }
    }

    if (_isPuckOwner) {
      _simulatePuck(dt);

      _syncTimer += dt;
      if (_syncTimer >= _syncHz) {
        _syncTimer = 0;
        gameProvider.sendGameData(gameId, {
          'action': 'puck_pos',
          'x': _puckPos.x / gameW,
          'y': _puckPos.y / gameH,
        });
      }
    }

    _puckComp.position = _puckPos.clone();
  }

  // ── Physics ───────────────────────────────────────────────────────────────
  void _simulatePuck(double dt) {
    _puckPos += _puckVel * dt;

    // Va tường trái/phải
    if (_puckPos.x - PuckComponent.radius < 0) {
      _puckPos.x = PuckComponent.radius;
      _puckVel.x = _puckVel.x.abs() * _wallBounce;
    } else if (_puckPos.x + PuckComponent.radius > gameW) {
      _puckPos.x = gameW - PuckComponent.radius;
      _puckVel.x = -_puckVel.x.abs() * _wallBounce;
    }

    // Va paddle mình (ở dưới)
    if (_checkPaddleCollision(_myPaddle)) {
      AppAudio.playPuckHit();
      HapticFeedback.lightImpact();
      _puckVel.y = -_puckVel.y.abs() * _paddleBounce; // bật lên
      // Thêm spin theo offset so với tâm paddle
      final spin =
          (_puckPos.x - _myPaddle.position.x) /
          (PaddleComponent.paddleW / 2) *
          120;
      _puckVel.x = (_puckVel.x + spin).clamp(-_maxSpeed, _maxSpeed);
      _capSpeed();
    }

    // Va "paddle ma" đối thủ (ở trên — đảo Y)
    if (_checkPaddleCollision(_opponentPaddle)) {
      _puckVel.y = _puckVel.y.abs() * _paddleBounce; // bật xuống
      final spin =
          (_puckPos.x - _opponentPaddle.position.x) /
          (PaddleComponent.paddleW / 2) *
          120;
      _puckVel.x = (_puckVel.x + spin).clamp(-_maxSpeed, _maxSpeed);
      _capSpeed();
    }

    // Vượt biên TRÊN → chuyển giao cho đối thủ
    if (_puckPos.y - PuckComponent.radius < 0) {
      _transferPuck();
      return;
    }

    // Vượt biên DƯỚI → ghi bàn vào cầu môn mình (đối thủ ghi bàn)
    if (_puckPos.y + PuckComponent.radius > gameH) {
      _onGoalConceded();
    }
  }

  bool _checkPaddleCollision(PaddleComponent paddle) {
    final puckBottom = _puckPos.y + PuckComponent.radius;
    final puckTop = _puckPos.y - PuckComponent.radius;
    final puckLeft = _puckPos.x - PuckComponent.radius;
    final puckRight = _puckPos.x + PuckComponent.radius;

    final padLeft = paddle.position.x - PaddleComponent.paddleW / 2;
    final padRight = paddle.position.x + PaddleComponent.paddleW / 2;
    final padTop = paddle.position.y - PaddleComponent.paddleH / 2;
    final padBottom = paddle.position.y + PaddleComponent.paddleH / 2;

    return puckRight > padLeft &&
        puckLeft < padRight &&
        puckBottom > padTop &&
        puckTop < padBottom;
  }

  void _capSpeed() {
    final speed = _puckVel.length;
    if (speed > _maxSpeed) _puckVel.scale(_maxSpeed / speed);
    if (speed < _minTransferSpeed && speed > 0) {
      _puckVel.scale(_minTransferSpeed / speed);
    }
  }

  // ── Transfer ──────────────────────────────────────────────────────────────
  void _transferPuck() {
    _isPuckOwner = false;
    final normX = _puckPos.x / gameW;
    final normVx = _puckVel.x;
    final normVy = _puckVel.y;

    gameProvider.sendGameData(gameId, {
      'action': 'puck_transfer',
      'x': 1.0 - normX, // đảo X
      'vx': -normVx, // đảo chiều ngang
      'vy': normVy.abs(), // puck luôn đi xuống khi vừa nhận (từ trên vào)
    });
  }

  // ── Goal ──────────────────────────────────────────────────────────────────
  void _onGoalConceded() {
    // Mình bị ghi bàn → đối thủ +1
    _isPuckOwner = false;
    _puckVel = Vector2.zero();

    gameProvider.sendGameData(gameId, {
      'action': 'goal',
      'scorer': 'opponent', // từ góc nhìn của mình, đối thủ ghi
    });

    _opponentScore++;
    _myScoreText.text = '$_myScore';
    _oppScoreText.text = '$_opponentScore';
    _goalText.text = 'GOAL!';

    if (_opponentScore >= _maxScore) {
      _finishGame();
    } else {
      _resetTimer = 2.0;
    }
  }

  void _onGoalScored() {
    AppAudio.playGoal();
    // Đối thủ bị ghi bàn → mình +1
    _myScore++;
    _myScoreText.text = '$_myScore';
    _oppScoreText.text = '$_opponentScore';
    _goalText.text = 'GOAL! ✓';

    if (_myScore >= _maxScore) {
      _finishGame();
    } else {
      _resetTimer = 2.0;
    }
  }

  void _doReset() {
    _goalText.text = '';
    _isPuckOwner = gameProvider.lobbyProvider.isHost;
    _puckPos = Vector2(gameW / 2, gameH * 0.65);

    if (_isPuckOwner) {
      _puckVel = Vector2((math.Random().nextDouble() - 0.5) * 200, -200);
    } else {
      _puckVel = Vector2.zero();
    }
  }

  void _finishGame() {
    _isGameOver = true;
    if (!gameProvider.lobbyProvider.isHost) return;

    final players = gameProvider.lobbyProvider.players;
    final scores = <String, int>{};
    for (final p in players) {
      scores[p.id] = p.isHost ? _myScore * 20 : _opponentScore * 20;
    }
    endMiniGame(scores);
  }

  // ── Network ───────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    switch (action) {
      case 'paddle':
        final x = (payload['x'] as num).toDouble() * gameW;
        // Đảo X để hiển thị paddle đối thủ từ góc nhìn của mình
        _opponentPaddle.position.x = gameW - x;

      case 'puck_transfer':
        _isPuckOwner = true;
        _puckPos = Vector2(
          (payload['x'] as num).toDouble() * gameW,
          PuckComponent.radius + 2, // vào từ biên trên
        );
        _puckVel = Vector2(
          (payload['vx'] as num).toDouble(),
          (payload['vy'] as num).toDouble().abs(), // đi xuống
        );
        _capSpeed();

      case 'puck_pos':
        // Hiện vị trí ghost puck khi đối thủ đang sở hữu
        if (!_isPuckOwner) {
          final x = (1.0 - (payload['x'] as num).toDouble()) * gameW;
          final y = (1.0 - (payload['y'] as num).toDouble()) * gameH;
          _puckPos = Vector2(x, y);
        }

      case 'goal':
        // Đối thủ báo bị ghi bàn → mình vừa ghi bàn
        _onGoalScored();
    }
  }
}

// ── Arena Renderer ────────────────────────────────────────────────────────
class _ArenaRenderer extends Component {
  @override
  void render(Canvas canvas) {
    const w = AirHockeyGame.gameW;
    const h = AirHockeyGame.gameH;

    // Nền
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF0D0D1A),
    );

    // Viền sân
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = const Color(0xFF6C63FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Vạch giữa sân
    canvas.drawLine(
      const Offset(0, h / 2),
      const Offset(w, h / 2),
      Paint()
        ..color = const Color(0x556C63FF)
        ..strokeWidth = 2,
    );

    // Vòng tròn giữa
    canvas.drawCircle(
      const Offset(w / 2, h / 2),
      60,
      Paint()
        ..color = const Color(0x226C63FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Khung thành dưới (mình)
    const goalW = 100.0;
    const goalDepth = 20.0;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH((w - goalW) / 2, h - goalDepth, goalW, goalDepth),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      Paint()..color = const Color(0x446C63FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH((w - goalW) / 2, h - goalDepth, goalW, goalDepth),
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFF6C63FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Khung thành trên (đối thủ)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH((w - goalW) / 2, 0, goalW, goalDepth),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      Paint()..color = const Color(0x44FF6584),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH((w - goalW) / 2, 0, goalW, goalDepth),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFFFF6584)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
