import 'dart:async';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../lobby/domain/player.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../../lobby/presentation/onboarding_screen.dart';
import '../domain/mini_game_hints.dart';
import '../domain/mini_game_registry.dart';
import '../mini_games/battleship/battleship_game.dart';
import '../mini_games/billiards/billiards_game.dart';
import '../mini_games/code_breaker/code_breaker_game.dart';
import '../mini_games/draw_guess/draw_guess_game.dart';
import '../mini_games/hot_potato/hot_potato_game.dart';
import '../mini_games/liars_dice/liars_dice_game.dart';
import '../mini_games/minesweeper/minesweeper_game.dart';
import '../mini_games/reaction_tap/reaction_tap_game.dart';
import 'emote_layer.dart';
import 'game_provider.dart';
import '../../../router.dart';
import 'overlays/countdown_overlay.dart';

/// Màn hình game — GameWidget luôn ở dưới;
/// scoreboard và pause hiển thị dưới dạng overlay qua Stack.
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  bool _showCountdown = true;
  int _lastScheduledToken = -1;

  final _externalTick = ValueNotifier<int>(0);

  // ── Disruption overlay state ──────────────────────────────────────────────
  String? _activeDisruption; // 'tomato' | 'smoke' | 'ice'
  // 6.1 — Timer is cancelable in dispose(); Future.delayed is not.
  Timer? _disruptionTimer;

  @override
  void initState() {
    super.initState();
    final lobby = context.read<LobbyProvider>();
    lobby.onCountdownTick = (tick) {
      if (mounted) _externalTick.value = tick;
    };
    lobby.onDisruption = (type) {
      if (!mounted) return;
      _disruptionTimer?.cancel();
      setState(() => _activeDisruption = type);
      _disruptionTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _activeDisruption = null);
      });
    };
  }

  @override
  void dispose() {
    final lobby = context.read<LobbyProvider>();
    lobby.onCountdownTick = null;
    lobby.onDisruption = null;
    _disruptionTimer?.cancel(); // 6.1 — prevent setState after unmount
    _externalTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final lobby = context.read<LobbyProvider>();
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final dialogL10n = AppLocalizations.of(ctx)!;
            return AlertDialog(
              backgroundColor: AppTheme.bgSurface,
              title: Text(dialogL10n.endGameTitle),
              content: Text(dialogL10n.endGameDesc),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(dialogL10n.cancelBtn),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    dialogL10n.endGameBtn,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            );
          },
        );
        if (shouldLeave == true && context.mounted) {
          lobby.leaveRoom();
        }
      },
      child: Consumer2<GameProvider, LobbyProvider>(
        builder: (context, gameProvider, lobby, _) {
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
                // Pause Flame during hint + countdown; resume when they finish.
                gp.pauseActiveGame();
                setState(() => _showCountdown = true);
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

          // Wire emote callback → EmoteLayer
          lobby.onEmoteReceived = (emoji) =>
              EmoteLayer.of(context)?.showEmote(emoji);

          lobby.onSystemPause = () {
            if (ModalRoute.of(context)?.isCurrent ?? true) {
              _showPauseMenu(context, lobby, gameProvider);
            }
          };

          return EmoteLayer(
            child: Stack(
              children: [
                // ── Flame canvas (luôn hiển thị khi game != null) ──────────────
                if (game != null)
                  GestureDetector(
                    onLongPress: () =>
                        _showPauseMenu(context, lobby, gameProvider),
                    behavior: HitTestBehavior.translucent,
                    child: GameWidget(
                      game: game,
                      overlayBuilderMap: {
                        if (game is ReactionTapGame)
                          ReactionTapGame.overlayKey: (ctx, g) =>
                              (g as ReactionTapGame).buildOverlay(ctx),
                        if (game is MinesweeperGame)
                          MinesweeperGame.overlayKey: (ctx, g) =>
                              (g as MinesweeperGame).buildOverlay(ctx),
                        if (game is BilliardsGame)
                          BilliardsGame.overlayKey: (ctx, g) =>
                              (g as BilliardsGame).buildOverlay(ctx),
                        if (game is DrawGuessGame)
                          DrawGuessGame.overlayKey: (ctx, g) =>
                              (g as DrawGuessGame).buildOverlay(ctx),
                        if (game is BattleshipGame)
                          BattleshipGame.overlayKey: (ctx, g) =>
                              (g as BattleshipGame).buildOverlay(ctx),
                        if (game is HotPotatoGame)
                          HotPotatoGame.overlayKey: (ctx, g) =>
                              (g as HotPotatoGame).buildOverlay(ctx),
                        if (game is CodeBreakerGame)
                          CodeBreakerGame.overlayKey: (ctx, g) =>
                              (g as CodeBreakerGame).buildOverlay(ctx),
                        if (game is LiarsDiceGame)
                          LiarsDiceGame.overlayKey: (ctx, g) =>
                              (g as LiarsDiceGame).buildOverlay(ctx),
                      },
                    ),
                  ),

                // ── Countdown + hint overlay ────────────────────────────────────
                if (_showCountdown && !gameProvider.showScoreboard)
                  CountdownOverlay(
                    hint: MiniGameHints.forGame(gameProvider.lastGameId ?? ''),
                    isHost: lobby.isHost,
                    onBroadcastTick: (tick) => lobby.broadcastCountdown(tick),
                    externalTickNotifier: lobby.isHost ? null : _externalTick,
                    isConsoleMode: lobby.isConsoleMode,
                    onComplete: () {
                      // Resume Flame now that hint + countdown are done.
                      context.read<GameProvider>().resumeActiveGame();
                      setState(() => _showCountdown = false);
                    },
                  ),

                // ── Scoreboard overlay dè lên canvas ──────────────────────────
                if (gameProvider.showScoreboard)
                  ScoreboardOverlay(
                    child: _ScoreboardContent(scores: gameProvider.totalScores),
                  ),

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
          ); // Stack + EmoteLayer
        },
      ),
    );
  }

  // ── Pause menu ─────────────────────────────────────────────────────────────

  void _showPauseMenu(
    BuildContext context,
    LobbyProvider lobby,
    GameProvider gameProvider,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Pause',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, animation, _, child) {
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
      pageBuilder: (ctx, a1, a2) =>
          _PauseDialog(lobby: lobby, gameProvider: gameProvider),
    );
  }
}

