import 'dart:ui' show lerpDouble;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';
import 'components/rope_component.dart';
import 'components/button_component.dart';

/// Kéo Co Tốc Độ — tap liên tục để kéo sợi dây về phía mình.
///
/// Host là authority về vị trí dây. Client gửi mỗi lần tap.
/// Sau 30 giây, phía nào kéo dây về phần của mình thắng.
class TugOfWarGame extends BaseMiniGame {
  static const double _winThreshold = 0.85;
  static const double _tapPower = 0.025;
  static const double _decayRate = 0.008;
  static const double _syncHz = 1 / 15; // 15Hz đủ cho game tap
  static const double _gameDuration = 30.0;

  double _ropePosition = 0.0; // -1.0 = Client wins | +1.0 = Host wins
  double _syncTimer = 0;
  double _timeLeft = _gameDuration;
  bool _gameEnded = false;
  bool _cancelled = false;

  static final _timerPaintNormal = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
  );
  static final _timerPaintUrgent = TextPaint(
    style: const TextStyle(
      color: Colors.red,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
  );

  late RopeComponent _rope;
  late TextComponent _timerText;
  late TextComponent _resultText;
  late TextComponent _tapLabelText;
  late _PowerBarComponent _powerBar;

  TugOfWarGame(super.gameProvider);

  @override
  String get gameId => GameIds.tugOfWar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 800);

    world.add(_TugBackground());

    _rope = RopeComponent()..size = Vector2(400, 800);
    world.add(_rope);

    _powerBar = _PowerBarComponent(position: Vector2(200, 400));
    world.add(_powerBar);

    // Nút tap — chiếm phần lớn màn hình
    world.add(
      TapButtonComponent(
        size: Vector2(380, 340),
        position: Vector2(10, 430),
        onTap: _onLocalTap,
      ),
    );

    final isHost = gameProvider.lobbyProvider.isHost;
    final labelColor = isHost
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6584);

    _tapLabelText = TextComponent(
      text: 'TAP NOW! ▼',
      position: Vector2(200, 590),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: labelColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    world.add(_tapLabelText);

    _timerText = TextComponent(
      text: '30',
      position: Vector2(200, 20),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    world.add(_timerText);

    _resultText = TextComponent(
      text: '',
      position: Vector2(200, 400),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 8, offset: Offset(2, 2)),
          ],
        ),
      ),
    );
    world.add(_resultText);
  }

  @override
  void onMount() {
    super.onMount();
    if (buildContext != null) {
      final l10n = AppLocalizations.of(buildContext!);
      if (l10n != null) {
        _tapLabelText.text = l10n.tugOfWarTapLabel;
      }
    }
  }

  void _onLocalTap() {
    if (_gameEnded) return;
    AppAudio.playTap();
    HapticFeedback.lightImpact();
    if (gameProvider.lobbyProvider.isHost) {
      _ropePosition = (_ropePosition + _tapPower).clamp(-1.0, 1.0);
    } else {
      // Client-side prediction: apply locally, server sẽ correct qua lerp
      _ropePosition = (_ropePosition - _tapPower).clamp(-1.0, 1.0);
      gameProvider.sendGameData(gameId, {'action': 'tap'});
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameEnded) return;

    if (gameProvider.lobbyProvider.isHost) {
      _timeLeft -= dt;
      if (_timeLeft <= 0) {
        _timeLeft = 0;
        _resolveByTime();
        return;
      }

      _ropePosition *= (1.0 - _decayRate);

      _syncTimer += dt;
      if (_syncTimer >= _syncHz) {
        _syncTimer = 0;
        gameProvider.sendGameData(gameId, {
          'action': 'state',
          'rope': _ropePosition,
          'time': _timeLeft,
        });
      }

      if (_ropePosition >= _winThreshold) {
        _endGame(hostWins: true);
      } else if (_ropePosition <= -_winThreshold) {
        _endGame(hostWins: false);
      }
    }

    _rope.ropePosition = _ropePosition;
    _powerBar.ropePosition = _ropePosition;
    _timerText.text = _timeLeft.ceil().toString();
    _timerText.textRenderer = _timeLeft <= 5
        ? _timerPaintUrgent
        : _timerPaintNormal;
  }

  void _resolveByTime() {
    _endGame(hostWins: _ropePosition >= 0);
  }

  void _endGame({required bool hostWins}) {
    if (_gameEnded) return;
    _gameEnded = true;

    final isHost = gameProvider.lobbyProvider.isHost;
    final iWin = (isHost && hostWins) || (!isHost && !hostWins);

    final l10n = buildContext != null
        ? AppLocalizations.of(buildContext!)
        : null;
    _resultText.text = iWin
        ? (l10n?.winText ?? '🏆 THẮNG!')
        : (l10n?.loseText ?? '😢 THUA!');

    if (isHost) {
      // Khoảnh khắc "dây đứt" — cả hai máy rung đồng bộ.
      gameProvider.triggerSyncHaptic();
      // Thông báo client kết quả trước khi dừng gửi state packets
      gameProvider.sendGameData(gameId, {
        'action': 'game_over',
        'host_wins': hostWins,
      });

      final players = gameProvider.lobbyProvider.players;
      final scores = <String, int>{};
      for (final p in players) {
        scores[p.id] = (p.isHost == hostWins) ? 100 : 0;
      }
      // endMiniGame trong base class sẽ phát win/lose audio cho host
      Future.delayed(const Duration(seconds: 2), () {
        if (!_cancelled) endMiniGame(scores);
      });
    }
    // Client: GameProvider phát win/lose audio khi nhận gói end_game từ host.
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    if (action == 'tap' && gameProvider.lobbyProvider.isHost) {
      _ropePosition = (_ropePosition - _tapPower).clamp(-1.0, 1.0);
    } else if (action == 'state') {
      // Blend prediction về giá trị authoritative từ host
      final serverPos = (payload['rope'] as num).toDouble();
      _ropePosition = lerpDouble(_ropePosition, serverPos, 0.3)!;
      _timeLeft = (payload['time'] as num).toDouble();
    } else if (action == 'game_over') {
      final hostWins = payload['host_wins'] as bool;
      _endGame(hostWins: hostWins);
    }
  }
}

