import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/game/presentation/game_provider.dart';
import '../../features/lobby/presentation/lobby_provider.dart';
import '../localization/locale_provider.dart';

/// Centralized Dependency Injection setup for the application.
abstract class AppProviders {
  /// Returns the list of all providers required at the root of the app.
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider(create: (_) => LobbyProvider()),
    ChangeNotifierProxyProvider<LobbyProvider, GameProvider>(
      create: (ctx) => GameProvider(ctx.read<LobbyProvider>()),
      update: (_, lobby, prev) => prev ?? GameProvider(lobby),
    ),
  ];
}
