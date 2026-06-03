import 'dart:convert';
import 'dart:math';
import 'roulette_cup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:party_game_hub/core/theme/neon_widgets.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../domain/player.dart';
import 'lobby_provider.dart';
import '../../game/domain/mini_game_metadata.dart';
import '../../game/domain/mini_game_registry.dart';

Future<void> _showQrDialog(BuildContext context, LobbyProvider lobby) async {
  final ip = await lobby.getHostIp();
  if (!context.mounted) return;
  final qrData = jsonEncode({'ip': ip ?? '?', 'port': 4567});
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('QR vào phòng'),
      content: SizedBox(
        width: 240,
        height: 240,
        child: QrImageView(data: qrData, size: 240),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Màn hình phòng chờ — danh sách người chơi và nút bắt đầu (chỉ Host).
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  // Guards: chặn addPostFrameCallback đăng ký nhiều lần
  bool _goingToGame = false;
  bool _goingToLobby = false;

  void _navigateOnce(String path, bool Function() guard, void Function() setFlag) {
    if (guard()) return;
    setFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        // Reset flags khi state thay đổi (đề phòng user quay lại rồi vào lại)
        if (lobby.state != LobbyState.inGame) _goingToGame = false;
        if (lobby.state != LobbyState.idle) _goingToLobby = false;

        if (lobby.state == LobbyState.inGame && lobby.pendingGameId != null) {
          _navigateOnce('/game', () => _goingToGame, () => _goingToGame = true);
        }

        if (lobby.state == LobbyState.idle) {
          _navigateOnce('/', () => _goingToLobby, () => _goingToLobby = true);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.roomTitle),
            leading: BackButton(onPressed: () => context.go('/')),
            actions: [
              if (lobby.isHost)
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showQrDialog(context, lobby),
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _PlayerList(players: lobby.players),
                  if (lobby.isHost) Expanded(child: _GameSelector(lobby: lobby)),
                ],
              ),
              if (lobby.state == LobbyState.reconnecting)
                const _ReconnectingOverlay(),
            ],
          ),
        );
      },
    );
  }
}

// ── Player List ────────────────────────────────────────────────────────────

class _PlayerList extends StatelessWidget {
  final List<Player> players;
  const _PlayerList({required this.players});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: players.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(p.color),
                    boxShadow: [
                      BoxShadow(
                        color: Color(p.color).withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      p.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                if (p.isHost)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      l10n.host,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Game Selector ──────────────────────────────────────────────────────────

class _GameSelector extends StatelessWidget {
  final LobbyProvider lobby;
  const _GameSelector({required this.lobby});

  String _localTitle(BuildContext context, String gameId, MiniGameMetadata game) {
    final l10n = AppLocalizations.of(context)!;
    return switch (gameId) {
      'tug_of_war'       => l10n.gameTugOfWarTitle,
      'sumo_bumper'      => l10n.gameSumoBumperTitle,
      'penalty_shootout' => l10n.gamePenaltyShootoutTitle,
      'air_hockey'       => l10n.gameAirHockeyTitle,
      'reaction_tap'     => l10n.gameReactionTapTitle,
      'minesweeper'      => l10n.gameMinesweeperTitle,
      'billiards'        => l10n.gameBilliardsTitle,
      'draw_guess'       => l10n.gameDrawGuessTitle,
      'battleship'       => l10n.gameBattleshipTitle,
      'hot_potato'       => l10n.gameHotPotatoTitle,
      _                  => game.title,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final games = MiniGameRegistry.availableGames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Series selector + Quick Play ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.selectMiniGame,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Bo 1')),
                  ButtonSegment(value: 3, label: Text('Bo 3')),
                  ButtonSegment(value: 5, label: Text('Bo 5')),
                ],
                selected: {lobby.seriesLength},
                onSelectionChanged: (v) => lobby.setSeriesLength(v.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // ── Quick Play + Roulette Cup ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Quick Play
              Expanded(
                child: PulseButton(
                  glowColor: Theme.of(context).colorScheme.secondary,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final randomGame = games[Random().nextInt(games.length)];
                      lobby.startGame(randomGame.id);
                    },
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: const Text('Quick Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Roulette Cup
              Expanded(
                child: PulseButton(
                  glowColor: const Color(0xFFFFD700),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final gameId = await showRouletteCup(context);
                      if (gameId != null && context.mounted) {
                        lobby.startGame(gameId);
                      }
                    },
                    icon: const Icon(Icons.casino, size: 16),
                    label: const Text('Roulette 🎰'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B5800),
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Games grid ───────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: games.length,
              itemBuilder: (context, i) {
                final game = games[i];
                return NeonGameCard(
                  game: game,
                  localizedTitle: _localTitle(context, game.id, game),
                  onTap: () => lobby.startGame(game.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reconnecting overlay ───────────────────────────────────────────────────

class _ReconnectingOverlay extends StatelessWidget {
  const _ReconnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Đang kết nối lại...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Previews ──────────────────────────────────────────────────────────────────

Widget roomPreviewWrapper(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

@Preview(name: 'Player List – 2 người chơi', wrapper: roomPreviewWrapper)
Widget previewPlayerList() => Scaffold(
  body: _PlayerList(
    players: const [
      Player(id: '1', name: 'Alice', isHost: true, color: 0xFF6C63FF),
      Player(id: '2', name: 'Bob', color: 0xFFFF6584),
    ],
  ),
);
