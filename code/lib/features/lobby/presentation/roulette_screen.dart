import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../game/domain/mini_game_registry.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';

/// Màn hình vòng quay chọn game ngẫu nhiên.
/// Pop với gameId được chọn khi user nhấn Play.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _angle;

  final _games = MiniGameRegistry.availableGames;
  int _selectedIndex = 0;
  bool _spinning = false;
  bool _done = false;

  static const _segmentColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF00D9FF),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF6B35),
    Color(0xFFE040FB),
    Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning) return;
    _spinning = true;
    _done = false;

    final rng = Random();
    _selectedIndex = rng.nextInt(_games.length);

    final segAngle = (2 * pi) / _games.length;
    final fullSpins = 4 + rng.nextInt(3);
    final targetAngle =
        fullSpins * 2 * pi +
        (2 * pi - (_selectedIndex * segAngle + segAngle / 2));

    _angle = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.decelerate));

    _ctrl.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _spinning = false;
          _done = true;
        });
        HapticFeedback.heavyImpact();
        AppAudio.playCountdownGo();
      }
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final selected = _done ? _games[_selectedIndex] : null;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
          boxShadow: AppTheme.glowShadow(primary, blur: 20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎰 Roulette Cup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primary, blurRadius: 12)],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinning
                        ? _ctrl
                        : const AlwaysStoppedAnimation(0),
                    builder: (ctx, child) => Transform.rotate(
                      angle: _spinning ? _angle.value : 0,
                      child: CustomPaint(
                        size: const Size(260, 260),
                        painter: _WheelPainter(
                          games: _games.map((g) => g.title).toList(),
                          colors: _segmentColors,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.bgSurface,
                      border: Border.all(color: primary, width: 2),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: const Size(20, 24),
                      painter: _PointerPainter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selected != null
                  ? Column(
                      key: ValueKey(selected.id),
                      children: [
                        Text(
                          selected.title,
                          style: TextStyle(
                            color: _segmentColors[
                                _selectedIndex % _segmentColors.length],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selected.description,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : const SizedBox(height: 40, key: ValueKey('empty')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _spinning ? null : _spin,
                    icon: const Icon(Icons.casino),
                    label: Text(_spinning ? l10n.spinningText : l10n.spinBtn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_done) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.pop(_games[_selectedIndex].id),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.playBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> games;
  final List<Color> colors;

  const _WheelPainter({required this.games, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final n = games.length;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) - 2;
    final segAngle = (2 * pi) / n;

    for (int i = 0; i < n; i++) {
      final start = -pi / 2 + i * segAngle;
      final color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        segAngle,
        true,
        Paint()..color = color.withValues(alpha: 0.85),
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        segAngle,
        true,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(start + segAngle / 2);
      final label = games[i].length > 8
          ? '${games[i].substring(0, 7)}…'
          : games[i];
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 0.7);
      tp.paint(canvas, Offset(r * 0.38 - tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
