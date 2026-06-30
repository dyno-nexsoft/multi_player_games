import 'dart:async';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../domain/base_mini_game.dart';
import '../domain/mini_game_registry.dart';
import '../mini_games/hot_potato/hot_potato_game.dart';
import '../mini_games/minesweeper/minesweeper_game.dart';
import '../mini_games/never_have_i_ever/never_have_i_ever_game.dart';
import '../mini_games/reaction_tap/reaction_tap_game.dart';
import '../mini_games/spin_picker/spin_picker_game.dart';
import '../mini_games/truth_or_dare/truth_or_dare_game.dart';
import 'emote_layer.dart';
import 'game_provider.dart';
import '../../../router.dart';
import 'pause_screen.dart';

/// Màn hình game — GameWidget luôn ở dưới;
/// countdown, pause, xác nhận hiển thị bằng push page qua go_router.
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  bool _showCountdown = true;
  int _lastScheduledToken = -1;
  bool _goingToScoreboard = false;
  bool _pauseOpen = false;
  bool _goingToRoom = false;
  bool _goingToLobby = false;

  // ── Disruption overlay state ──────────────────────────────────────────────
  String? _activeDisruption; // 'tomato' | 'smoke' | 'ice'
  Timer? _disruptionTimer;
  late LobbyProvider _lobby;

  @override
  void initState() {
    super.initState();
    _lobby = context.read<LobbyProvider>();
    if (_lobby.isConsoleMode) WakelockPlus.enable();
    _lobby.onDisruption = (type) {
      if (!mounted) return;
      _disruptionTimer?.cancel();
      setState(() => _activeDisruption = type);
      _disruptionTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _activeDisruption = null);
      });
    };
    _lobby.onSystemPause = () {
      if (!mounted) return;
      final lp = context.read<LobbyProvider>();
      final gp = context.read<GameProvider>();
      _showPauseMenu(context, lp, gp);
    };
    _lobby.onEmoteReceived = (emoji) =>
        EmoteLayer.of(context)?.showEmote(emoji);
  }

  @override
  void dispose() {
    _lobby.onDisruption = null;
    _lobby.onSystemPause = null;
    _lobby.onEmoteReceived = null;
    if (_lobby.isConsoleMode) WakelockPlus.disable();
    _disruptionTimer?.cancel();
    super.dispose();
  }

  void _showCountdownOverlay() async {
    await const CountdownRoute().push<void>(context);
    if (mounted) {
      context.read<GameProvider>().resumeActiveGame();
      setState(() => _showCountdown = false);
    }
  }

  void _showPauseMenu(
    BuildContext context,
    LobbyProvider lobby,
    GameProvider gameProvider,
  ) async {
    if (_pauseOpen) return;
    _pauseOpen = true;
    try {
      await const PauseRoute().push<void>(context);
    } finally {
      _pauseOpen = false;
    }
  }

  Widget _buildGameUi(BuildContext context, BaseMiniGame game) {
    if (game is ReactionTapGame) return game.buildOverlay(context);
    if (game is MinesweeperGame) return game.buildOverlay(context);
    if (game is HotPotatoGame) return game.buildOverlay(context);
    if (game is TruthOrDareGame) return game.buildOverlay(context);
    if (game is SpinPickerGame) return game.buildOverlay(context);
    if (game is NeverHaveIEverGame) return game.buildOverlay(context);
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final lobby = context.read<LobbyProvider>();
        final shouldLeave = await const ExitGameRoute().push<bool>(context);
        if (shouldLeave == true && context.mounted) {
          lobby.leaveRoom();
        }
      },
      child: Consumer2<GameProvider, LobbyProvider>(
        builder: (context, gameProvider, lobby, _) {
          // Navigate to scoreboard when game ends
          if (gameProvider.showScoreboard && !_goingToScoreboard) {
            _goingToScoreboard = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) const ScoreboardRoute().go(context);
            });
          } else if (!gameProvider.showScoreboard && _goingToScoreboard) {
            _goingToScoreboard = false;
          }

          if (lobby.state == LobbyState.inRoom && !_goingToRoom) {
            _goingToRoom = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) const RoomRoute().go(context);
            });
          }
          if (lobby.state != LobbyState.inRoom) _goingToRoom = false;

          if (lobby.state == LobbyState.idle && !_goingToLobby) {
            _goingToLobby = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) const LobbyRoute().go(context);
            });
          }
          if (lobby.state != LobbyState.idle) _goingToLobby = false;

          // Launch game một lần duy nhất mỗi gameStartToken
          if (lobby.gameStartToken > gameProvider.lastLaunchToken &&
              lobby.pendingGameId != null &&
              lobby.gameStartToken != _lastScheduledToken) {
            _lastScheduledToken = lobby.gameStartToken;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final lp = context.read<LobbyProvider>();
              final gp = context.read<GameProvider>();
              if (lp.gameStartToken > gp.lastLaunchToken &&
                  lp.pendingGameId != null) {
                gp.launchGame(lp.pendingGameId!);
                gp.pauseActiveGame();
                setState(() => _showCountdown = true);
                _showCountdownOverlay();
              }
            });
          }

          final game = gameProvider.activeGame;

          // Không có game và chưa hiện scoreboard → đang chờ launch
          if (game == null && !gameProvider.showScoreboard) {
            final gid = gameProvider.lastGameId;
            return Scaffold(
              body: Center(
                child: gid != null
                    ? Hero(
                        tag: 'game_icon_$gid',
                        child: MiniGameRegistry.iconFor(
                          gid,
                        ).svg(width: 80, height: 80),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.black,
            body: SizedBox.expand(
              child: EmoteLayer(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Flame canvas ───────────────────────────────────────────────
                    if (game != null)
                      GestureDetector(
                        onLongPress: () =>
                            _showPauseMenu(context, lobby, gameProvider),
                        behavior: HitTestBehavior.translucent,
                        child: GameWidget(game: game),
                      ),

                    // ── Flutter game UI (các game dùng Flutter UI thay vì Flame) ──
                    if (game != null && !gameProvider.showScoreboard)
                      _buildGameUi(context, game),

                    // ── Disruption overlay (khán giả phá đám) ─────────────────────
                    if (_activeDisruption != null)
                      _DisruptionOverlay(type: _activeDisruption!),

                    // ── Nút pause nhỏ góc trên phải (khi đang chơi) ───────────────
                    if (game != null &&
                        !gameProvider.showScoreboard &&
                        !_showCountdown)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: () =>
                                _showPauseMenu(context, lobby, gameProvider),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.pause,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ); // Stack + EmoteLayer + SizedBox
        },
      ),
    );
  }
}

