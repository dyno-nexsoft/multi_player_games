import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/game_packet.dart';
import '../../lobby/presentation/lobby_provider.dart';

// ── Available emotes ───────────────────────────────────────────────────────

const _emotes = ['🐔', '😎', '🤣', '💪', '😢', '🔥'];

// ── Emote Layer ────────────────────────────────────────────────────────────
/// Full-screen Stack wrapper that renders flying emote animations over the game.
/// Add to any Stack by wrapping [child] with this widget.
class EmoteLayer extends StatefulWidget {
  final Widget child;
  const EmoteLayer({required this.child, super.key});

  @override
  State<EmoteLayer> createState() => EmoteLayerState();

  /// Access the state from ancestor widgets via context.
  static EmoteLayerState? of(BuildContext context) =>
      context.findAncestorStateOfType<EmoteLayerState>();
}

class EmoteLayerState extends State<EmoteLayer> {
  final List<_EmoteParticle> _active = [];
  int _nextId = 0;

  /// Fire an emote — call from game or lobby provider callback.
  void showEmote(String emoji) {
    if (!mounted) return;
    setState(() {
      _active.add(_EmoteParticle(id: _nextId++, emoji: emoji));
    });
  }

  void _removeParticle(int id) {
    if (mounted) setState(() => _active.removeWhere((p) => p.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Emote picker button (bottom-right edge, translucent)
        Positioned(
          bottom: 60,
          right: 8,
          child: _EmotePickerButton(onSelected: showEmote),
        ),
        // Flying emotes
        for (final p in _active)
          _FlyingEmote(
            key: ValueKey(p.id),
            particle: p,
            onDone: () => _removeParticle(p.id),
          ),
      ],
    );
  }
}

// ── Emote picker button ────────────────────────────────────────────────────

class _EmotePickerButton extends StatefulWidget {
  final ValueChanged<String> onSelected;
  const _EmotePickerButton({required this.onSelected});

  @override
  State<_EmotePickerButton> createState() => _EmotePickerButtonState();
}

class _EmotePickerButtonState extends State<_EmotePickerButton> {
  bool _open = false;

  void _send(BuildContext context, String emoji) {
    setState(() => _open = false);
    widget.onSelected(emoji);
    HapticFeedback.lightImpact();

    // Broadcast emote packet via LobbyProvider
    final lobby = context.read<LobbyProvider>();
    final packet = GamePacket(
      type: PacketType.emote,
      senderId: lobby.localPlayer?.id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'emoji': emoji},
    );
    lobby.sendGamePacket(packet);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Emote grid (shown when open)
        if (_open)
          AnimatedScale(
            scale: _open ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emotes
                    .map(
                      (e) => GestureDetector(
                        onTap: () => _send(context, e),
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        // Toggle button
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text('😄', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

// ── Flying emote animation ─────────────────────────────────────────────────

class _EmoteParticle {
  final int id;
  final String emoji;
  final double startX;

  _EmoteParticle({required this.id, required this.emoji})
    : startX = 0.3 + Random().nextDouble() * 0.4;
}

class _FlyingEmote extends StatefulWidget {
  final _EmoteParticle particle;
  final VoidCallback onDone;

  const _FlyingEmote({required this.particle, required this.onDone, super.key});

  @override
  State<_FlyingEmote> createState() => _FlyingEmoteState();
}

class _FlyingEmoteState extends State<_FlyingEmote>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos; // 0 = bottom, 1 = top
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pos = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.4), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
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
        final y = 0.85 - _pos.value * 0.75; // from 85% to 10% of screen height
        return Positioned(
          left: widget.particle.startX * MediaQuery.of(context).size.width - 24,
          top: y * MediaQuery.of(context).size.height,
          child: Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.particle.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        );
      },
    );
  }
}
