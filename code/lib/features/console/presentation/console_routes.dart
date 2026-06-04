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