// ── Background ────────────────────────────────────────────────────────────
class _TugBackground extends Component {
  @override
  void render(Canvas canvas) {
    // Gradient nền
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      ).createShader(const Rect.fromLTWH(0, 0, 400, 800));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 800), paint);

    // Vạch giữa
    canvas.drawLine(
      const Offset(0, 400),
      const Offset(400, 400),
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..strokeWidth = 1,
    );
  }
}

// ── Power Bar ─────────────────────────────────────────────────────────────
class _PowerBarComponent extends PositionComponent {
  double ropePosition = 0.0;
  static const double _barW = 300.0;
  static const double _barH = 12.0;

  _PowerBarComponent({required super.position})
    : super(anchor: Anchor.center, size: Vector2(_barW, _barH));

  @override
  void render(Canvas canvas) {
    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, _barW, _barH),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0x33FFFFFF),
    );

    // Fill — chia 2 bên từ giữa
    final center = _barW / 2;
    final fill = (ropePosition * _barW / 2).abs().clamp(0.0, _barW / 2);
    final isHostWinning = ropePosition > 0;

    final fillColor = isHostWinning
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6584);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        isHostWinning
            ? Rect.fromLTWH(center, 0, fill, _barH)
            : Rect.fromLTWH(center - fill, 0, fill, _barH),
        const Radius.circular(6),
      ),
      Paint()..color = fillColor,
    );

    // Marker giữa
    canvas.drawRect(
      Rect.fromLTWH(center - 2, -4, 4, _barH + 8),
      Paint()..color = Colors.white,
    );

    // Labels
    const textStyle = TextStyle(
      color: Colors.white54,
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );
    final hostPainter = TextPainter(
      text: const TextSpan(text: 'HOST', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    hostPainter.paint(canvas, const Offset(_barW - 36, _barH + 6));

    final clientPainter = TextPainter(
      text: const TextSpan(text: 'CLIENT', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    clientPainter.paint(canvas, const Offset(0, _barH + 6));
  }
}
