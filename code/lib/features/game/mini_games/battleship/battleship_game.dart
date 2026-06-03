import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../domain/base_mini_game.dart';

/// Hải Chiến Không Gian — mỗi màn hình là một chiến trường riêng.
/// Hidden information: đối thủ không biết bạn đặt tàu ở đâu.
/// Ships: [2, 3, 4] ô. Grid: 8×8.
class BattleshipGame extends BaseMiniGame {
  static const String overlayKey = 'battleship_ui';
  static const int _gridSize = 8;
  static const List<int> _shipSizes = [4, 3, 2];

  BattleshipGame(super.gameProvider);

  @override
  String get gameId => 'battleship';

  // ── Phase ─────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.placement;

  // ── My grid ───────────────────────────────────────────────────────────────
  // 0 = empty, 1 = my ship, 2 = hit on my ship, 3 = missed shot on my grid
  final List<List<int>> _myGrid =
      List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

  // ── Opponent tracking grid ────────────────────────────────────────────────
  // null = unknown, true = hit, false = miss
  final List<List<bool?>> _trackGrid =
      List.generate(_gridSize, (_) => List.filled(_gridSize, null));

  // ── Ship placement state ──────────────────────────────────────────────────
  final List<_Ship> _ships = [];          // my placed ships
  int _selectedShipIndex = 0;             // ship index being placed
  bool _horizontal = true;                // orientation toggle

  // ── Game flow ─────────────────────────────────────────────────────────────
  bool _myTurn = false;
  bool _gameOver = false;
  bool _cancelled = false;

  String _statusText = '';
  String get statusText => _statusText;

  String _resultText = '';
  String get resultText => _resultText;

  // Opponent's ship grid — only host holds this
  final List<List<int>> _oppGrid =
      List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

