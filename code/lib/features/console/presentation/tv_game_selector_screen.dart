import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../game/domain/mini_game_metadata.dart';
import '../../game/domain/mini_game_registry.dart';
import '../../lobby/presentation/lobby_provider.dart';

/// Màn hình chọn Mini-Game cho TV (10-foot UI).
/// Hỗ trợ D-Pad: ▲▼ di chuyển, OK/Enter chọn, Back/Esc hủy.
class TvGameSelectorScreen extends StatelessWidget {
  const TvGameSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerCount = context.read<LobbyProvider>().players.length;
    final games = MiniGameRegistry.availableGames
        .where(
          (g) => playerCount >= g.minPlayers && playerCount <= g.maxPlayers,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        minimum: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              children: [
                _TvBackButton(onPressed: () => context.pop(null)),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn Mini-Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$playerCount người chơi  •  ${games.length} game khả dụng',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const _DPadHint(),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 16),

            // ── Game List ─────────────────────────────────────────────────────
            Expanded(
              child: games.isEmpty
                  ? const _EmptyState()
                  : FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: ListView.separated(
                        itemCount: games.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => FocusTraversalOrder(
                          order: NumericFocusOrder(i.toDouble()),
                          child: _TvGameCard(
                            game: games[i],
                            autofocus: i == 0,
                            onSelect: () => context.pop(games[i].id),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TV Game Card (10-foot UI) ──────────────────────────────────────────────────

class _TvGameCard extends StatefulWidget {
  final MiniGameMetadata game;
  final bool autofocus;
  final VoidCallback onSelect;

  const _TvGameCard({
    required this.game,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_TvGameCard> createState() => _TvGameCardState();
}

class _TvGameCardState extends State<_TvGameCard> {
  bool _focused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
      widget.onSelect();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.neonPurple;
    final accentColor = _focused ? color : color.withValues(alpha: 0.5);

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _focused ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: _focused
                  ? color.withValues(alpha: 0.18)
                  : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: _focused ? 2.5 : 1.5),
              boxShadow: _focused
                  ? AppTheme.glowShadow(color, blur: 24, spread: 2)
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Game icon
                SizedBox(
                  width: 48,
                  height: 48,
                  child: MiniGameRegistry.iconFor(widget.game.id).svg(
                    width: 48,
                    height: 48,
                    colorFilter: ColorFilter.mode(
                      _focused ? Colors.white : Colors.white54,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.game.title,
                        style: TextStyle(
                          color: _focused ? Colors.white : Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.game.description,
                        style: TextStyle(
                          color: _focused
                              ? Colors.white54
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Player count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${widget.game.minPlayers}–${widget.game.maxPlayers} 👤',
                    style: TextStyle(
                      color: _focused ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // OK badge khi đang focus
                if (_focused) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.8)),
                    ),
                    child: const Text(
                      'OK ↵',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── TV Back Button ─────────────────────────────────────────────────────────────

class _TvBackButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _TvBackButton({required this.onPressed});

  @override
  State<_TvBackButton> createState() => _TvBackButtonState();
}

class _TvBackButtonState extends State<_TvBackButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _focused
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: _focused ? Colors.white70 : Colors.white24,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Icon(
            Icons.arrow_back,
            color: _focused ? Colors.white : Colors.white54,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ── D-Pad Hint ─────────────────────────────────────────────────────────────────

class _DPadHint extends StatelessWidget {
  const _DPadHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('▲▼', style: TextStyle(color: Colors.white38, fontSize: 14)),
          SizedBox(width: 6),
          Text(
            'Di chuyển',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          SizedBox(width: 16),
          Text('OK', style: TextStyle(color: Colors.white38, fontSize: 14)),
          SizedBox(width: 6),
          Text(
            'Chọn',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videogame_asset_off, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text(
            'Không có game phù hợp',
            style: TextStyle(color: Colors.white38, fontSize: 22),
          ),
          SizedBox(height: 8),
          Text(
            'Thêm người chơi để mở khóa nhiều game hơn.',
            style: TextStyle(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
