import 'package:flutter/material.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/audio/audio_service.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/game/presentation/game_provider.dart';
import 'features/lobby/presentation/lobby_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAudio.preload();
  runApp(const PartyGameHubApp());
}

class PartyGameHubApp extends StatelessWidget {
  const PartyGameHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => LobbyProvider()),
        ChangeNotifierProxyProvider<LobbyProvider, GameProvider>(
          create: (ctx) => GameProvider(ctx.read<LobbyProvider>()),
          update: (_, lobby, prev) => prev ?? GameProvider(lobby),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp.router(
            title: 'Party Game Hub',
            theme: AppTheme.light,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
