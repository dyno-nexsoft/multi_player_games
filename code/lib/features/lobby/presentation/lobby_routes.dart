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
