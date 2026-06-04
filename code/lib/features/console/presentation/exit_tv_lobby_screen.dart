import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';

/// Màn hình xác nhận giải tán phòng TV — push với opaque: false.
/// Font size lớn hơn cho 10-foot UI per tv_ui_ux_spec.md §1.4.
class ExitTvLobbyScreen extends StatelessWidget {
  const ExitTvLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text(
          'Giải tán phòng?',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn giải tán phòng không?',
          style: TextStyle(color: Colors.white70, fontSize: 20),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => context.pop(false),
            child: const Text('Hủy', style: TextStyle(fontSize: 20)),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Giải tán',
              style: TextStyle(color: Colors.redAccent, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}
