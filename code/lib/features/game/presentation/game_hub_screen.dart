import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../lobby/domain/player.dart';
import '../../lobby/presentation/lobby_provider.dart';
import 'game_provider.dart';
import 'overlays/countdown_overlay.dart';

/// Màn hình chính của game — gắn FlameGame vào Flutter hoặc hiển thị bảng điểm.
class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  bool _showCountdown = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lobby = context.read<LobbyProvider>();
      final gameProvider = context.read<GameProvider>();
      if (lobby.pendingGameId != null) {
        gameProvider.launchGame(lobby.pendingGameId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (gameProvider.showScoreboard) {
          return _ScoreboardScreen(scores: gameProvider.totalScores);
        }

        final game = gameProvider.activeGame;
        if (game == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Stack(
          children: [
            GameWidget(game: game),
            if (_showCountdown)
              CountdownOverlay(
                onComplete: () => setState(() => _showCountdown = false),
              ),
          ],
        );
      },
    );
  }
}

class _ScoreboardScreen extends StatelessWidget {
  final Map<String, int> scores;

  const _ScoreboardScreen({required this.scores});

  @override
  Widget build(BuildContext context) {
    final lobby = context.read<LobbyProvider>();
    final sortedPlayers = List.of(lobby.players)
      ..sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                '🏆 Bảng Xếp Hạng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (_, i) {
                    final player = sortedPlayers[i];
                    return _RankTile(
                      rank: i + 1,
                      player: player,
                      score: scores[player.id] ?? 0,
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  lobby.returnToLobby();
                  context.go('/room');
                },
                child: const Text('Quay lại Phòng Chờ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  final int rank;
  final Player player;
  final int score;

  const _RankTile({required this.rank, required this.player, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$rank')),
        title: Text(player.name),
        trailing: Text(
          '$score điểm',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
