import 'package:flutter/material.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:nsd/nsd.dart';
import 'package:provider/provider.dart';
import 'lobby_provider.dart';

/// Màn hình quét và hiển thị danh sách phòng Host đang quảng bá.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.discoverTitle),
            leading: BackButton(onPressed: () => context.go('/')),
          ),
          body: lobby.discoveredRooms.isEmpty
              ? const _EmptyState()
              : _RoomList(rooms: lobby.discoveredRooms, lobby: lobby),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.searchingRooms),
        ],
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  final List<Service> rooms;
  final LobbyProvider lobby;

  const _RoomList({required this.rooms, required this.lobby});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (_, i) {
        final room = rooms[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(room.name ?? l10n.unknownRoom),
            trailing: ElevatedButton(
              onPressed: () async {
                await lobby.joinRoom(room);
                if (context.mounted) context.go('/room');
              },
              child: Text(l10n.joinBtn),
            ),
          ),
        );
      },
    );
  }
}
