part of '../../../router.dart';

@TypedGoRoute<LobbyRoute>(path: LobbyRoute.path)
class LobbyRoute extends GoRouteData with $LobbyRoute {
  static const path = '/';
  const LobbyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LobbyScreen();
}

@TypedGoRoute<DiscoverRoute>(path: DiscoverRoute.path)
class DiscoverRoute extends GoRouteData with $DiscoverRoute {
  static const path = '/discover';
  const DiscoverRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const DiscoverScreen());
}

@TypedGoRoute<RoomRoute>(path: RoomRoute.path)
class RoomRoute extends GoRouteData with $RoomRoute {
  static const path = '/room';
  const RoomRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const RoomScreen());
}

@TypedGoRoute<QrScanRoute>(path: QrScanRoute.path)
class QrScanRoute extends GoRouteData with $QrScanRoute {
  static const path = '/qr-scan';
  const QrScanRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const QrScannerScreen());
}

@TypedGoRoute<OnboardingRoute>(path: OnboardingRoute.path)
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  static const path = '/onboarding';
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const OnboardingScreen());
}

@TypedGoRoute<EmojiJoinRoute>(path: EmojiJoinRoute.path)
class EmojiJoinRoute extends GoRouteData with $EmojiJoinRoute {
  static const path = '/emoji-join';
  const EmojiJoinRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const EmojiJoinScreen());
}

@TypedGoRoute<QrRoute>(path: QrRoute.path)
class QrRoute extends GoRouteData with $QrRoute {
  static const path = '/room/qr';
  const QrRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeScale(state, const QrScreen());
}

@TypedGoRoute<ExitRoomRoute>(path: ExitRoomRoute.path)
class ExitRoomRoute extends GoRouteData with $ExitRoomRoute {
  static const path = '/room/exit-confirm';
  const ExitRoomRoute();

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
        child: const ExitRoomScreen(),
      );
}

@TypedGoRoute<RouletteRoute>(path: RouletteRoute.path)
class RouletteRoute extends GoRouteData with $RouletteRoute {
  static const path = '/roulette';
  const RouletteRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        maintainState: true,
        barrierDismissible: true,
        barrierLabel: 'Roulette',
        barrierColor: Colors.black.withValues(alpha: 0.7),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: child,
          ),
        ),
        child: const RouletteScreen(),
      );
}
