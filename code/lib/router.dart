import 'package:go_router/go_router.dart';
import 'features/lobby/presentation/lobby_screen.dart';
import 'features/lobby/presentation/discover_screen.dart';
import 'features/lobby/presentation/room_screen.dart';
import 'features/game/presentation/game_hub_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, _) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/discover',
      builder: (ctx, _) => const DiscoverScreen(),
    ),
    GoRoute(
      path: '/room',
      builder: (ctx, _) => const RoomScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (ctx, _) => const GameHubScreen(),
    ),
  ],
);
