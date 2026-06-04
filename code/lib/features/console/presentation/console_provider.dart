import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/network/game_packet.dart';
import '../../lobby/presentation/lobby_provider.dart';

/// Quản lý toàn bộ vòng đời của màn hình Tay Cầm trong Console Mode.
///
/// Gửi input (joystick, nút, gyroscope) về Host ở tần số 30Hz.
/// Nhận feedback (rung, chớp màn hình) từ Host và kích hoạt ngay lập tức.
class ConsoleProvider extends ChangeNotifier {
  final LobbyProvider lobbyProvider;
  bool _disposed = false;

  ConsoleProvider(this.lobbyProvider) {
    lobbyProvider.onControllerFeedback = _onFeedback;
    lobbyProvider.onGameEnded = (_) => onGameEnded?.call();
    lobbyProvider.onControllerInit = _applyConfig;
    _startGyro();
    _startSendTimer();
  }

  // ── Controller configuration (sent by host via init_controller) ────────────

  bool joystickEnabled = true;
  bool gyroHint = false;
  Map<String, String> buttonLabels = const {'A': '', 'B': '', 'X': '', 'Y': ''};
  String? highlightButton;
  bool highlightDone = false;

  void _applyConfig(Map<String, dynamic> config) {
    joystickEnabled = (config['joystick_enabled'] as bool?) ?? true;
    gyroHint = (config['gyro_hint'] as bool?) ?? false;
    final raw = config['labels'] as Map?;
    if (raw != null) {
      buttonLabels = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      buttonLabels = const {
        'A': '',
        'B': '',
        'X': '',
        'Y': '',
      }; // All enabled by default
    }
    highlightButton = config['highlight'] as String?;
    highlightDone = false;
    notifyListeners();
  }

  // ── Input state ────────────────────────────────────────────────────────────

  /// Joystick vector, clamped to unit circle, -1..1 per axis.
  Offset _joystick = Offset.zero;
  Offset get joystick => _joystick;

  final Map<String, bool> _buttons = {
    'A': false,
    'B': false,
    'X': false,
    'Y': false,
  };
  Map<String, bool> get buttons => Map.unmodifiable(_buttons);

  double _gyroX = 0;
  double _gyroY = 0;

  /// True whenever input has changed since the last packet was sent.
  /// Cleared after each send so idle ticks are suppressed.
  bool _inputDirty = false;

  /// Màu nền hiện tại — chớp khi nhận feedback từ host.
  Color bgColor = const Color(0xFF0D0D1A);

  /// Callback khi host kết thúc game → GamepadScreen navigate về /room.
  VoidCallback? onGameEnded;

  // ── Joystick ───────────────────────────────────────────────────────────────

  void updateJoystick(Offset raw) {
    final len = raw.distance;
    _joystick = len > 1.0 ? raw / len : raw;
    _inputDirty = true;
  }

  void resetJoystick() {
    _joystick = Offset.zero;
    _inputDirty = true;
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  void setButton(String key, bool pressed) {
    if (_buttons[key] == pressed) return;
    _buttons[key] = pressed;
    _inputDirty = true;
    if (pressed) HapticFeedback.selectionClick();
    notifyListeners();
  }

  // ── Gyroscope ──────────────────────────────────────────────────────────────

  StreamSubscription<GyroscopeEvent>? _gyroSub;

  void _startGyro() {
    try {
      _gyroSub = gyroscopeEventStream().listen(
        (event) {
          _gyroX = event.x;
          _gyroY = event.y;
          _inputDirty = true;
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  // ── 30Hz send loop ─────────────────────────────────────────────────────────

  Timer? _sendTimer;

  void _startSendTimer() {
    _sendTimer = Timer.periodic(
      const Duration(milliseconds: 33),
      (_) => _sendInput(),
    );
  }

  void _sendInput() {
    final joystickActive = _joystick.distance > 0.01;
    final buttonActive = _buttons.values.any((pressed) => pressed);
    // Skip the packet when fully idle and nothing has changed since last send.
    if (!joystickActive && !buttonActive && !_inputDirty) return;
    _inputDirty = false;
    lobbyProvider.sendGamePacket(
      GamePacket(
        type: PacketType.controllerInput,
        senderId: lobbyProvider.localPlayer?.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: {
          'j': [_joystick.dx, _joystick.dy],
          'b': Map<String, dynamic>.from(_buttons),
          'g': [_gyroX, _gyroY],
        },
      ),
    );
  }

  // ── Feedback từ host ───────────────────────────────────────────────────────

  void _onFeedback(String hapticType, int? flashColor) {
    switch (hapticType) {
      case 'heavy':
        HapticFeedback.heavyImpact();
      case 'medium':
        HapticFeedback.mediumImpact();
      case 'selection':
        HapticFeedback.selectionClick();
      default:
        HapticFeedback.lightImpact();
    }

    if (flashColor != null) {
      bgColor = Color(flashColor).withValues(alpha: 0.6);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_disposed) return;
        bgColor = const Color(0xFF0D0D1A);
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sendTimer?.cancel();
    _gyroSub?.cancel();
    lobbyProvider.onControllerFeedback = null;
    lobbyProvider.onGameEnded = null;
    lobbyProvider.onControllerInit = null;
    super.dispose();
  }
}

/// Konvert offset joystick sang angle (radian) để các game tính hướng di chuyển.
double joystickAngle(Offset v) => atan2(v.dy, v.dx);

/// Độ lớn joystick 0..1.
double joystickMagnitude(Offset v) => v.distance.clamp(0.0, 1.0);
