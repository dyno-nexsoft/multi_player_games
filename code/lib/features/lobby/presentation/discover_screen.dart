import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nsd/nsd.dart';
import 'package:provider/provider.dart';
import 'lobby_provider.dart';

/// Màn hình quét và hiển thị danh sách phòng Host đang quảng bá.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tìm Phòng'),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tìm kiếm phòng...'),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (_, i) {
        final room = rooms[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: Text(room.name ?? 'Unknown Room'),
            trailing: ElevatedButton(
              onPressed: () async {
                await lobby.joinRoom(room);
                if (context.mounted) context.go('/room');
              },
              child: const Text('Tham gia'),
            ),
          ),
        );
      },
    );
  }
}
