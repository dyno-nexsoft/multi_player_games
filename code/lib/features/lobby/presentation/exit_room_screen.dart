import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'lobby_provider.dart';

/// Màn hình xác nhận rời phòng — push với opaque: false.
class ExitRoomScreen extends StatelessWidget {
  const ExitRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lobby = context.read<LobbyProvider>();
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: Text(
          lobby.isHost ? l10n.exitRoomTitleHost : l10n.exitRoomTitleClient,
        ),
        content: Text(
          lobby.isHost ? l10n.exitRoomDescHost : l10n.exitRoomDescClient,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.cancelBtn),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              l10n.confirmBtn,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