// ── Pause dialog ───────────────────────────────────────────────────────────

class _PauseDialog extends StatelessWidget {
  final LobbyProvider lobby;
  final GameProvider gameProvider;

  const _PauseDialog({required this.lobby, required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: AppTheme.glowShadow(primary, blur: 18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    NeonTitle(AppLocalizations.of(context)!.pauseTitle, fontSize: 22, color: primary),
                      const SizedBox(width: 8),
                      // [?] help — mở lại onboarding overlay
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          OnboardingScreen.showAsDialog(context);
                        },
                        child: Icon(
                          Icons.help_outline,
                          color: primary.withValues(alpha: 0.55),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Tiếp tục
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(AppLocalizations.of(context)!.continueBtn),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rời phòng
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        gameProvider.leaveGame();
                        lobby.returnToLobby();
                        const RoomRoute().go(context);
                      },
                      icon: const Icon(Icons.exit_to_app, size: 18),
                      label: Text(AppLocalizations.of(context)!.leaveRoomBtn),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scoreboard content ─────────────────────────────────────────────────────

class _ScoreboardContent extends StatelessWidget {
  final Map<String, int> scores;
  const _ScoreboardContent({required this.scores});

  @override
  Widget build(BuildContext context) {
    // 5.2 — Use watch so the scoreboard rebuilds when round/series state changes.
    final lobby = context.watch<LobbyProvider>();
    final gp = context.watch<GameProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isSeries = gp.seriesLength > 1;

    final sortedPlayers = List.of(lobby.players)
      ..sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));

    final localId = lobby.localPlayer?.id;
    final topScore = scores.values.fold(0, (a, b) => a > b ? a : b);
    final localScore = localId != null ? (scores[localId] ?? 0) : 0;
    final iWon = localScore > 0 && localScore >= topScore;

    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            _VictoryBanner(iWon: iWon),
            const SizedBox(height: 4),
            if (isSeries) ...[
              Text(
                l10n.seriesRound(gp.currentRound, gp.seriesLength),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: sortedPlayers.length,
                itemBuilder: (_, i) {
                  final player = sortedPlayers[i];
                  return _RankTile(
                    rank: i + 1,
                    player: player,
                    score: scores[player.id] ?? 0,
                    wins: isSeries ? gp.roundWins[player.id] ?? 0 : null,
                    isLocal: player.id == localId,
                    isWinner: i == 0,
                  );
                },
              ),
            ),

            if (lobby.isHost) ...[
              if (isSeries && !gp.isSeriesOver) ...[
                PulseButton(
                  glowColor: Theme.of(context).colorScheme.primary,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => gp.startNextRound(context),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(l10n.nextRoundBtn),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              PulseButton(
                glowColor: Theme.of(context).colorScheme.secondary,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => gp.startRematch(),
                    icon: const Icon(Icons.replay, size: 18),
                    label: Text(l10n.rematchBtn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  gp.leaveGame();
                  lobby.returnToLobby();
                  const RoomRoute().go(context);
                },
                child: Text(l10n.backToLobbyBtn),
              ),
            ),
          ],
        ),
      ),
    );

