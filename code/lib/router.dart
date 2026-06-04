import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/lobby/presentation/discover_screen.dart';
import 'features/lobby/presentation/room_screen.dart';
import 'features/lobby/presentation/qr_scanner_screen.dart';
import 'features/game/presentation/game_hub_screen.dart';
import 'features/console/presentation/gamepad_screen.dart';
import 'features/lobby/presentation/onboarding_screen.dart';
import 'features/lobby/presentation/emoji_join_screen.dart';
import 'features/game/presentation/spectator_screen.dart';

part 'router.g.dart';
part 'features/lobby/presentation/lobby_routes.dart';
part 'features/game/presentation/game_routes.dart';
part 'features/console/presentation/console_routes.dart';

// ── Shared transition helper ───────────────────────────────────────────────

CustomTransitionPage<void> _fadeScale(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 320),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCirc,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The main router configuration for the application.
final appRouter = GoRouter(initialLocation: '/', routes: $appRoutes);
