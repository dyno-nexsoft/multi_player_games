import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/utils/title_system.dart';
import 'package:party_game_hub/features/lobby/domain/player.dart';

/// Thẻ Game Thủ Kỹ Thuật Số — hiển thị avatar, màu neon, danh hiệu.
/// Dùng ở RoomScreen (danh sách người chơi) và Victory Screen (người thắng).
class GamerCard extends StatelessWidget {
  final Player player;
  final int wins;
  final bool isWinner;
  final bool compact;

  const GamerCard({
    super.key,
    required this.player,
    this.wins = 0,
    this.isWinner = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(player.color);
    final title = TitleSystem.titleFor(wins);
    final badge = TitleSystem.badgeFor(wins);
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

    if (compact) {
      return _CompactCard(player: player, color: color, badge: badge);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isWinner ? 0.9 : 0.4),
          width: isWinner ? 2.5 : 1.5,
        ),
        boxShadow: AppTheme.glowShadow(color, blur: isWinner ? 24 : 10),
      ),
      child: Row(
        children: [
          // Avatar
          _Avatar(initial: initial, color: color, size: 56, isWinner: isWinner),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    color: isWinner ? const Color(0xFFFFD700) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(badge, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isWinner) const Text('👑', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final Player player;
  final Color color;
  final String badge;
  const _CompactCard({
    required this.player,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(initial: initial, color: color, size: 44, isWinner: false),
        const SizedBox(height: 4),
        Text(
          player.name,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        Text(badge, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final Color color;
  final double size;
  final bool isWinner;
  const _Avatar({
    required this.initial,
    required this.color,
    required this.size,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isWinner ? 0.7 : 0.4),
            blurRadius: isWinner ? 18 : 8,
            spreadRadius: isWinner ? 3 : 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Wrapper slide-in animation — dùng ở RoomScreen khi người chơi mới join.
class SlideInGamerCard extends StatefulWidget {
  final Player player;
  final int wins;

  const SlideInGamerCard({super.key, required this.player, this.wins = 0});

  @override
  State<SlideInGamerCard> createState() => _SlideInGamerCardState();
}

class _SlideInGamerCardState extends State<SlideInGamerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GamerCard(player: widget.player, wins: widget.wins),
        ),
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

@Preview(name: 'GamerCard - Normal', wrapper: themeWrapper)
Widget previewGamerCardNormal() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: GamerCard(
    player: Player(id: '1', name: 'John Doe', color: 0xFF6C63FF),
    wins: 2,
  ),
);

@Preview(name: 'GamerCard - Winner', wrapper: themeWrapper)
Widget previewGamerCardWinner() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: GamerCard(
    player: Player(id: '2', name: 'Jane Doe', color: 0xFFFFD700),
    wins: 5,
    isWinner: true,
  ),
);

@Preview(name: 'GamerCard - Compact', wrapper: themeWrapper)
Widget previewGamerCardCompact() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: GamerCard(
    player: Player(id: '3', name: 'Alex', color: 0xFFFF6584),
    wins: 1,
    compact: true,
  ),
);

@Preview(name: 'GamerCard - SlideIn', wrapper: themeWrapper)
Widget previewGamerCardSlideIn() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: SlideInGamerCard(
    player: Player(id: '4', name: 'New Player', color: 0xFF00D9FF),
  ),
);
