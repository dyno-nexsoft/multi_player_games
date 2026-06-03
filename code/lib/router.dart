import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/lobby/presentation/discover_screen.dart';
import 'features/lobby/presentation/room_screen.dart';
import 'features/lobby/presentation/qr_scanner_screen.dart';
import 'features/game/presentation/game_hub_screen.dart';

part 'router.g.dart';

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

// ── Routes ─────────────────────────────────────────────────────────────────

@TypedGoRoute<LobbyRoute>(path: '/')
class LobbyRoute extends GoRouteData with $LobbyRoute {
  const LobbyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LobbyScreen();
}

@TypedGoRoute<DiscoverRoute>(path: '/discover')
class DiscoverRoute extends GoRouteData with $DiscoverRoute {
  const DiscoverRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const DiscoverScreen());
}

@TypedGoRoute<RoomRoute>(path: '/room')
class RoomRoute extends GoRouteData with $RoomRoute {
  const RoomRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const RoomScreen());
}

@TypedGoRoute<GameRoute>(path: '/game')
class GameRoute extends GoRouteData with $GameRoute {
  const GameRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const GameHubScreen(), duration: const Duration(milliseconds: 500));
}

@TypedGoRoute<QrScanRoute>(path: '/qr-scan')
class QrScanRoute extends GoRouteData with $QrScanRoute {
  const QrScanRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const QrScannerScreen());
}

/// The main router configuration for the application.
final appRouter = GoRouter(initialLocation: '/', routes: $appRoutes);