// ── Disruption Overlay ────────────────────────────────────────────────────────

class _DisruptionOverlay extends StatelessWidget {
  final String type;
  const _DisruptionOverlay({required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      'tomato' => const _TomatoSplat(),
      'smoke' => _SmokeFog(),
      'ice' => const _IceFrost(),
      _ => const SizedBox.shrink(),
    };
  }
}

/// 🍅 Tương Cà Chua — vết đỏ che khoảng 20% màn hình.
class _TomatoSplat extends StatelessWidget {
  const _TomatoSplat();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _TomatoPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TomatoPainter extends CustomPainter {
  static final _splats = [
    (0.15, 0.12, 55.0),
    (0.78, 0.08, 40.0),
    (0.35, 0.85, 50.0),
    (0.85, 0.75, 38.0),
    (0.05, 0.55, 32.0),
    (0.60, 0.20, 28.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xCCE53935);
    for (final (rx, ry, r) in _splats) {
      canvas.drawCircle(Offset(size.width * rx, size.height * ry), r, paint);
    }
  }

  @override
  bool shouldRepaint(_TomatoPainter old) => false;
}

/// 💨 Bom Khói — làm mờ nhẹ toàn màn hình.
class _SmokeFog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(color: Colors.grey.withValues(alpha: 0.35)),
      ),
    );
  }
}

/// ❄️ Đóng Băng — viền băng giá xung quanh màn hình.
class _IceFrost extends StatelessWidget {
  const _IceFrost();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xAA29B6F6), width: 20),
        ),
        child: Container(color: const Color(0x2229B6F6)),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget gameHubPreviewWrapper(Widget child) => ChangeNotifierProvider(
  create: (_) => LobbyProvider(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.dark,
    home: child,
  ),
);

@Preview(name: 'Pause Screen', wrapper: gameHubPreviewWrapper)
Widget previewPauseScreen() => const Scaffold(body: PauseScreen());
