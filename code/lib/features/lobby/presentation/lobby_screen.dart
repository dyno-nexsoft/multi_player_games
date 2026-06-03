import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/locale_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 24),
                child: const _LanguageToggle(),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.lobbyTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      _TextField(
                        controller: _nameController,
                        label: l10n.yourNameLabel,
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        controller: _roomController,
                        label: l10n.roomNameLabel,
                      ),
                      const SizedBox(height: 20),
                      _ColorPicker(
                        selected: context.watch<LobbyProvider>().selectedColor,
                        onChanged: (c) =>
                            context.read<LobbyProvider>().setColor(c),
                      ),
                      const SizedBox(height: 24),
                      _ActionButton(
                        label: l10n.createRoomBtn,
                        icon: Icons.wifi_tethering,
                        onPressed: () => _hostRoom(context),
                      ),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: l10n.findRoomBtn,
                        icon: Icons.search,
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () => _joinRoom(context),
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: l10n.scanQrBtn,
                        icon: Icons.qr_code_scanner,
                        color: Theme.of(context).colorScheme.tertiary,
                        onPressed: () => _scanQr(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hostRoom(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.hostRoom(
      _nameController.text.trim(),
      _roomController.text.trim(),
    );
    if (context.mounted) context.push('/room');
  }

  Future<void> _joinRoom(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.discoverRooms(_nameController.text.trim());
    if (context.mounted) context.push('/discover');
  }

  Future<void> _scanQr(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    // Khởi tạo local player trước khi mở scanner
    await lobby.discoverRooms(_nameController.text.trim());
    if (context.mounted) context.push('/qr-scan');
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isVietnamese = localeProvider.locale.languageCode == 'vi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => localeProvider.toggleLocale(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              key: ValueKey<bool>(isVietnamese),
              children: [
                Text(
                  isVietnamese ? '🇻🇳' : '🇬🇧',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  isVietnamese ? 'VI' : 'EN',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon),
            label: Text(widget.label),
            style: widget.color != null
                ? ElevatedButton.styleFrom(backgroundColor: widget.color)
                : null,
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  static const _colors = [
    0xFF6C63FF, // purple
    0xFFFF6584, // pink
    0xFFFF6B35, // orange
    0xFF4CAF50, // green
    0xFF2196F3, // blue
    0xFFFFD700, // yellow
    0xFFE53935, // red
    0xFF009688, // teal
  ];

  final int selected;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _colors.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: isSelected ? 36 : 28,
            height: isSelected ? 36 : 28,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 8)]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget lobbyPreviewWrapper(Widget child) => ChangeNotifierProvider(
  create: (_) => LocaleProvider(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

@Preview(name: 'Lobby Screen', wrapper: lobbyPreviewWrapper)
Widget previewLobbyScreen() => const LobbyScreen();

@Preview(name: 'Action Button – Create Room')
Widget previewActionButtonCreate() => MaterialApp(
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ActionButton(
          label: 'Create Room',
          icon: Icons.wifi_tethering,
          onPressed: () {},
        ),
      ),
    ),
  ),
);

@Preview(name: 'Action Button – Find Room')
Widget previewActionButtonFind() => MaterialApp(
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _ActionButton(
          label: 'Find Room',
          icon: Icons.search,
          onPressed: () {},
          color: Colors.deepPurple,
        ),
      ),
    ),
  ),
);

@Preview(name: 'Text Field – Player Name')
Widget previewTextField() => MaterialApp(
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _TextField(
          controller: TextEditingController(text: 'Player 1'),
          label: 'Your Name',
        ),
      ),
    ),
  ),
);
