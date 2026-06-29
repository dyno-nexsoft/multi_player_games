import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../features/game/domain/game_ids.dart';
import '../../features/game/domain/mini_game_metadata.dart';
import '../../features/game/domain/mini_game_registry.dart';
import 'app_colors.dart';

// ── GlassCard ──────────────────────────────────────────────────────────────
/// Glassmorphism card — blur backdrop + neon border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    required this.child,
    this.borderRadius = 16,
    this.borderColor,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = borderColor ?? colors.neonPurple;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.bgSurface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── NeonGameCard ───────────────────────────────────────────────────────────
/// Tappable game selection card — large icon + title, neon glow on press.
class NeonGameCard extends StatefulWidget {
  final MiniGameMetadata game;
  final String localizedTitle;
  final VoidCallback onTap;

  const NeonGameCard({
    required this.game,
    required this.localizedTitle,
    required this.onTap,
    super.key,
  });

  @override
  State<NeonGameCard> createState() => _NeonGameCardState();
}

class _NeonGameCardState extends State<NeonGameCard> {
  bool _pressed = false;

  static Color _accent(String id, AppColors colors) => switch (id) {
    GameIds.tugOfWar => colors.neonPurple,
    GameIds.sumoBumper => const Color(0xFFFF6B35),
    GameIds.reactionTap => const Color(0xFFFFD700),
    GameIds.minesweeper => const Color(0xFFE53935),
    GameIds.drawGuess => colors.neonPink,
    GameIds.truthOrDare => colors.neonPurple,
    GameIds.spinPicker => const Color(0xFFFFD700),
    GameIds.neverHaveIEver => const Color(0xFFFF6584),
    GameIds.hotPotato => const Color(0xFFFF6B35),
    _ => colors.neonPurple,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final accent = _accent(widget.game.id, colors);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1A1A2E),
            border: Border.all(
              color: accent.withValues(alpha: _pressed ? 0.95 : 0.38),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: _pressed ? 0.55 : 0.18),
                blurRadius: _pressed ? 22 : 10,
                spreadRadius: _pressed ? 2 : 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'game_icon_${widget.game.id}',
                  child: MiniGameRegistry.iconFor(
                    widget.game.id,
                  ).svg(width: 52, height: 52),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    widget.localizedTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                // Neon accent underline
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _pressed ? 32 : 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PulseButton ────────────────────────────────────────────────────────────
/// Wraps a button widget with a breathing neon glow pulse animation.
class PulseButton extends StatefulWidget {
  final Widget child;
  final Color? glowColor;

  const PulseButton({required this.child, this.glowColor, super.key});

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.18 + _pulse.value * 0.38),
              blurRadius: 8 + _pulse.value * 18,
              spreadRadius: _pulse.value * 2.5,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ── FireworksOverlay ───────────────────────────────────────────────────────
/// Neon confetti burst — shown on top of the winner's scoreboard.
class FireworksOverlay extends StatefulWidget {
  final Widget child;

  const FireworksOverlay({required this.child, super.key});

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;

  static const _palette = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFFFFD700),
    Color(0xFF00D9FF),
    Color(0xFF4CAF50),
    Color(0xFFFF6B35),
    Color(0xFFE040FB),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(70, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 0.18 + rng.nextDouble() * 0.38;
      return _Particle(
        sx: 0.25 + rng.nextDouble() * 0.5,
        sy: 0.05 + rng.nextDouble() * 0.35,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed * 0.55,
        color: _palette[rng.nextInt(_palette.length)],
        r: 2.5 + rng.nextDouble() * 4.5,
        // stagger start so not all burst at once
        delay: rng.nextDouble() * 0.4,
      );
    });

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => CustomPaint(
                painter: _FireworksPainter(_ctrl.value, _particles),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final double sx, sy, vx, vy, r, delay;
  final Color color;
  const _Particle({
    required this.sx,
    required this.sy,
    required this.vx,
    required this.vy,
    required this.r,
    required this.color,
    required this.delay,
  });
}

class _FireworksPainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;

  const _FireworksPainter(this.t, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Adjust local time per particle (staggered start)
      final lt = ((t - p.delay).clamp(0.0, 1.0));
      if (lt <= 0) continue;

      final x = p.sx * size.width + p.vx * lt * size.width;
      final y =
          p.sy * size.height +
          p.vy * lt * size.height +
          0.28 * lt * lt * size.height; // gravity
      final alpha = (1 - lt * 1.1).clamp(0.0, 1.0);
      final radius = p.r * (1 - lt * 0.4);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t;
}

