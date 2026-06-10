part of '../../../router.dart';

@TypedGoRoute<GameRoute>(
  path: '/game',
  routes: [TypedGoRoute<ScoreboardRoute>(path: 'scoreboard')],
)
class GameRoute extends GoRouteData with $GameRoute {
  const GameRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) => _fadeScale(
    state,
    const GameHubScreen(),
    duration: const Duration(milliseconds: 500),
  );
}

class ScoreboardRoute extends GoRouteData with $ScoreboardRoute {
  const ScoreboardRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _slideUp(state, const ScoreboardScreen());
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

@TypedGoRoute<CountdownRoute>(path: CountdownRoute.path)
class CountdownRoute extends GoRouteData with $CountdownRoute {
  static const path = '/game/countdown';
  const CountdownRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        maintainState: true,
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        child: const CountdownScreen(),
      );
}

@TypedGoRoute<PauseRoute>(path: PauseRoute.path)
class PauseRoute extends GoRouteData with $PauseRoute {
  static const path = '/game/pause';
  const PauseRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        maintainState: true,
        barrierDismissible: true,
        barrierLabel: 'Pause',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (ctx, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        child: const PauseScreen(),
      );
}

@TypedGoRoute<ExitGameRoute>(path: ExitGameRoute.path)
class ExitGameRoute extends GoRouteData with $ExitGameRoute {
  static const path = '/game/exit-confirm';
  const ExitGameRoute();

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
        child: const ExitGameScreen(),
      );
}
