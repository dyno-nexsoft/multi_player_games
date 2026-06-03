import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';

/// Overlay đếm ngược 3-2-1-GO! hiển thị trước khi game bắt đầu.
/// Dùng chung cho mọi mini-game qua GameWidget overlayBuilderMap.
///
/// Cách dùng trong BaseMiniGame.onLoad():
///   overlays.add(CountdownOverlay.overlayKey);
class CountdownOverlay extends StatefulWidget {
  static const String overlayKey = 'countdown';

  final VoidCallback onComplete;

  const CountdownOverlay({super.key, required this.onComplete});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _steps = ['3', '2', '1', 'GO!'];
  int _index = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = Tween<double>(
      begin: 1.6,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)),
    );

    _startStep();
  }

  void _startStep() {
    _controller.forward(from: 0);
    final isGo = _index == _steps.length - 1;
    if (isGo) {
      AppAudio.playCountdownGo();
    } else {
      AppAudio.playCountdownBeep();
    }
    _stepTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_index < _steps.length - 1) {
        setState(() => _index++);
        _startStep();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGo = _index == _steps.length - 1;
    return Container(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) => FadeTransition(
            opacity: _fadeAnim,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Text(
                _steps[_index],
                style: TextStyle(
                  fontSize: isGo ? 72 : 96,
                  fontWeight: FontWeight.w900,
                  color: isGo ? const Color(0xFF6C63FF) : Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

void _countdownNoOp() {}

@Preview(name: 'Countdown Overlay – animated')
Widget previewCountdownOverlay() => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: SizedBox(
      width: 375,
      height: 667,
      child: CountdownOverlay(onComplete: _countdownNoOp),
    ),
  ),
);
