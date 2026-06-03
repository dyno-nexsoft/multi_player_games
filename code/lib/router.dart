import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/lobby/presentation/discover_screen.dart';
import 'features/lobby/presentation/room_screen.dart';
import 'features/game/presentation/game_hub_screen.dart';

part 'router.g.dart';

@TypedGoRoute<LobbyRoute>(
  path: '/',
)
class LobbyRoute extends GoRouteData with $LobbyRoute {
  const LobbyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LobbyScreen();
}

@TypedGoRoute<DiscoverRoute>(
  path: '/discover',
)
class DiscoverRoute extends GoRouteData with $DiscoverRoute {
  const DiscoverRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const DiscoverScreen();
}

@TypedGoRoute<RoomRoute>(
  path: '/room',
)
class RoomRoute extends GoRouteData with $RoomRoute {
  const RoomRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const RoomScreen();
}

@TypedGoRoute<GameRoute>(
  path: '/game',
)
class GameRoute extends GoRouteData with $GameRoute {
  const GameRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const GameHubScreen();
}

/// The main router configuration for the application.
/// Uses [go_router_builder] to generate type-safe routes.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: $appRoutes,
);

