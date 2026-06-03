import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../domain/player.dart';
import 'lobby_provider.dart';
import '../../game/domain/mini_game_metadata.dart';
import '../../game/domain/mini_game_registry.dart';

/// Màn hình phòng chờ — danh sách người chơi và nút bắt đầu (chỉ Host).
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        if (lobby.state == LobbyState.inGame && lobby.pendingGameId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/game');
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.roomTitle),
            leading: BackButton(onPressed: () => context.go('/')),
          ),
          body: Column(
            children: [
              Expanded(child: _PlayerList(players: lobby.players)),
              if (lobby.isHost) _GameSelector(lobby: lobby),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerList extends StatelessWidget {
  final List<Player> players;

  const _PlayerList({required this.players});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        return ListTile(
          leading: CircleAvatar(child: Text(p.name[0].toUpperCase())),
          title: Text(p.name),
          trailing: p.isHost
              ? Chip(
                  label: Text(l10n.host),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }
}

class _GameSelector extends StatelessWidget {
  final LobbyProvider lobby;

  const _GameSelector({required this.lobby});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectMiniGame,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...MiniGameRegistry.availableGames.map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GameCard(game: game, lobby: lobby),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final MiniGameMetadata game;
  final LobbyProvider lobby;

  const _GameCard({required this.game, required this.lobby});

  String _getGameTitle(BuildContext context, String gameId) {
    final l10n = AppLocalizations.of(context)!;
    switch (gameId) {
      case 'tug_of_war':
        return l10n.gameTugOfWarTitle;
      case 'sumo_bumper':
        return l10n.gameSumoBumperTitle;
      case 'penalty_shootout':
        return l10n.gamePenaltyShootoutTitle;
      case 'air_hockey':
        return l10n.gameAirHockeyTitle;
      default:
        return game.title;
    }
  }

  String _getGameDescription(BuildContext context, String gameId) {
    final l10n = AppLocalizations.of(context)!;
    switch (gameId) {
      case 'tug_of_war':
        return l10n.gameTugOfWarDesc;
      case 'sumo_bumper':
        return l10n.gameSumoBumperDesc;
      case 'penalty_shootout':
        return l10n.gamePenaltyShootoutDesc;
      case 'air_hockey':
        return l10n.gameAirHockeyDesc;
      default:
        return game.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: MiniGameRegistry.iconFor(game.id).svg(width: 40, height: 40),
        title: Text(_getGameTitle(context, game.id)),
        subtitle: Text(_getGameDescription(context, game.id)),
        trailing: ElevatedButton(
          onPressed: () => lobby.startGame(game.id),
          child: Text(l10n.startBtn),
        ),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget roomPreviewWrapper(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

@Preview(name: 'Player List – 3 người chơi', wrapper: roomPreviewWrapper)
Widget previewPlayerList() => Scaffold(
  appBar: AppBar(title: const Text('Phòng chờ')),
  body: _PlayerList(
    players: const [
      Player(id: '1', name: 'Alice', isHost: true),
      Player(id: '2', name: 'Bob'),
      Player(id: '3', name: 'Charlie'),
    ],
  ),
);

@Preview(name: 'Game Card – Kéo Co', wrapper: roomPreviewWrapper)
Widget previewGameCard() => Scaffold(
  body: Padding(
    padding: const EdgeInsets.all(16),
    child: _GameCard(
      game: MiniGameRegistry.availableGames.first,
      lobby: LobbyProvider(),
    ),
  ),
);
