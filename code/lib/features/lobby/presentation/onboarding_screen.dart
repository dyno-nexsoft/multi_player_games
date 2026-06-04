import 'dart:math';

import 'package:flutter/material.dart';
import 'package:party_game_hub/core/storage/onboarding_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';

import '../../../router.dart';

/// Màn hình giới thiệu lần đầu — 3 slide vuốt ngang.
///
/// Hiển thị một lần duy nhất khi mở app lần đầu (kiểm tra SharedPreferences).
/// Có thể mở lại dưới dạng Dialog qua [showAsDialog].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<void> showAsDialog(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Onboarding',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(
            begin: 0.92,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, _) => const _OnboardingDialog(),
    );
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _done();
    }
  }

  Future<void> _done() async {
    await OnboardingService.markSeen();
    if (mounted) const LobbyRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [_Slide1(), _Slide2(), _Slide3()],
              ),
            ),
            _BottomBar(page: _page, onNext: _next, onSkip: _done),
          ],
        ),
      ),
    );
  }
}

// ── Dialog wrapper (khi mở lại từ [?]) ────────────────────────────────────────

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: AppTheme.bgDeep,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: const [_Slide1(), _Slide2(), _Slide3()],
                  ),
                ),
                _BottomBar(
                  page: _page,
                  onNext: () {
                    if (_page < 2) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  onSkip: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int page;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _BottomBar({
    required this.page,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = page == 2;
    final primary = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          // Dot indicators
          Row(
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page ? primary : primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          if (!isLast)
            TextButton(
              onPressed: onSkip,
              child: Text(
                l10n.skipBtn,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          const SizedBox(width: 8),
          PulseButton(
            glowColor: primary,
            child: ElevatedButton(
              onPressed: onNext,
              child: Text(isLast ? l10n.letsGo : l10n.nextBtn),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide 1: Giới thiệu ───────────────────────────────────────────────────────

class _Slide1 extends StatelessWidget {
  const _Slide1();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GamepadIcon(),
          const SizedBox(height: 32),
          NeonTitle(l10n.appName, fontSize: 28, color: primary),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingDesc1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(l10n.onboardingFeature1),
              _FeatureChip(l10n.onboardingFeature2),
              _FeatureChip(l10n.onboardingFeature3),
              _FeatureChip(l10n.onboardingFeature4),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}

// ── Slide 2: WiFi ─────────────────────────────────────────────────────────────

class _Slide2 extends StatelessWidget {
  const _Slide2();

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _WiFiWaveAnimation(color: secondary),
          const SizedBox(height: 32),
          NeonTitle(l10n.onboardingTitle2, fontSize: 22, color: secondary),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: secondary.withValues(alpha: 0.3)),
            ),
            child: Text(
              l10n.onboardingDesc2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingSub2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animation sóng WiFi vẽ bằng CustomPaint — thay thế Lottie.
class _WiFiWaveAnimation extends StatefulWidget {
  final Color color;
  const _WiFiWaveAnimation({required this.color});

  @override
  State<_WiFiWaveAnimation> createState() => _WiFiWaveAnimationState();
}

class _WiFiWaveAnimationState extends State<_WiFiWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
      builder: (_, _) => CustomPaint(
        size: const Size(140, 100),
        painter: _WiFiPainter(progress: _ctrl.value, color: widget.color),
      ),
    );
  }
}

class _WiFiPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _WiFiPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.7;

    // 3 concentric arcs representing WiFi signal strength
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.25;
      final p = ((progress - delay) % 1.0 + 1.0) % 1.0;
      final opacity = (sin(p * pi)).clamp(0.0, 1.0);
      final radius = 20.0 + i * 24;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        pi + pi / 5,
        pi - pi / 2.5,
        false,
        paint,
      );
    }

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WiFiPainter old) => old.progress != progress;
}

// ── Slide 3: CTA ──────────────────────────────────────────────────────────────

class _Slide3 extends StatefulWidget {
  const _Slide3();

  @override
  State<_Slide3> createState() => _Slide3State();
}

class _Slide3State extends State<_Slide3> with SingleTickerProviderStateMixin {
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
    final primary = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Transform.scale(
              scale: 1.0 + _ctrl.value * 0.06,
              child: const Text(
                '🎉',
                style: TextStyle(fontSize: 80),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          NeonTitle(l10n.onboardingTitle3, fontSize: 28, color: primary),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingDesc3,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared icons ──────────────────────────────────────────────────────────────

class _GamepadIcon extends StatefulWidget {
  const _GamepadIcon();

  @override
  State<_GamepadIcon> createState() => _GamepadIconState();
}

class _GamepadIconState extends State<_GamepadIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.2 + _ctrl.value * 0.25),
              blurRadius: 24 + _ctrl.value * 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