    return iWon
        ? FireworksOverlay(
            child: Scaffold(backgroundColor: Colors.transparent, body: content),
          )
        : Scaffold(
            backgroundColor: const Color(0xFF0D0D12).withValues(alpha: 0.96),
            body: content,
          );
  }
}

// ── Victory/Defeat banner ──────────────────────────────────────────────────

class _VictoryBanner extends StatelessWidget {
  final bool iWon;
  const _VictoryBanner({required this.iWon});

  @override
  Widget build(BuildContext context) {
    if (iWon) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        children: [
          NeonTitle(
            '🏆 VICTORY!',
            fontSize: 36,
            color: const Color(0xFFFFD700),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.victorySubtitle,
            style: TextStyle(
              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      );
    }
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Text(
          '😢 DEFEAT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.defeatSubtitle,
          style: const TextStyle(color: Colors.white24, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Rank tile ──────────────────────────────────────────────────────────────

class _RankTile extends StatelessWidget {
  final int rank;
  final Player player;
  final int score;
  final int? wins;
  final bool isLocal;
  final bool isWinner;

  const _RankTile({
    required this.rank,
    required this.player,
    required this.score,
    required this.isLocal,
    required this.isWinner,
    this.wins,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = isWinner
        ? const Color(0xFFFFD700)
        : isLocal
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD700).withValues(alpha: 0.6)
              : isLocal
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: isWinner || isLocal ? 1.5 : 1.0,
        ),
        boxShadow: (isWinner || isLocal)
            ? AppTheme.glowShadow(accent, blur: 12)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(player.color),
              child: Text(
                player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (rank == 1)
              const Positioned(
                top: 0,
                right: 0,
                child: Text('👑', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        title: Text(
          '${player.name}${isLocal ? AppLocalizations.of(context)!.youSuffix : ''}' ,
          style: TextStyle(
            color: isWinner ? const Color(0xFFFFD700) : Colors.white,
            fontWeight: isLocal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: wins != null
            ? Text(
                l10n.seriesWins(wins!),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isWinner ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            l10n.pointsText(score),
            style: TextStyle(
              color: isWinner ? const Color(0xFFFFD700) : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
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

@Preview(name: 'Pause Dialog', wrapper: gameHubPreviewWrapper)
Widget previewPauseDialog() => Scaffold(
  body: _PauseDialog(
    lobby: LobbyProvider(),
    gameProvider: GameProvider(LobbyProvider()),
  ),
);
