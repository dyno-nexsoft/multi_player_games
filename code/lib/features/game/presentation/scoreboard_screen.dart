import 'package:flutter/material.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../lobby/domain/player.dart';
import '../../lobby/presentation/lobby_provider.dart';
import 'game_provider.dart';
import '../../../router.dart';

/// Full-screen scoreboard shown at the end of each mini-game round.
/// Navigates reactively: when host triggers rematch/next-round the lobby state
/// switches back to inGame and the Consumer below pushes [GameRoute].
class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  bool _goingToGame = false;
  bool _goingToRoom = false;
  bool _goingToLobby = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, LobbyProvider>(
      builder: (context, gp, lobby, _) {
        // Reactive: both host and client navigate to /game when next round starts.
        if (!gp.showScoreboard && !_goingToGame) {
          _goingToGame = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) const GameRoute().go(context);
          });
        }
        if (gp.showScoreboard) _goingToGame = false;

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

        final scores = gp.totalScores;
        final isSeries = gp.seriesLength > 1;
        final l10n = AppLocalizations.of(context)!;

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
                        topScore:
                            topScore, // Truyền topScore vào để tính tỷ lệ Bar
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
                          onPressed: () async {
                            if (gp.lobbyProvider.isTournamentMode) {
                              final gameId = await const RouletteRoute()
                                  .push<String>(context);
                              if (gameId != null && context.mounted) {
                                gp.startNextRoundWithGame(gameId);
                              }
                            } else {
                              gp.startNextRoundSameGame();
                            }
                          },
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
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

        return PopScope(
          canPop: false,
          child: iWon
              ? FireworksOverlay(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: content,
                  ),
                )
              : Scaffold(
                  backgroundColor: const Color(
                    0xFF0D0D12,
                  ).withValues(alpha: 0.96),
                  body: content,
                ),
        );
      },
    );
  }
}

// ── Victory/Defeat banner ──────────────────────────────────────────────────

class _VictoryBanner extends StatelessWidget {
  final bool iWon;
  const _VictoryBanner({required this.iWon});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (iWon) {
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
  final int topScore;
  final int? wins;
  final bool isLocal;
  final bool isWinner;

  const _RankTile({
    required this.rank,
    required this.player,
    required this.score,
    required this.topScore,
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

    final fraction = topScore > 0 ? (score / topScore).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
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
      child: Stack(
        children: [
          // Bar ngang hiển thị điểm số
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction > 0 ? fraction : 0.01,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(player.color).withValues(alpha: 0.1),
                      Color(player.color).withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Nội dung Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
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
              '${player.name}${isLocal ? l10n.youSuffix : ''}',
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
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1,
                ),
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
        ],
      ),
    );
  }
}
