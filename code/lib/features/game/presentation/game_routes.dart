part of '../../../router.dart';

@TypedGoRoute<GameRoute>(path: GameRoute.path)
class GameRoute extends GoRouteData with $GameRoute {
  static const path = '/game';
  const GameRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const GameHubScreen(),
    duration: const Duration(milliseconds: 500),
  );
}

@TypedGoRoute<SpectatorRoute>(path: SpectatorRoute.path)
class SpectatorRoute extends GoRouteData with $SpectatorRoute {
  static const path = '/spectate';
  const SpectatorRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const SpectatorScreen(),
    duration: const Duration(milliseconds: 400),
  );
}
