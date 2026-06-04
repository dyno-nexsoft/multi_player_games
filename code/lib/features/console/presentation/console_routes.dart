part of '../../../router.dart';

@TypedGoRoute<GamepadRoute>(path: GamepadRoute.path)
class GamepadRoute extends GoRouteData with $GamepadRoute {
  static const path = '/gamepad';
  const GamepadRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const GamepadScreen(),
    duration: const Duration(milliseconds: 400),
  );
}

@TypedGoRoute<TvLobbyRoute>(path: TvLobbyRoute.path)
class TvLobbyRoute extends GoRouteData with $TvLobbyRoute {
  static const path = '/tv-lobby';
  const TvLobbyRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const TvLobbyScreen(),
    duration: const Duration(milliseconds: 400),
  );
}
