import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/console/presentation/exit_gamepad_screen.dart';
import 'features/console/presentation/exit_tv_lobby_screen.dart';
import 'features/console/presentation/gamepad_screen.dart';
import 'features/console/presentation/tv_game_selector_screen.dart';
import 'features/console/presentation/tv_lobby_screen.dart';
import 'features/game/presentation/countdown_screen.dart';
import 'features/game/presentation/exit_game_screen.dart';
import 'features/game/presentation/game_hub_screen.dart';
import 'features/game/presentation/pause_screen.dart';
import 'features/game/presentation/scoreboard_screen.dart';
import 'features/game/presentation/spectator_screen.dart';
import 'features/lobby/presentation/discover_screen.dart';
import 'features/lobby/presentation/emoji_join_screen.dart';
import 'features/lobby/presentation/exit_room_screen.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/lobby/presentation/onboarding_screen.dart';
import 'features/lobby/presentation/qr_scanner_screen.dart';
import 'features/lobby/presentation/qr_screen.dart';
import 'features/lobby/presentation/room_screen.dart';
import 'features/lobby/presentation/roulette_screen.dart';

part 'features/console/presentation/console_routes.dart';
part 'features/game/presentation/game_routes.dart';
part 'features/lobby/presentation/lobby_routes.dart';
part 'router.g.dart';

// ── Shared transition helpers ──────────────────────────────────────────────

CustomTransitionPage<void> _slideUp(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 420),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

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
