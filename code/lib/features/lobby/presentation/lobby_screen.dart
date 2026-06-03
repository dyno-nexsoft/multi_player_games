import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'lobby_provider.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Player');
  final _roomController = TextEditingController(text: 'My Room');

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎮 Party Game Hub',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              _TextField(controller: _nameController, label: 'Tên của bạn'),
              const SizedBox(height: 16),
              _TextField(controller: _roomController, label: 'Tên phòng (Host)'),
              const SizedBox(height: 32),
              _ActionButton(
                label: 'Tạo Phòng (Host)',
                icon: Icons.wifi_tethering,
                onPressed: () => _hostRoom(context),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: 'Tìm Phòng (Join)',
                icon: Icons.search,
                color: Theme.of(context).colorScheme.secondary,
                onPressed: () => _joinRoom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _hostRoom(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.hostRoom(_nameController.text.trim(), _roomController.text.trim());
    if (context.mounted) context.push('/room');
  }

  Future<void> _joinRoom(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.discoverRooms(_nameController.text.trim());
    if (context.mounted) context.push('/discover');
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _TextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
      ),
    );
  }
}
