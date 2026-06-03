import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
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
              ? _RadarEmptyState(statusText: l10n.searchingRooms)
              : _RoomList(rooms: lobby.discoveredRooms, lobby: lobby),
        );
      },
    );
  }
}

// ── Radar empty state ──────────────────────────────────────────────────────

class _RadarEmptyState extends StatelessWidget {
  final String statusText;
  const _RadarEmptyState({required this.statusText});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RadarWidget(color: primary, size: 200),
          const SizedBox(height: 32),
          NeonTitle(statusText, fontSize: 15, color: primary),
          const SizedBox(height: 8),
          Text(
            'Đảm bảo 2 thiết bị cùng WiFi',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Room list ──────────────────────────────────────────────────────────────

class _RoomList extends StatefulWidget {
  final List<Service> rooms;
  final LobbyProvider lobby;

  const _RoomList({required this.rooms, required this.lobby});

  @override
  State<_RoomList> createState() => _RoomListState();
}

class _RoomListState extends State<_RoomList> {
  // Chặn double-tap: chỉ cho phép một lần kết nối cùng lúc
  bool _connecting = false;

  Future<void> _connectWithRadar(Service room) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    HapticFeedback.mediumImpact();

    // Track navigator key để pop dialog an toàn
    final navigator = Navigator.of(context);
    bool dialogOpen = true;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      pageBuilder: (dialogCtx, a1, a2) => const _ConnectingDialog(),
    ).then((_) => dialogOpen = false);

    try {
      await widget.lobby.joinRoom(room);
      if (!mounted) return;
      if (dialogOpen && navigator.canPop()) navigator.pop();
      context.go('/room');
    } catch (e) {
      if (!mounted) return;
      if (dialogOpen && navigator.canPop()) navigator.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kết nối thất bại: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.rooms.length,
      itemBuilder: (context, i) {
        final room = widget.rooms[i];
        return _RoomCard(
          name: room.name ?? l10n.unknownRoom,
          // Disable button khi đang connecting
          onJoin: _connecting ? null : () => _connectWithRadar(room),
        );
      },
    );
  }
}

// ── Connecting dialog ──────────────────────────────────────────────────────

class _ConnectingDialog extends StatelessWidget {
  const _ConnectingDialog();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadarWidget(color: primary, size: 160),
          const SizedBox(height: 20),
          NeonTitle('Đang kết nối...', fontSize: 16, color: primary),
          const SizedBox(height: 8),
          Text(
            'Thiết lập kết nối TCP',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatefulWidget {
  final String name;
  final VoidCallback? onJoin;
  const _RoomCard({required this.name, required this.onJoin});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FadeTransition(
      opacity: _slide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(_slide),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: AppTheme.glowShadow(primary, blur: 10),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.wifi, color: primary, size: 20),
              ),
              title: Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Tap để vào phòng',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: widget.onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Vào'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget discoverPreviewWrapper(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

@Preview(name: 'Discover – Radar (đang tìm)', wrapper: discoverPreviewWrapper)
Widget previewDiscoverSearching() => const Scaffold(
  body: _RadarEmptyState(statusText: 'Đang tìm kiếm phòng...'),
);

@Preview(name: 'Discover – tìm thấy phòng', wrapper: discoverPreviewWrapper)
Widget previewDiscoverRoomFound() => Scaffold(
  appBar: AppBar(title: const Text('Tìm phòng')),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _RoomCard(name: "Alice's Room", onJoin: () {}),
      _RoomCard(name: "Bob's Room", onJoin: () {}),
    ],
  ),
);
