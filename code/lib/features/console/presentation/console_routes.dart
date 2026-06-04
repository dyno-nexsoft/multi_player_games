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

@TypedGoRoute<ExitGamepadRoute>(path: ExitGamepadRoute.path)
class ExitGamepadRoute extends GoRouteData with $ExitGamepadRoute {
  static const path = '/gamepad/exit-confirm';
  const ExitGamepadRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        maintainState: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        child: const ExitGamepadScreen(),
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

@TypedGoRoute<ExitTvLobbyRoute>(path: ExitTvLobbyRoute.path)
class ExitTvLobbyRoute extends GoRouteData with $ExitTvLobbyRoute {
  static const path = '/tv-lobby/exit-confirm';
  const ExitTvLobbyRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        maintainState: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (ctx, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        child: const ExitTvLobbyScreen(),
      );
}

@TypedGoRoute<TvGameSelectorRoute>(path: TvGameSelectorRoute.path)
class TvGameSelectorRoute extends GoRouteData with $TvGameSelectorRoute {
  static const path = '/tv-lobby/game-selector';
  const TvGameSelectorRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const TvGameSelectorScreen(),
    duration: const Duration(milliseconds: 280),
  );
}
