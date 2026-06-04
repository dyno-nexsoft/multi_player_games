import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';

/// Màn hình xác nhận thoát Gamepad — push với opaque: false.
class ExitGamepadScreen extends StatelessWidget {
  const ExitGamepadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Rời trò chơi?'),
        content: const Text(
          'Bạn sẽ ngắt kết nối khỏi trò chơi này. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text(
              'Thoát',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
