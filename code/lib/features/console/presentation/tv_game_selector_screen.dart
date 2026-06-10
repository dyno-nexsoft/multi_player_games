import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../game/domain/mini_game_metadata.dart';
import '../../game/domain/mini_game_registry.dart';
import '../../lobby/presentation/lobby_provider.dart';

/// Màn hình chọn Mini-Game cho TV (10-foot UI).
/// Đọc số người chơi từ LobbyProvider, lọc game phù hợp.
/// Pop với gameId (String) khi chọn, hoặc pop(null) khi hủy.
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
      backgroundColor: AppTheme.bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54, size: 28),
          onPressed: () => context.pop(null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn Mini-Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$playerCount người chơi',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
        child: games.isEmpty
            ? const Center(
                child: Text(
                  'Không có game phù hợp với số lượng người chơi này.',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.8,
                ),
                itemCount: games.length,
                itemBuilder: (context, i) => _TvGameChip(
                  game: games[i],
                  onTap: () => context.pop(games[i].id),
                ),
              ),
      ),
    );
  }
}

class _TvGameChip extends StatefulWidget {
  final MiniGameMetadata game;
  final VoidCallback onTap;

  const _TvGameChip({required this.game, required this.onTap});

  @override
  State<_TvGameChip> createState() => _TvGameChipState();
}

class _TvGameChipState extends State<_TvGameChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.neonPurple.withValues(
              alpha: _focused ? 0.22 : 0.08,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neonPurple.withValues(
                alpha: _focused ? 1.0 : 0.25,
              ),
              width: _focused ? 2.5 : 1.5,
            ),
            boxShadow: _focused
                ? AppTheme.glowShadow(AppTheme.neonPurple, blur: 16, spread: 2)
                : null,
          ),
          child: Text(
            widget.game.title,
            style: TextStyle(
              color: _focused ? Colors.white : Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
