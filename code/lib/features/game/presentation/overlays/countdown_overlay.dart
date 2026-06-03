import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/features/game/domain/mini_game_hints.dart';

/// Overlay đếm ngược với 2 pha:
///   1. Hint (1.5s) — emoji + câu lệnh đặc trưng cho mini-game.
///   2. Countdown 3-2-1-GO! — P2P sync qua [onBroadcastTick] / [externalTickNotifier].
///
/// Host cung cấp [onBroadcastTick] để broadcast tick đến clients.
/// Client cung cấp [externalTickNotifier] được cập nhật từ [LobbyProvider.onCountdownTick].
class CountdownOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final MiniGameHint? hint;
  final bool isHost;

  /// Host gọi callback này mỗi khi chuyển step (3,2,1,0=GO).
  final void Function(int step)? onBroadcastTick;

  /// Client: ValueNotifier được cập nhật từ LobbyProvider.onCountdownTick.
  /// Khi không null và không phải host, overlay theo tick này thay vì bộ đếm nội.
  final ValueNotifier<int>? externalTickNotifier;

  const CountdownOverlay({
    super.key,
    required this.onComplete,
    this.hint,
    this.isHost = true,
    this.onBroadcastTick,
    this.externalTickNotifier,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _steps = ['3', '2', '1', 'GO!'];

  // Phase 1: hint
  bool _showingHint = true;
  double _hintOpacity = 0.0;

  // Phase 2: countdown
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

    // Wire client external tick notifier.
    if (!widget.isHost && widget.externalTickNotifier != null) {
      widget.externalTickNotifier!.addListener(_onExternalTick);
    }

    if (widget.hint != null) {
      _startHint();
    } else {
      _showingHint = false;
      _startCountdown();
    }
  }

  // ── Phase 1: Hint ──────────────────────────────────────────────────────────

  void _startHint() {
    // Fade-in hint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hintOpacity = 1.0);
    });
    _stepTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _hintOpacity = 0.0);
      // Wait for fade-out then start countdown
      _stepTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _showingHint = false);
        _startCountdown();
      });
    });
  }

  // ── Phase 2: Countdown ──────────────────────────────────────────────────────

  void _startCountdown() {
    if (widget.isHost) {
      _driveStep(_index);
    }
    // Client: waits for externalTickNotifier to fire.
    // If no network (solo test), fall back to local timer.
    if (!widget.isHost && widget.externalTickNotifier == null) {
      _driveStep(_index);
    }
  }

  void _driveStep(int stepIndex) {
    if (!mounted) return;
    setState(() => _index = stepIndex);
    _controller.forward(from: 0);
    final isGo = stepIndex == _steps.length - 1;
    isGo ? AppAudio.playCountdownGo() : AppAudio.playCountdownBeep();

    widget.onBroadcastTick?.call(stepIndex);

    _stepTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (stepIndex < _steps.length - 1) {
        _driveStep(stepIndex + 1);
      } else {
        widget.onComplete();
      }
    });
  }

  void _onExternalTick() {
    final tick = widget.externalTickNotifier!.value;
    if (!mounted || _showingHint) return;
    setState(() => _index = tick);
    _controller.forward(from: 0);
    final isGo = tick == _steps.length - 1;
    isGo ? AppAudio.playCountdownGo() : AppAudio.playCountdownBeep();
    if (isGo) {
      // Slight delay so GO! is visible before onComplete
      _stepTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) widget.onComplete();
      });
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    widget.externalTickNotifier?.removeListener(_onExternalTick);
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(child: _showingHint ? _buildHint() : _buildCountdown()),
    );
  }

  Widget _buildHint() {
    final hint = widget.hint!;
    return AnimatedOpacity(
      opacity: _hintOpacity,
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hint.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          Text(
            hint.instruction,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 16)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    final isGo = _index == _steps.length - 1;
    return AnimatedBuilder(
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
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

void _noOp() {}

@Preview(name: 'Countdown – hint phase (Kéo Co)')
Widget previewCountdownHint() => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: CountdownOverlay(
      onComplete: _noOp,
      hint: const MiniGameHint(emoji: '👆', instruction: 'TAP NHANH!'),
      isHost: true,
    ),
  ),
);

@Preview(name: 'Countdown – animated (no hint)')
Widget previewCountdownOverlay() => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: SizedBox(
      width: 375,
      height: 667,
      child: CountdownOverlay(onComplete: _noOp, isHost: true),
    ),
  ),
);
