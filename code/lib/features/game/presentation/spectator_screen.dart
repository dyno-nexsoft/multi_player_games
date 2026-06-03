import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import '../../lobby/presentation/lobby_provider.dart';

/// Màn hình Khán Giả Tương Tác — xem game và phá đám bằng vật phẩm.
///
/// Spectator không chơi; thay vào đó họ dùng "vật phẩm phá đám" để
/// tác động lên màn hình của người chơi chính (tomato, smoke, ice).
class SpectatorScreen extends StatefulWidget {
  const SpectatorScreen({super.key});

  @override
  State<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends State<SpectatorScreen> {
  // Cooldown timers per disruptor (in seconds remaining)
  final Map<String, int> _cooldowns = {'tomato': 0, 'smoke': 0, 'ice': 0};
  final Map<String, Timer?> _timers = {};

  @override
  void initState() {
    super.initState();
    final lobby = context.read<LobbyProvider>();
    // Khi host kết thúc game, khán giả về phòng chờ.
    lobby.onGameEnded = (_) {
      if (mounted) {
        lobby.returnToLobby();
        context.go('/room');
      }
    };
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t?.cancel();
    }
    super.dispose();
  }

  static const Map<String, (String, String, int, Color)> _disruptors = {
    'tomato': ('🍅', 'Tương Cà Chua', 10, Color(0xFFE53935)),
    'smoke': ('💨', 'Bom Khói', 15, Color(0xFF78909C)),
    'ice': ('❄️', 'Đóng Băng', 20, Color(0xFF29B6F6)),
  };

  void _use(String type) {
    if (_cooldowns[type]! > 0) return;
    HapticFeedback.mediumImpact();
    context.read<LobbyProvider>().sendSpectatorAction(type);

    final (_, _, cooldown, _) = _disruptors[type]!;
    setState(() => _cooldowns[type] = cooldown);
    _timers[type]?.cancel();
    _timers[type] = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldowns[type] = (_cooldowns[type]! - 1).clamp(0, 999);
        if (_cooldowns[type] == 0) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobby = context.read<LobbyProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  NeonTitle('👁️ Khán Giả', fontSize: 18, color: primary),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      lobby.returnToLobby();
                      context.go('/room');
                    },
                    child: const Text('Rời phòng'),
                  ),
                ],
              ),
            ),

            // Live game indicator
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulsingLiveIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Game đang diễn ra...',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Dùng vật phẩm bên dưới để phá đám 😈',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Disruptor toolbar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _disruptors.entries.map((entry) {
                  final type = entry.key;
                  final (emoji, label, _, color) = entry.value;
                  final cd = _cooldowns[type]!;
                  return _DisruptorButton(
                    emoji: emoji,
                    label: label,
                    cooldown: cd,
                    color: color,
                    onTap: cd > 0 ? null : () => _use(type),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingLiveIndicator extends StatefulWidget {
  const _PulsingLiveIndicator();
  @override
  State<_PulsingLiveIndicator> createState() => _PulsingLiveIndicatorState();
}

class _PulsingLiveIndicatorState extends State<_PulsingLiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, anim) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                Colors.red.shade700,
                Colors.red.shade300,
                _ctrl.value,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisruptorButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int cooldown;
  final Color color;
  final VoidCallback? onTap;
  const _DisruptorButton({
    required this.emoji,
    required this.label,
    required this.cooldown,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ready = cooldown == 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: ready ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ready
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: ready ? color : Colors.white12,
                  width: 2,
                ),
                boxShadow: ready
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: ready
                  ? Text(emoji, style: const TextStyle(fontSize: 30))
                  : Text(
                      '$cooldown',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: ready ? color : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
