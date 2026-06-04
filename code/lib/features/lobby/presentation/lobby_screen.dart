import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/storage/onboarding_service.dart';
import 'package:party_game_hub/core/storage/stats_service.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../router.dart';
import 'lobby_provider.dart';
import 'onboarding_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Player');
  final _roomController = TextEditingController(text: 'My Room');
  bool _tvMode = false;

  @override
  void initState() {
    super.initState();
    OnboardingService.isFirstTime().then((first) {
      if (first && mounted) const OnboardingRoute().go(context);
    });
    // Auto-detect TV mode: landscape + width > 900dp per spec §4
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      if (size.width > size.height && size.width > 900) {
        setState(() => _tvMode = true);
      }
    });
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: _LanguageToggle(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            color: Colors.white70,
            onPressed: () => OnboardingScreen.showAsDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.lobbyTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _StatsBar(),
                    const SizedBox(height: 32),

                    // Profile Section
                    _GlassCard(
                      title: l10n.profileSectionTitle,
                      icon: Icons.person_outline,
                      child: Column(
                        children: [
                          _GlassTextField(
                            controller: _nameController,
                            label: l10n.yourNameLabel,
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 20),
                          _ColorPicker(
                            selected: context
                                .watch<LobbyProvider>()
                                .selectedColor,
                            onChanged: (c) =>
                                context.read<LobbyProvider>().setColor(c),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Host Section
                    _GlassCard(
                      title: l10n.hostSectionTitle,
                      icon: Icons.add_home_outlined,
                      child: Column(
                        children: [
                          _GlassTextField(
                            controller: _roomController,
                            label: l10n.roomNameLabel,
                            icon: Icons.meeting_room_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.tv, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.tvModeLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _tvMode,
                                onChanged: (val) =>
                                    setState(() => _tvMode = val),
                                activeTrackColor: Colors.cyanAccent.withValues(
                                  alpha: 0.5,
                                ),
                                thumbColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return Colors.cyanAccent;
                                      }
                                      return Colors.white70;
                                    }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _PrimaryButton(
                            label: l10n.createRoomBtn,
                            icon: Icons.wifi_tethering,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            onPressed: () =>
                                _hostRoom(context, consoleMode: _tvMode),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Join Section
                    _GlassCard(
                      title: l10n.joinSectionTitle,
                      icon: Icons.login_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SecondaryGridButton(
                                  label: l10n.findLanBtn,
                                  icon: Icons.radar,
                                  color: Colors.blueAccent,
                                  onPressed: () => _joinRoom(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SecondaryGridButton(
                                  label: l10n.scanQrLabel,
                                  icon: Icons.qr_code_scanner,
                                  color: Colors.pinkAccent,
                                  onPressed: () => _scanQr(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SecondaryGridButton(
                                  label: l10n.enterEmojiBtn,
                                  icon: Icons.tag_faces,
                                  color: Colors.greenAccent,
                                  onPressed: () async {
                                    final lobby = context.read<LobbyProvider>();
                                    if (lobby.localPlayer == null) {
                                      await lobby.discoverRooms(
                                        _nameController.text.trim(),
                                      );
                                    }
                                    if (context.mounted) {
                                      const EmojiJoinRoute().push(context);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _hostRoom(
    BuildContext context, {
    bool consoleMode = false,
  }) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.hostRoom(
      _nameController.text.trim(),
      _roomController.text.trim(),
      consoleMode: consoleMode,
    );
    if (!context.mounted) return;
    if (consoleMode) {
      const TvLobbyRoute().push(context);
    } else {
      const RoomRoute().push(context);
    }
  }

  Future<void> _joinRoom(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.discoverRooms(_nameController.text.trim());
    if (context.mounted) const DiscoverRoute().push(context);
  }

  Future<void> _scanQr(BuildContext context) async {
    final lobby = context.read<LobbyProvider>();
    await lobby.discoverRooms(_nameController.text.trim());
    if (context.mounted) const QrScanRoute().push(context);
  }
}

// ── Components ─────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _GlassCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient gradient;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.gradient,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryGridButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SecondaryGridButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_SecondaryGridButton> createState() => _SecondaryGridButtonState();
}

class _SecondaryGridButtonState extends State<_SecondaryGridButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 28),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlayerStats>(
      future: StatsService.load(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        if (stats == null || stats.gamesPlayed == 0) {
          return const SizedBox.shrink();
        }
        final winPct = (stats.winRate * 100).round();
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            _StatChip(icon: '🎮', label: '${stats.gamesPlayed}'),
            _StatChip(icon: '🏆', label: '${stats.wins} ($winPct%)'),
            _StatChip(icon: '🔥', label: '${stats.currentStreak}'),
            if (stats.bestStreak > 0)
              _StatChip(icon: '⭐', label: '${stats.bestStreak}'),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        '$icon $label',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final isVietnamese = localeProvider.locale.languageCode == 'vi';

    return InkWell(
      onTap: () => localeProvider.toggleLocale(),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            key: ValueKey<bool>(isVietnamese),
            children: [
              Text(
                isVietnamese ? '🇻🇳' : '🇬🇧',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                isVietnamese ? 'VI' : 'EN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  static const _colors = [
    0xFF6C63FF,
    0xFFFF6584,
    0xFFFF6B35,
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFFD700,
    0xFFE53935,
    0xFF009688,
  ];

  final int selected;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colors.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isSelected ? 32 : 24,
            height: isSelected ? 32 : 24,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(c).withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
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
