import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/game/presentation/game_provider.dart';
import 'features/lobby/presentation/lobby_provider.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PartyGameHubApp());
}

class PartyGameHubApp extends StatelessWidget {
  const PartyGameHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LobbyProvider()),
        ChangeNotifierProxyProvider<LobbyProvider, GameProvider>(
          create: (ctx) => GameProvider(ctx.read<LobbyProvider>()),
          update: (_, lobby, prev) => prev ?? GameProvider(lobby),
        ),
      ],
      child: MaterialApp.router(
        title: 'Party Game Hub',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