  final Map<String, int> _scores = {};

  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
    _statusText = 'Đặt tàu của bạn';
    overlays.add(overlayKey);
  }

  // ── Ship placement ─────────────────────────────────────────────────────────

  // Private getters used by overlay widgets in the same file
  int get selectedShipIndex => _selectedShipIndex;
  bool get horizontal => _horizontal;

  void toggleOrientation() {
    _horizontal = !_horizontal;
    _notify();
  }

  List<_Cell>? _previewPlacement(int r, int c) {
    if (_selectedShipIndex >= _shipSizes.length) return null;
    final size = _shipSizes[_selectedShipIndex];
    return _shipCells(r, c, size, _horizontal);
  }

  List<_Cell>? _shipCells(int r, int c, int size, bool horiz) {
    final cells = <_Cell>[];
    for (int i = 0; i < size; i++) {
      final nr = horiz ? r : r + i;
      final nc = horiz ? c + i : c;
      if (nr < 0 || nr >= _gridSize || nc < 0 || nc >= _gridSize) return null;
      cells.add(_Cell(nr, nc));
    }
    // Check overlap with existing ships
    for (final ship in _ships) {
      for (final cell in cells) {
        if (ship.cells.contains(cell)) return null;
      }
    }
    return cells;
  }

  void placeship(int r, int c) {
    if (_selectedShipIndex >= _shipSizes.length) return;
    final size = _shipSizes[_selectedShipIndex];
    final cells = _shipCells(r, c, size, _horizontal);
    if (cells == null) return;

    // Remove existing ship at this index if re-placing
    _ships.removeWhere((s) => s.index == _selectedShipIndex);

    final ship = _Ship(index: _selectedShipIndex, cells: cells, size: size);
    _ships.add(ship);
    for (final cell in cells) {
      _myGrid[cell.r][cell.c] = 1;
    }

    HapticFeedback.lightImpact();
    AppAudio.playTap();

    if (_ships.length < _shipSizes.length) {
      _selectedShipIndex = _ships.length;
    }
    _notify();
  }

  void selectShipToPlace(int index) {
    _selectedShipIndex = index;
    _notify();
  }

  void confirmPlacement() {
    if (_ships.length < _shipSizes.length) return;

    // Encode ship positions as flat list
    final flat = _myGrid.expand((r) => r).toList();
    gameProvider.sendGameData(gameId, {
      'action': 'place_ships',
      'grid': flat,
    });

    _phase = _Phase.waiting;
    _statusText = 'Chờ đối thủ đặt tàu...';
    _notify();
  }

  // ── Host-side logic ────────────────────────────────────────────────────────

  void _startAttackPhase() {
    _phase = _Phase.attacking;
    // Host always goes first
    _myTurn = gameProvider.lobbyProvider.isHost;
    _statusText = _myTurn ? 'Lượt bạn — chọn ô tấn công!' : 'Đợi đối thủ tấn công...';
    gameProvider.sendGameData(gameId, {
      'action': 'battle_start',
      'first_turn_is_host': true,
    });
    _notify();
  }

  void attackCell(int r, int c) {
    if (!_myTurn || _phase != _Phase.attacking) return;
    if (_trackGrid[r][c] != null) return; // already attacked

    _myTurn = false;
    _statusText = 'Đang chờ kết quả...';
    _notify();

    gameProvider.sendGameData(gameId, {
      'action': 'attack_coord',
      'r': r,
      'c': c,
    });
  }

  void _processAttack(int r, int c, String attackerId) {
    // attackerId is attacker's player id
    // Check against opponent's grid
    final List<List<int>> targetGrid;
    if (attackerId == gameProvider.lobbyProvider.players.firstWhere((p) => p.isHost).id) {
      targetGrid = _oppGrid; // host attacked client's grid
    } else {
      targetGrid = _myGrid; // client attacked host's grid
    }

    final isHit = targetGrid[r][c] == 1;
    if (isHit) targetGrid[r][c] = 2;

    HapticFeedback.mediumImpact();

    // Check if all ships sunk for target
    final ships = _shipsFromGrid(targetGrid);
    final allSunk = ships.every((s) => s.every((cell) => targetGrid[cell.r][cell.c] == 2));

    gameProvider.sendGameData(gameId, {
      'action': 'attack_result',
      'r': r,
      'c': c,
      'hit': isHit,
      'sunk': allSunk,
      'attacker_id': attackerId,
    });

    if (allSunk) {
      _scores[attackerId] = 100;
      _finishGame(winnerId: attackerId);
    }
  }

  List<List<_Cell>> _shipsFromGrid(List<List<int>> grid) {
    // Returns list of ships as list of cells (where value != 0)
    // Simple: just return all non-zero cells grouped — good enough for sunk check
    final result = <List<_Cell>>[];
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (grid[r][c] == 1 || grid[r][c] == 2) {
          result.add([_Cell(r, c)]); // simple — each cell is its own "ship" for sunk check
        }
      }
    }
    return result;
  }

  void _finishGame({required String winnerId}) {
    if (_gameOver) return;
    _gameOver = true;
    _phase = _Phase.gameOver;

    gameProvider.sendGameData(gameId, {
      'action': 'game_over',
      'winner_id': winnerId,
      'scores': Map<String, dynamic>.from(_scores),
    });

    _statusText = 'Trận chiến kết thúc!';
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(Map.from(_scores));
    });
  }

  // ── Network ───────────────────────────────────────────────────────────────

  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'place_ships':
        if (gameProvider.lobbyProvider.isHost) {
          // Client sent their grid — store it
          final flat = (payload['grid'] as List).cast<int>();
          for (int r = 0; r < _gridSize; r++) {
            for (int c = 0; c < _gridSize; c++) {
              _oppGrid[r][c] = flat[r * _gridSize + c];
            }
          }
          if (_phase == _Phase.waiting) _startAttackPhase();
        }

      case 'battle_start':
        _phase = _Phase.attacking;
        final firstIsHost = payload['first_turn_is_host'] as bool;
        _myTurn = gameProvider.lobbyProvider.isHost ? firstIsHost : !firstIsHost;
        _statusText = _myTurn ? 'Lượt bạn — chọn ô tấn công!' : 'Đợi đối thủ tấn công...';
        _notify();

      case 'attack_coord':
        if (gameProvider.lobbyProvider.isHost) {
          _processAttack(
            payload['r'] as int,
            payload['c'] as int,
            senderId,
          );
        }

      case 'attack_result':
        final r = payload['r'] as int;
        final c = payload['c'] as int;
        final hit = payload['hit'] as bool;
        final sunk = payload['sunk'] as bool;
        final attackerId = payload['attacker_id'] as String;
        final iMeAttacker = attackerId == gameProvider.lobbyProvider.localPlayer?.id;

        if (iMeAttacker) {
          _trackGrid[r][c] = hit;
          _resultText = hit ? (sunk ? '💥 Đánh chìm!' : '🎯 Trúng!') : '💧 Hụt!';
        } else {
          _myGrid[r][c] = hit ? 2 : 3;
          _resultText = hit ? '💥 Tàu bạn bị trúng!' : '💨 Đối thủ hụt!';
        }

        hit ? AppAudio.playGoal() : AppAudio.playTap();
        HapticFeedback.mediumImpact();

        // Pass turn
        if (!sunk) {
          _myTurn = !iMeAttacker;
          _statusText = _myTurn ? 'Lượt bạn — chọn ô tấn công!' : 'Đợi đối thủ...';
        }
        _notify();

      case 'game_over':
        if (!_gameOver) {
          _gameOver = true;
          _phase = _Phase.gameOver;
          final winnerId = payload['winner_id'] as String;
          final raw = payload['scores'] as Map;
          raw.forEach((k, v) => _scores[k.toString()] = (v as num).toInt());
          final iWin = winnerId == gameProvider.lobbyProvider.localPlayer?.id;
          _statusText = iWin ? '🏆 Bạn thắng!' : '😢 Bạn thua!';
          _notify();
          Future.delayed(const Duration(seconds: 2), () {
            if (!_cancelled) endMiniGame(Map.from(_scores));
          });
        }
    }
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  Widget buildOverlay(BuildContext context) =>
      _BattleshipOverlay(game: this);
}

