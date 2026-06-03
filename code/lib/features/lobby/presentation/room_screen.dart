import 'package:flutter/material.dart';
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
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        if (lobby.state == LobbyState.inGame && lobby.pendingGameId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/game');
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phòng Chờ'),
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
                  label: const Text('Host'),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chọn Mini-Game',
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(game.title),
        subtitle: Text(game.description),
        trailing: ElevatedButton(
          onPressed: () => lobby.startGame(game.id),
          child: const Text('Bắt đầu'),
        ),
      ),
    );
  }
}
