import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../../../router.dart';
import 'game_provider.dart';

/// Màn hình pause — push trên GameHubScreen với opaque: false.
/// Glassmorphic card trên nền mờ, game canvas vẫn render phía sau.
class PauseScreen extends StatelessWidget {
  const PauseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lobby = context.read<LobbyProvider>();
    final gameProvider = context.read<GameProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: AppTheme.glowShadow(primary, blur: 18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeonTitle(
                          l10n.pauseTitle,
                          fontSize: 22,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            context.pop();
                            const OnboardingRoute().push(context);
                          },
                          child: Icon(
                            Icons.help_outline,
                            color: primary.withValues(alpha: 0.55),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.continueBtn),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pop();
                          gameProvider.leaveGame();
                          lobby.returnToLobby();
                          const RoomRoute().go(context);
                        },
                        icon: const Icon(Icons.exit_to_app, size: 18),
                        label: Text(l10n.leaveRoomBtn),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                        ),
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
}