// ── Data types ─────────────────────────────────────────────────────────────

enum _Phase { placement, waiting, attacking, gameOver }

class _Cell {
  final int r, c;
  const _Cell(this.r, this.c);
  @override
  bool operator ==(Object other) =>
      other is _Cell && other.r == r && other.c == c;
  @override
  int get hashCode => r * 100 + c;
}

class _Ship {
  final int index, size;
  final List<_Cell> cells;
  const _Ship({required this.index, required this.size, required this.cells});
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _BattleshipOverlay extends StatefulWidget {
  final BattleshipGame game;
  const _BattleshipOverlay({required this.game});

  @override
  State<_BattleshipOverlay> createState() => _BattleshipOverlayState();
}

class _BattleshipOverlayState extends State<_BattleshipOverlay> {
  _Cell? _hoverCell;

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: switch (g._phase) {
          _Phase.placement || _Phase.waiting => _PlacementView(
              game: g,
              hoverCell: _hoverCell,
              onHover: (c) => setState(() => _hoverCell = c),
            ),
          _Phase.attacking || _Phase.gameOver => _AttackView(game: g),
        },
      ),
    );
  }
}

// ── Placement view ─────────────────────────────────────────────────────────

class _PlacementView extends StatelessWidget {
  final BattleshipGame game;
  final _Cell? hoverCell;
  final ValueChanged<_Cell?> onHover;

