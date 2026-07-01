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

  void showEmote(String senderId, String emoji) {
    if (!mounted) return;
    final lobby = context.read<LobbyProvider>();
    final index = lobby.players.indexWhere((p) => p.id == senderId);
    final isHost = lobby.isHost && lobby.localPlayer?.id == senderId;
    final finalIndex = index >= 0 ? index : (isHost ? 0 : 0);
    setState(() {
      _active.add(
        _EmoteParticle(
          id: _nextId++,
          emoji: emoji,
          playerIndex: finalIndex,
          totalPlayers: max(1, lobby.players.length),
        ),
      );
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
  final void Function(String senderId, String emoji) onSelected;
  const _EmotePickerButton({required this.onSelected});

  @override
  State<_EmotePickerButton> createState() => _EmotePickerButtonState();
}

class _EmotePickerButtonState extends State<_EmotePickerButton> {
  bool _open = false;

  void _send(BuildContext context, String emoji) {
    setState(() => _open = false);
    final lobby = context.read<LobbyProvider>();
    widget.onSelected(lobby.localPlayer?.id ?? '', emoji);
    HapticFeedback.lightImpact();

    // Broadcast emote packet via LobbyProvider
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
  final double startY;

  _EmoteParticle({
    required this.id,
    required this.emoji,
    required int playerIndex,
    required int totalPlayers,
  }) : // Tính toán vị trí xuất phát dựa trên index người chơi
       startX = _calcStartX(playerIndex, totalPlayers),
       startY = _calcStartY(playerIndex, totalPlayers);

  static double _calcStartX(int i, int total) {
    // 4 góc hoặc chia đều theo viền
    if (total <= 4) {
      if (i == 0 || i == 2) return 0.1; // Trái
      return 0.9; // Phải
    } else {
      return (i % 2 == 0) ? 0.1 : 0.9;
    }
  }

  static double _calcStartY(int i, int total) {
    if (total <= 4) {
      if (i == 0 || i == 1) return 0.15; // Trên
      return 0.85; // Dưới
    } else {
      // Dải đều từ trên xuống dưới
      final step = 0.8 / (total / 2).ceil();
      return 0.1 + (i ~/ 2) * step;
    }
  }
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
        // Tọa độ bay: Từ điểm xuất phát (startX, startY) bay dạt về giữa màn hình (0.5, 0.5)
        final dx =
            widget.particle.startX +
            (0.5 - widget.particle.startX) * _pos.value;
        final dy =
            widget.particle.startY +
            (0.4 - widget.particle.startY) * _pos.value;

        return Positioned(
          left: dx * MediaQuery.of(context).size.width - 24,
          top: dy * MediaQuery.of(context).size.height,
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