// ── RadarWidget ────────────────────────────────────────────────────────────
/// Animated radar sweep — used during room discovery.
class RadarWidget extends StatefulWidget {
  final Color color;
  final double size;

  const RadarWidget({
    this.color = const Color(0xFF6C63FF),
    this.size = 200,
    super.key,
  });

  @override
  State<RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<RadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            CustomPaint(painter: _RadarPainter(_ctrl.value, widget.color)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double t;
  final Color color;

  const _RadarPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxR = cx * 0.9;

    // 3 expanding rings, staggered 120°
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = phase * maxR;
      final alpha = (1.0 - phase).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Static crosshair grid lines
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), gridPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), gridPaint);

    // Rotating sweep sector
    final sweepAngle = t * 2 * pi;
    const sectorSpan = pi / 6; // 30° sweep tail
    final rect = Rect.fromCircle(center: center, radius: maxR);
    canvas.drawArc(
      rect,
      sweepAngle - sectorSpan,
      sectorSpan,
      true,
      Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: sweepAngle - sectorSpan,
          endAngle: sweepAngle,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.45)],
        ).createShader(rect)
        ..style = PaintingStyle.fill,
    );

    // Center dot
    canvas.drawCircle(center, 5, Paint()..color = color);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}

// ── ScoreboardOverlay ──────────────────────────────────────────────────────
/// Animated overlay that slides in from the bottom over the Flame canvas.
/// Shows victory/defeat with a blurred glassmorphism backdrop.
class ScoreboardOverlay extends StatefulWidget {
  final Widget child;
  const ScoreboardOverlay({required this.child, super.key});

  @override
  State<ScoreboardOverlay> createState() => _ScoreboardOverlayState();
}

class _ScoreboardOverlayState extends State<ScoreboardOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
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
      builder: (context, child) {
        return Stack(
          children: [
            // Blurred backdrop over the game canvas
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),
            ),
            // Scoreboard slides up from bottom
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(_slide),
              child: FadeTransition(opacity: _fade, child: child),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

// ── NeonTitle ──────────────────────────────────────────────────────────────
/// Title text with a neon glow shadow effect.
class NeonTitle extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;

  const NeonTitle(this.text, {this.color, this.fontSize = 28, super.key});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: c, blurRadius: 18),
          Shadow(color: c.withValues(alpha: 0.6), blurRadius: 36),
        ],
      ),
      textAlign: TextAlign.center,
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

@Preview(name: 'Neon - GlassCard', wrapper: themeWrapper)
Widget previewGlassCard() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: GlassCard(
    padding: EdgeInsets.all(24),
    child: Text(
      'Glassmorphism Card',
      style: TextStyle(color: Colors.white, fontSize: 18),
    ),
  ),
);

@Preview(name: 'Neon - GameCard', wrapper: themeWrapper)
Widget previewNeonGameCard() => Padding(
  padding: const EdgeInsets.all(16.0),
  child: SizedBox(
    width: 140,
    height: 180,
    child: NeonGameCard(
      game: const MiniGameMetadata(
        id: GameIds.tugOfWar,
        title: 'Tug of War',
        description: 'Pull the rope!',
        iconPath: 'assets/icons/ic_tug_of_war.svg',
        minPlayers: 2,
        maxPlayers: 8,
      ),
      localizedTitle: 'Kéo Co',
      onTap: () {},
    ),
  ),
);

@Preview(name: 'Neon - PulseButton', wrapper: themeWrapper)
Widget previewPulseButton() => Padding(
  padding: const EdgeInsets.all(16.0),
  child: PulseButton(
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: const Text(
        'Pulsing Button',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
);

@Preview(name: 'Neon - RadarWidget', wrapper: themeWrapper)
Widget previewRadarWidget() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: RadarWidget(color: Color(0xFF00D9FF)),
);

@Preview(name: 'Neon - Title', wrapper: themeWrapper)
Widget previewNeonTitle() => const Padding(
  padding: EdgeInsets.all(16.0),
  child: NeonTitle('NEON TITLE', color: Color(0xFFFF6584)),
);
