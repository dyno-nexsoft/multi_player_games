import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';

/// Màn hình xác nhận thoát game — push với opaque: false.
class ExitGameScreen extends StatelessWidget {
  const ExitGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: Text(l10n.endGameTitle),
        content: Text(l10n.endGameDesc),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.cancelBtn),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(
              l10n.endGameBtn,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
