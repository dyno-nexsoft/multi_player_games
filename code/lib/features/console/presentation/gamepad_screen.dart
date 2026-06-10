import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_colors.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../lobby/presentation/lobby_provider.dart';
import 'console_provider.dart';
import '../../../router.dart';

/// Màn hình Tay Cầm Vạn Năng (Universal Gamepad) cho Console Mode.
///
/// Layout: Joystick ảo bên trái — 4 nút A/B/X/Y xếp hình thoi bên phải.
/// Gyroscope đọc ngầm, gói vào mỗi input packet.
/// Nền chớp màu khi host gửi feedback (bị trúng đạn, v.v.).
class GamepadScreen extends StatefulWidget {
  const GamepadScreen({super.key});

  @override
  State<GamepadScreen> createState() => _GamepadScreenState();
}

class _GamepadScreenState extends State<GamepadScreen> {
  late ConsoleProvider _console;

  @override
  void initState() {
    super.initState();
    final lobby = context.read<LobbyProvider>();
    _console = ConsoleProvider(lobby);
    _console.onGameEnded = () {
      if (mounted) {
        lobby.returnToLobby();
        const RoomRoute().go(context);
      }
    };
  }

  @override
  void dispose() {
    _console.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<LobbyProvider>().localPlayer;
    final colors = Theme.of(context).extension<AppColors>()!;
    final playerColor = Color(player?.color ?? colors.neonPurple.toARGB32());

    return ChangeNotifierProvider.value(
      value: _console,
      child: Consumer<ConsoleProvider>(
        builder: (context, console, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final lobby = context.read<LobbyProvider>();
              final shouldLeave = await const ExitGamepadRoute().push<bool>(
                context,
              );
              if (shouldLeave == true && context.mounted) {
                lobby.leaveRoom();
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  // Swipe down -> Mở pause (gửi lệnh cho host)
                  context.read<LobbyProvider>().sendSystemPause();
                }
              },
              onLongPress: () {
                // Long press -> Pause/Stop
                context.read<LobbyProvider>().sendSystemPause();
              },
              onScaleUpdate: (details) {
                if (details.scale < 0.7) {
                  // Pinch in -> Thoát nhanh
                  final lobby = context.read<LobbyProvider>();
                  lobby.leaveRoom();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                color: console.bgColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      _TopBar(playerColor: playerColor, player: player),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Virtual Joystick (grayed when unused) ──────────
                            Expanded(
                              child: Center(
                                child: Opacity(
                                  opacity: console.joystickEnabled ? 1.0 : 0.3,
                                  child: IgnorePointer(
                                    ignoring: !console.joystickEnabled,
                                    child: _VirtualJoystick(
                                      color: playerColor,
                                      onChanged: console.updateJoystick,
                                      onReset: console.resetJoystick,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // ── Action Buttons ─────────────────────────────────
                            Expanded(
                              child: Center(
                                child: _ActionButtonCluster(
                                  color: playerColor,
                                  buttons: console.buttons,
                                  labels: console.buttonLabels,
                                  highlight: console.highlightButton,
                                  onButton: console.setButton,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Gyro hint (khi game dùng cảm biến nghiêng) ───────────
                      if (console.gyroHint)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '↔  Nghiêng máy để lái',
                            style: TextStyle(
                              color: playerColor.withValues(alpha: 0.45),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Color playerColor;
  final dynamic player;
  const _TopBar({required this.playerColor, required this.player});

  @override
  Widget build(BuildContext context) {
    final name = player?.name as String? ?? 'Player';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: playerColor,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            name,
            style: TextStyle(
              color: playerColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Icon(Icons.sports_esports, color: playerColor.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            'Controller',
            style: TextStyle(
              color: playerColor.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Virtual Joystick ──────────────────────────────────────────────────────────

class _VirtualJoystick extends StatefulWidget {
  final Color color;
  final ValueChanged<Offset> onChanged;
  final VoidCallback onReset;

  const _VirtualJoystick({
    required this.color,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _knob = Offset.zero; // -1..1 normalised

  static const double _size = 160;
  static const double _knobRadius = 28;
  static const double _baseRadius = 70;

  void _handlePan(Offset localPosition) {
    const center = Offset(_size / 2, _size / 2);
    final raw = localPosition - center;
    final norm = Offset(raw.dx / _baseRadius, raw.dy / _baseRadius);
    final len = norm.distance;
    final clamped = len > 1.0 ? norm / len : norm;
    setState(() => _knob = clamped);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _handlePan(d.localPosition),
      onPanUpdate: (d) => _handlePan(d.localPosition),
      onPanEnd: (_) {
        setState(() => _knob = Offset.zero);
        widget.onReset();
      },
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: _JoystickPainter(
            knob: _knob,
            color: widget.color,
            baseRadius: _baseRadius,
            knobRadius: _knobRadius,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knob;
  final Color color;
  final double baseRadius;
  final double knobRadius;

  const _JoystickPainter({
    required this.knob,
    required this.color,
    required this.baseRadius,
    required this.knobRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Base circle
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Knob
    final knobCenter =
        center + Offset(knob.dx * baseRadius, knob.dy * baseRadius);
    canvas.drawCircle(
      knobCenter,
      knobRadius,
      Paint()..color = color.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      knobCenter,
      knobRadius * 0.45,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.knob != knob || old.color != color;
}

// ── Action Button Cluster (A/B/X/Y diamond) ───────────────────────────────────

class _ActionButtonCluster extends StatelessWidget {
  final Color color;
  final Map<String, bool> buttons;
  final Map<String, String> labels;
  final String? highlight;
  final void Function(String key, bool pressed) onButton;

  const _ActionButtonCluster({
    required this.color,
    required this.buttons,
    required this.labels,
    required this.onButton,
    this.highlight,
  });

  static const _btnSize = 58.0;

  static List<(String, Color, Alignment)> _defs(AppColors colors) => [
    ('Y', colors.neonPurple, Alignment.topCenter),
    ('X', const Color(0xFF4CAF50), Alignment.centerLeft),
    ('B', colors.neonPink, Alignment.centerRight),
    ('A', const Color(0xFFFFD700), Alignment.bottomCenter),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    const total = _btnSize * 3 + 10.0 * 2;
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: _defs(colors).map((def) {
          final (key, btnColor, align) = def;
          final isA = key == 'A';
          final size = isA ? _btnSize * 1.2 : _btnSize;
          final isEnabled = labels.containsKey(key);
          final customLabel = labels[key] ?? '';
          return Align(
            alignment: align,
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.2,
              child: IgnorePointer(
                ignoring: !isEnabled,
                child: _GamepadButton(
                  buttonKey: key,
                  color: btnColor,
                  size: size,
                  pressed: buttons[key] ?? false,
                  customLabel: customLabel,
                  pulseOnEntry: highlight == key,
                  onChanged: (p) => onButton(key, p),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Gamepad Button (StatefulWidget — supports 3-pulse highlight glow) ─────────

class _GamepadButton extends StatefulWidget {
  final String buttonKey;
  final Color color;
  final double size;
  final bool pressed;
  final String customLabel;
  final bool pulseOnEntry;
  final ValueChanged<bool> onChanged;

  const _GamepadButton({
    required this.buttonKey,
    required this.color,
    required this.size,
    required this.pressed,
    required this.customLabel,
    required this.onChanged,
    this.pulseOnEntry = false,
  });

  @override
  State<_GamepadButton> createState() => _GamepadButtonState();
}

class _GamepadButtonState extends State<_GamepadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  int _pulseCount = 0;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.pulseOnEntry) _startPulse();
  }

  void _startPulse() {
    _glow.forward().then((_) {
      _glow.reverse().then((_) {
        _pulseCount++;
        if (_pulseCount < 3) _startPulse();
      });
    });
  }

  @override
  void didUpdateWidget(_GamepadButton old) {
    super.didUpdateWidget(old);
    if (widget.pulseOnEntry && !old.pulseOnEntry) {
      _pulseCount = 0;
      _startPulse();
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = widget.customLabel.isNotEmpty
        ? widget.customLabel
        : widget.buttonKey;

    return GestureDetector(
      onTapDown: (_) => widget.onChanged(true),
      onTapUp: (_) => widget.onChanged(false),
      onTapCancel: () => widget.onChanged(false),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, gv) {
          final glowAlpha = 0.55 + _glow.value * 0.45;
          final glowBlur = 14.0 + _glow.value * 20.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.pressed
                  ? widget.color
                  : widget.color.withValues(alpha: 0.2),
              border: Border.all(
                color: widget.color.withValues(
                  alpha: widget.pressed ? 1.0 : 0.55,
                ),
                width: widget.pressed ? 3 : 2,
              ),
              boxShadow: (widget.pressed || _glow.value > 0)
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: _glow.value * 4,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.buttonKey,
                  style: TextStyle(
                    color: widget.pressed ? Colors.black87 : widget.color,
                    fontWeight: FontWeight.w900,
                    fontSize: widget.size * 0.28,
                    height: 1.1,
                  ),
                ),
                if (widget.customLabel.isNotEmpty)
                  Text(
                    displayLabel,
                    style: TextStyle(
                      color: (widget.pressed ? Colors.black87 : widget.color)
                          .withValues(alpha: 0.85),
                      fontWeight: FontWeight.bold,
                      fontSize: widget.size * 0.19,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget themeWrapper(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    backgroundColor: AppTheme.bgDeep,
    body: Center(child: child),
  ),
);

@Preview(name: 'Console - Joystick', wrapper: themeWrapper)
Widget previewJoystick() => Padding(
  padding: const EdgeInsets.all(32.0),
  child: _VirtualJoystick(
    color: const Color(0xFF00D9FF),
    onChanged: (_) {},
    onReset: () {},
  ),
);

@Preview(name: 'Console - Buttons', wrapper: themeWrapper)
Widget previewActionButtonCluster() => Padding(
  padding: const EdgeInsets.all(32.0),
  child: _ActionButtonCluster(
    color: const Color(0xFFFF6584),
    buttons: const {'A': true, 'B': false, 'X': false, 'Y': false},
    labels: const {'A': 'Nhảy', 'B': 'Bắn', 'X': '', 'Y': ''},
    highlight: 'B',
    onButton: (k, p) {},
  ),
);

@Preview(name: 'Console - Gamepad Button', wrapper: themeWrapper)
Widget previewGamepadButton() => Padding(
  padding: const EdgeInsets.all(32.0),
  child: _GamepadButton(
    buttonKey: 'A',
    color: const Color(0xFFFFD700),
    size: 80,
    pressed: false,
    customLabel: 'Action',
    pulseOnEntry: true,
    onChanged: (_) {},
  ),
);