  const _PlacementView({
    required this.game,
    required this.hoverCell,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final preview = hoverCell != null
        ? game._previewPlacement(hoverCell!.r, hoverCell!.c)
        : null;
    final previewValid = preview != null;
    final previewCells = preview ?? const <_Cell>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  game.statusText,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (game._phase == _Phase.placement)
                GestureDetector(
                  onTap: game.toggleOrientation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(game.horizontal ? Icons.swap_horiz : Icons.swap_vert,
                            color: primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          game.horizontal ? 'Ngang' : 'Dọc',
                          style: TextStyle(color: primary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AspectRatio(
              aspectRatio: 1,
              child: _Grid(
                size: BattleshipGame._gridSize,
                cellBuilder: (r, c) {
                  final cell = _Cell(r, c);
                  final val = game._myGrid[r][c];
                  final isPreview = previewCells.contains(cell);
                  final isShip = val == 1;

                  Color bg;
                  if (isPreview) {
                    bg = previewValid
                        ? primary.withValues(alpha: 0.5)
                        : Colors.red.withValues(alpha: 0.4);
                  } else if (isShip) {
                    bg = primary.withValues(alpha: 0.7);
                  } else {
                    bg = const Color(0xFF1A2A3A);
                  }

                  return GestureDetector(
                    onTap: game._phase == _Phase.placement
                        ? () => game.placeship(r, c)
                        : null,
                    onTapDown: game._phase == _Phase.placement
                        ? (_) => onHover(cell)
                        : null,
                    onTapCancel: () => onHover(null),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Ship dock
        if (game._phase == _Phase.placement) ...[
          const SizedBox(height: 8),
          _ShipDock(game: game),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: game._ships.length >= BattleshipGame._shipSizes.length
                    ? game.confirmPlacement
                    : null,
                child: const Text('Xác Nhận ✓'),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ShipDock extends StatelessWidget {
  final BattleshipGame game;
  const _ShipDock({required this.game});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(BattleshipGame._shipSizes.length, (i) {
        final size = BattleshipGame._shipSizes[i];
        final placed = game._ships.any((s) => s.index == i);
        final selected = game.selectedShipIndex == i;

        return GestureDetector(
          onTap: () => game.selectShipToPlace(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? primary
                    : placed
                        ? Colors.green.withValues(alpha: 0.6)
                        : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                size,
                (_) => Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: placed
                        ? Colors.green.withValues(alpha: 0.5)
                        : selected
                            ? primary
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Attack view ────────────────────────────────────────────────────────────

class _AttackView extends StatelessWidget {
  final BattleshipGame game;
  const _AttackView({required this.game});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Column(
      children: [
        // Status bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(
                game.statusText,
                style: TextStyle(
                  color: game._myTurn ? primary : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (game.resultText.isNotEmpty)
                Text(
                  game.resultText,
                  style: TextStyle(
                    color: game.resultText.contains('Trúng') ||
                            game.resultText.contains('chìm') ||
                            game.resultText.contains('thắng')
                        ? secondary
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        // Attack grid (top)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Chiến trường đối thủ',
                    style: TextStyle(color: primary, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _Grid(
                      size: BattleshipGame._gridSize,
                      cellBuilder: (r, c) {
                        final result = game._trackGrid[r][c];
                        return GestureDetector(
                          onTap: game._myTurn && result == null
                              ? () => game.attackCell(r, c)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: result == null
                                  ? const Color(0xFF0A1A2A)
                                  : result
                                      ? const Color(0xFFE53935).withValues(alpha: 0.7)
                                      : const Color(0xFF1A3A5A),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: game._myTurn && result == null
                                    ? primary.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: result == null
                                  ? null
                                  : Text(
                                      result ? '💥' : '•',
                                      style: TextStyle(
                                        fontSize: result ? 9 : 12,
                                        color: result ? null : Colors.blue.shade300,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // My fleet mini-grid (bottom)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    'Hạm đội của bạn',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _Grid(
                      size: BattleshipGame._gridSize,
                      cellBuilder: (r, c) {
                        final val = game._myGrid[r][c];
                        return Container(
                          margin: const EdgeInsets.all(0.5),
                          decoration: BoxDecoration(
                            color: switch (val) {
                              1 => primary.withValues(alpha: 0.5),
                              2 => Colors.red.withValues(alpha: 0.7),
                              3 => const Color(0xFF1A2A3A),
                              _ => const Color(0xFF0D1A25),
                            },
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: val == 2
                              ? const Center(
                                  child: Text('✕',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 8)),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Reusable Grid ──────────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  final int size;
  final Widget Function(int r, int c) cellBuilder;
  const _Grid({required this.size, required this.cellBuilder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
      ),
      itemCount: size * size,
      itemBuilder: (_, i) => cellBuilder(i ~/ size, i % size),
    );
  }
}
