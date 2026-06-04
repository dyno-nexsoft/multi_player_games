import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../game/domain/mini_game_metadata.dart';
import '../../game/domain/mini_game_registry.dart';
import '../../lobby/data/connection_repository.dart';
import '../../lobby/domain/player.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../../../router.dart';

/// Màn hình Sảnh Chờ TV (10-foot UI) cho Host ở chế độ Console.
///
/// Bố cục ngang 2 cột:
///  - Trái (40%): QR Code siêu lớn + Mật Khẩu Emoji fallback
///  - Phải (60%): Sân Khấu — Avatar người chơi rơi xuống khi kết nối
///
/// Tuân theo spec: doc/tv_ui_ux_spec.md
class TvLobbyScreen extends StatefulWidget {
  const TvLobbyScreen({super.key});

  @override
  State<TvLobbyScreen> createState() => _TvLobbyScreenState();
}

class _TvLobbyScreenState extends State<TvLobbyScreen>
    with TickerProviderStateMixin {
  String? _qrData;
  bool _goingToGame = false;
  bool _goingToLobby = false;

  final Map<String, AnimationController> _dropControllers = {};
  final Map<String, Animation<Offset>> _dropAnimations = {};
  final Set<String> _knownIds = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadQrData();
    // Register listener before the first build so _syncNewPlayers fires
    // before Consumer.builder, ensuring dropAnimations is populated by the
    // time the builder reads _dropAnimations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LobbyProvider>().addListener(_onLobbyChanged);
        // Sync the initial player list (e.g. Host is already present).
        _syncNewPlayers(context.read<LobbyProvider>().players);
      }
    });
  }

  @override
  void dispose() {
    // Keep wakelock alive when transitioning to the game — GameHubScreen
    // will re-enable it in initState and release it in its own dispose().
    if (!_goingToGame) WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    for (final ctrl in _dropControllers.values) {
      ctrl.dispose();
    }
    // Safe: context.read is valid until after super.dispose().
    if (mounted) {
      context.read<LobbyProvider>().removeListener(_onLobbyChanged);
    }
    super.dispose();
  }

  void _onLobbyChanged() {
    if (!mounted) return;
    _syncNewPlayers(context.read<LobbyProvider>().players);
  }

  Future<void> _loadQrData() async {
    final lobby = context.read<LobbyProvider>();
    final ip = await lobby.getHostIp();
    if (!mounted) return;
    setState(() {
      _qrData = jsonEncode({
        'ip': ip ?? '?',
        'port': ConnectionRepository.kPort,
      });
    });
  }

  /// Diff players list để chạy drop-in animation chỉ với người mới vào phòng.
  void _syncNewPlayers(List<Player> players) {
    final currentIds = players.map((p) => p.id).toSet();

    for (final player in players) {
      if (!_knownIds.contains(player.id)) {
        _knownIds.add(player.id);
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 750),
        );
        final anim = Tween<Offset>(
          begin: const Offset(0, -4.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.elasticOut));
        _dropControllers[player.id] = ctrl;
        _dropAnimations[player.id] = anim;
        ctrl.forward();
      }
    }

    final removedIds = _knownIds.difference(currentIds);
    for (final id in removedIds) {
      _knownIds.remove(id);
      _dropControllers[id]?.dispose();
      _dropControllers.remove(id);
      _dropAnimations.remove(id);
    }
  }

  void _navigateOnce(
    VoidCallback navigate,
    bool Function() guard,
    void Function() setFlag,
  ) {
    if (guard()) return;
    setFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navigate();
    });
  }

  void _showGameSelector(BuildContext context, LobbyProvider lobby) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _GameSelectorDialog(
        playerCount: lobby.players.length,
        onGameSelected: (gameId) {
          Navigator.pop(ctx);
          lobby.startGame(gameId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LobbyProvider>(
      builder: (context, lobby, _) {
        if (lobby.state != LobbyState.inGame) _goingToGame = false;
        if (lobby.state != LobbyState.idle) _goingToLobby = false;

        if (lobby.state == LobbyState.inGame && lobby.pendingGameId != null) {
          _navigateOnce(
            () => const GameRoute().go(context),
            () => _goingToGame,
            () => _goingToGame = true,
          );
        }

        if (lobby.state == LobbyState.idle) {
          _navigateOnce(
            () => const LobbyRoute().go(context),
            () => _goingToLobby,
            () => _goingToLobby = true,
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldLeave = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.bgSurface,
                title: const Text(
                  'Giải tán phòng?',
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
                content: const Text(
                  'Bạn có chắc chắn muốn giải tán phòng không?',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
                actions: [
                  // Default focus on Cancel per tv_ui_ux_spec.md §1.4
                  TextButton(
                    autofocus: true,
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy', style: TextStyle(fontSize: 20)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text(
                      'Giải tán',
                      style: TextStyle(color: Colors.redAccent, fontSize: 20),
                    ),
                  ),
                ],
              ),
            );
            if (shouldLeave == true && context.mounted) {
              lobby.leaveRoom();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: SafeArea(
              minimum: const EdgeInsets.all(0),
              child: Row(
                children: [
                  // ── Left panel: Connection info (40%) ───────────────────
                  Flexible(
                    flex: 4,
                    child: _ConnectionPanel(
                      qrData: _qrData,
                      emojiCode: lobby.emojiCode,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  // ── Right panel: The Stage (60%) ────────────────────────
                  Flexible(
                    flex: 6,
                    child: _StagePanel(
                      players: lobby.players,
                      dropAnimations: _dropAnimations,
                      canStart: lobby.players.length >= 2,
                      onQuickPlay: () {
                        final games = MiniGameRegistry.availableGames;
                        if (games.isNotEmpty) {
                          lobby.startGame(
                            games[Random().nextInt(games.length)].id,
                          );
                        }
                      },
                      onChooseGame: () => _showGameSelector(context, lobby),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Left Panel ────────────────────────────────────────────────────────────────

class _ConnectionPanel extends StatelessWidget {
  final String? qrData;
  final String emojiCode;

  const _ConnectionPanel({required this.qrData, required this.emojiCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A18),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Party Game Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // White border acts as quiet zone — prevents HDR glare per spec §2.1
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.glowShadow(
                AppTheme.neonCyan,
                blur: 28,
                spread: 2,
              ),
            ),
            child: qrData != null
                ? QrImageView(
                    data: qrData!,
                    size: 200,
                    backgroundColor: Colors.white,
                  )
                : const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.neonPurple,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quét QR để tham gia',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          if (emojiCode.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'hoặc nhập mật khẩu',
              style: TextStyle(color: Colors.white38, fontSize: 15),
            ),
            const SizedBox(height: 10),
            // Emoji password — huge fallback for far viewers per spec §2.1
            Text(
              emojiCode,
              style: const TextStyle(fontSize: 52, letterSpacing: 10),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Right Panel — The Stage ───────────────────────────────────────────────────

class _StagePanel extends StatelessWidget {
  final List<Player> players;
  final Map<String, Animation<Offset>> dropAnimations;
  final bool canStart;
  final VoidCallback onQuickPlay;
  final VoidCallback onChooseGame;

  const _StagePanel({
    required this.players,
    required this.dropAnimations,
    required this.canStart,
    required this.onQuickPlay,
    required this.onChooseGame,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Row(
            children: [
              const Icon(
                Icons.stadium_outlined,
                color: AppTheme.neonPurple,
                size: 26,
              ),
              const SizedBox(width: 10),
              const Text(
                'Sân Khấu',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${players.length} người chơi',
                style: const TextStyle(color: Colors.white38, fontSize: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        Expanded(
          child: players.isEmpty
              ? const _EmptyStage()
              : _AvatarStage(
                  players: players,
                  dropAnimations: dropAnimations,
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canStart) ...[
                _TvButton(
                  label: '⚡  Quick Play',
                  color: AppTheme.neonCyan,
                  autofocus: true,
                  onPressed: onQuickPlay,
                ),
                const SizedBox(width: 20),
              ],
              _TvButton(
                label: '🎮  Chọn Game',
                color: AppTheme.neonPurple,
                autofocus: !canStart,
                onPressed: onChooseGame,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStage extends StatelessWidget {
  const _EmptyStage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_outlined, size: 72, color: Colors.white12),
          SizedBox(height: 16),
          Text(
            'Chưa có ai tham gia...',
            style: TextStyle(color: Colors.white24, fontSize: 22),
          ),
          SizedBox(height: 8),
          Text(
            'Mời bạn bè quét QR hoặc nhập mật khẩu!',
            style: TextStyle(color: Colors.white12, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AvatarStage extends StatelessWidget {
  final List<Player> players;
  final Map<String, Animation<Offset>> dropAnimations;

  const _AvatarStage({
    required this.players,
    required this.dropAnimations,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Neon floor line
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.neonPurple.withValues(alpha: 0.45),
                  AppTheme.neonCyan.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Avatars lined up on the floor
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: players.map((p) {
            final anim = dropAnimations[p.id];
            final avatar = Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: _PlayerAvatar(player: p),
            );
            return anim != null
                ? SlideTransition(position: anim, child: avatar)
                : avatar;
          }).toList(),
        ),
      ],
    );
  }
}

// ── Player Avatar ─────────────────────────────────────────────────────────────

class _PlayerAvatar extends StatelessWidget {
  final Player player;

  const _PlayerAvatar({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = Color(player.color);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 3),
            boxShadow: AppTheme.glowShadow(color, blur: 24, spread: 3),
          ),
          child: Center(
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          player.name,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (player.isHost)
          Text(
            'Host',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

// ── TV Button (Focus: 1.15× scale + 16dp glow per spec §1.1) ─────────────────

class _TvButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool autofocus;
  final VoidCallback onPressed;

  const _TvButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<_TvButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _focused ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _focused ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.color.withValues(alpha: _focused ? 1.0 : 0.45),
                width: _focused ? 3 : 2,
              ),
              boxShadow: _focused
                  ? AppTheme.glowShadow(widget.color, blur: 20, spread: 4)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Game Selector Dialog ──────────────────────────────────────────────────────

class _GameSelectorDialog extends StatelessWidget {
  final int playerCount;
  final ValueChanged<String> onGameSelected;

  const _GameSelectorDialog({
    required this.playerCount,
    required this.onGameSelected,
  });

  @override
  Widget build(BuildContext context) {
    final games = MiniGameRegistry.availableGames
        .where(
          (g) => playerCount >= g.minPlayers && playerCount <= g.maxPlayers,
        )
        .toList();

    return Dialog(
      backgroundColor: AppTheme.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppTheme.neonPurple.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn Mini-Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$playerCount người chơi',
              style: const TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (games.isEmpty)
              const Text(
                'Không có game phù hợp với số lượng người chơi này.',
                style: TextStyle(color: Colors.white54, fontSize: 18),
                textAlign: TextAlign.center,
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: games
                        .map(
                          (g) => _GameChip(
                            game: g,
                            onTap: () => onGameSelected(g.id),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.white54, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameChip extends StatelessWidget {
  final MiniGameMetadata game;
  final VoidCallback onTap;

  const _GameChip({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.neonPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.neonPurple.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          game.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
