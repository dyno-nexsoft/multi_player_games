import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/features/game/domain/mini_game_hints.dart';
import '../../lobby/presentation/lobby_provider.dart';
import 'game_provider.dart';

/// Màn hình đếm ngược — push trên GameHubScreen với opaque: false.
/// Đọc callback và notifier từ Provider thay vì constructor params.
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  static const _steps = ['3', '2', '1', 'GO!'];

  bool _showingHint = true;
  double _hintOpacity = 0.0;

  int _index = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  Timer? _stepTimer;

  late bool _isHost;
  late bool _isConsoleMode;
  late MiniGameHint? _hint;
  late LobbyProvider _lobby;

  @override
  void initState() {
    super.initState();
    _lobby = context.read<LobbyProvider>();
    final gp = context.read<GameProvider>();
    _isHost = _lobby.isHost;
    _isConsoleMode = _lobby.isConsoleMode;
    _hint = MiniGameHints.forGame(gp.lastGameId ?? '');

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

    if (!_isHost) {
      _lobby.countdownTickNotifier.addListener(_onExternalTick);
    }

    if (_hint != null) {
      _startHint();
    } else {
      _showingHint = false;
      _startCountdown();
    }
  }

  void _startHint() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _hintOpacity = 1.0);
    });
    _stepTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _hintOpacity = 0.0);
      _stepTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _showingHint = false);
        _startCountdown();
      });
    });
  }

  void _startCountdown() {
    if (_isHost) {
      _driveStep(_index);
    }
    // Client waits for countdownTickNotifier ticks via listener added in initState.
  }

  void _driveStep(int stepIndex) {
    if (!mounted) return;
    setState(() => _index = stepIndex);
    _controller.forward(from: 0);
    final isGo = stepIndex == _steps.length - 1;
    isGo ? AppAudio.playCountdownGo() : AppAudio.playCountdownBeep();

    _lobby.broadcastCountdown(stepIndex);

    _stepTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (stepIndex < _steps.length - 1) {
        _driveStep(stepIndex + 1);
      } else {
        _onComplete();
      }
    });
  }

  void _onExternalTick() {
    final tick = _lobby.countdownTickNotifier.value;
    if (!mounted || _showingHint) return;
    setState(() => _index = tick);
    _controller.forward(from: 0);
    final isGo = tick == _steps.length - 1;
    isGo ? AppAudio.playCountdownGo() : AppAudio.playCountdownBeep();
    if (isGo) {
      _stepTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) _onComplete();
      });
    }
  }

  void _onComplete() {
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    _lobby.countdownTickNotifier.removeListener(_onExternalTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(child: _showingHint ? _buildHint() : _buildCountdown()),
    );
  }

  Widget _buildHint() {
    final hint = _hint!;
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
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          if (_isConsoleMode) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gamepad_rounded, color: Colors.cyanAccent, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Sử dụng tay cầm trên điện thoại',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                Shadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
