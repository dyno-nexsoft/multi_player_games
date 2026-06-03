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
                      const SizedBox(height: 32),
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
