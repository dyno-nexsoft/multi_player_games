import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../domain/base_mini_game.dart';

/// Xúc Xắc Tố (Liar's Dice / Perudo-lite) — đối kháng ẩn thông tin.
///
/// Mỗi thiết bị lắc 5 viên xúc xắc bí mật (tổng 10 viên trong ván). Hai bên
/// luân phiên "ra giá" — tuyên bố có ít nhất N viên hiện mặt X trên TOÀN BỘ
/// xúc xắc. Đến lượt, người chơi có thể nâng giá hoặc hô "Tố!" (Liar). Khi tố,
/// cả hai lật xúc xắc: nếu thực tế đủ số → người tố thua; nếu thiếu → người ra
/// giá (nói dối) thua.
class LiarsDiceGame extends BaseMiniGame {
  static const String overlayKey = 'liars_dice_ui';
  static const int _dicePerPlayer = 5;
  static const int _totalDice = _dicePerPlayer * 2;

  LiarsDiceGame(super.gameProvider);

  @override
  String get gameId => 'liars_dice';

  // ── State ──────────────────────────────────────────────────────────────────
  late List<int> _myDice;
  String? _myId;
  String? _oppId;

  bool _myTurn = false;
  bool _gameOver = false;
  bool _cancelled = false;

  int? _bidQty;
  int? _bidFace;
  String? _bidBy;

  // Lật bài khi kết thúc
  List<int>? _revealMine;
  List<int>? _revealOpp;
  int _revealCount = 0;

  String _status = '';
  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Getters cho overlay ────────────────────────────────────────────────────
  List<int> get myDice => _myDice;
  bool get isMyTurn => _myTurn && !_gameOver;
  bool get isGameOver => _gameOver;
  String get statusText => _status;
  int? get bidQty => _bidQty;
  int? get bidFace => _bidFace;
  bool get hasOpponentBid => _bidQty != null && _bidBy == _oppId;
  int get totalDice => _totalDice;
  List<int>? get revealMine => _revealMine;
  List<int>? get revealOpp => _revealOpp;
  int get revealCount => _revealCount;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final rng = Random();
    _myDice = List.generate(_dicePerPlayer, (_) => rng.nextInt(6) + 1);

    final players = gameProvider.lobbyProvider.players;
    _myId = gameProvider.lobbyProvider.localPlayer?.id;
    _oppId = players
        .firstWhere((p) => p.id != _myId, orElse: () => players.first)
        .id;

    _myTurn = gameProvider.lobbyProvider.isHost;
    _status = _myTurn ? 'Lượt bạn — ra giá đầu tiên!' : 'Chờ đối thủ ra giá...';
    overlays.add(overlayKey);
  }

  /// Giá mới phải cao hơn: nhiều hơn về số lượng, hoặc cùng số lượng nhưng
  /// mặt lớn hơn.
  bool isValidRaise(int qty, int face) {
    if (qty < 1 || qty > _totalDice || face < 1 || face > 6) return false;
    if (_bidQty == null) return true;
    return qty > _bidQty! || (qty == _bidQty! && face > _bidFace!);
  }

  // ── Input từ overlay ────────────────────────────────────────────────────────
  void submitBid(int qty, int face) {
    if (!_myTurn || _gameOver || !isValidRaise(qty, face)) return;
    _bidQty = qty;
    _bidFace = face;
    _bidBy = _myId;
    _myTurn = false;
    _status = 'Bạn đặt: ≥$qty con mặt $face. Chờ đối thủ...';
    AppAudio.playTap();
    HapticFeedback.lightImpact();
    gameProvider.sendGameData(gameId, {
      'action': 'bid',
      'qty': qty,
      'face': face,
    });
    _notify();
  }

  void submitCall() {
    if (!_myTurn || _gameOver || !hasOpponentBid) return;
    _myTurn = false;
    _status = 'Bạn hô TỐ! Đang lật xúc xắc...';
    AppAudio.playTap();
    HapticFeedback.mediumImpact();
    gameProvider.sendGameData(gameId, {'action': 'call', 'dice': _myDice});
    _notify();
  }

  // ── Network ──────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    if (_gameOver) return;
    switch (payload['action'] as String?) {
      case 'bid':
        _bidQty = payload['qty'] as int;
        _bidFace = payload['face'] as int;
        _bidBy = _oppId;
        _myTurn = true;
        _status = 'Đối thủ: ≥$_bidQty con mặt $_bidFace. Tới lượt bạn.';
        _notify();

      case 'call':
        // Đối thủ tố giá CỦA MÌNH → mình là người ra giá, có đủ thông tin lật.
        final oppDice = (payload['dice'] as List).cast<int>();
        final all = [..._myDice, ...oppDice];
        final count = all.where((d) => d == _bidFace).length;
        final bidderTruthful = count >= _bidQty!;
        final loserId = bidderTruthful ? _oppId : _myId;
        gameProvider.sendGameData(gameId, {
          'action': 'result',
          'bidderDice': _myDice,
          'callerDice': oppDice,
          'count': count,
          'loser': loserId,
        });
        _revealMine = _myDice;
        _revealOpp = oppDice;
        _resolveEnd(loserId, count);

      case 'result':
        // Mình là người tố → bidderDice là của đối thủ.
        final bidderDice = (payload['bidderDice'] as List).cast<int>();
        final callerDice = (payload['callerDice'] as List).cast<int>();
        _revealMine = callerDice;
        _revealOpp = bidderDice;
        _resolveEnd(payload['loser'] as String?, payload['count'] as int);
    }
  }

  void _resolveEnd(String? loserId, int count) {
    if (_gameOver) return;
    _gameOver = true;
    _revealCount = count;
    final winnerId = loserId == _myId ? _oppId : _myId;
    final scores = <String, int>{};
    for (final p in gameProvider.lobbyProvider.players) {
      scores[p.id] = p.id == winnerId ? 100 : 0;
    }
    final iWon = winnerId == _myId;
    _status = iWon
        ? '🎉 Thắng! Thực tế có $count con mặt $_bidFace'
        : '😢 Thua! Thực tế có $count con mặt $_bidFace';
    iWon ? AppAudio.playWin() : AppAudio.playLose();
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(scores);
    });
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  Widget buildOverlay(BuildContext context) => _LiarsDiceOverlay(game: this);
}

// ── Overlay UI ────────────────────────────────────────────────────────────────
class _LiarsDiceOverlay extends StatefulWidget {
  final LiarsDiceGame game;
  const _LiarsDiceOverlay({required this.game});

  @override
  State<_LiarsDiceOverlay> createState() => _LiarsDiceOverlayState();
}

class _LiarsDiceOverlayState extends State<_LiarsDiceOverlay> {
  int _qty = 1;
  int _face = 1;
  bool _initDraft = false;

  static const _diceGlyphs = ['', '⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

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
    if (mounted) setState(() => _syncDraftToMinimum());
  }

  /// Khi tới lượt, nâng draft lên mức hợp lệ tối thiểu so với giá hiện tại.
  void _syncDraftToMinimum() {
    final g = widget.game;
    if (!g.isMyTurn) return;
    if (!_initDraft || !g.isValidRaise(_qty, _face)) {
      _initDraft = true;
      if (g.bidQty == null) {
        _qty = 1;
        _face = 2;
      } else if (g.bidFace! < 6) {
        _qty = g.bidQty!;
        _face = g.bidFace! + 1;
      } else {
        _qty = g.bidQty! + 1;
        _face = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Container(
      color: const Color(0xFF0D0D1A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🎲 Xúc xắc của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              _DiceRow(
                dice: g.myDice,
                glyphs: _diceGlyphs,
                highlight: g.bidFace,
              ),
              const SizedBox(height: 16),
              _CurrentBid(qty: g.bidQty, face: g.bidFace, glyphs: _diceGlyphs),
              const SizedBox(height: 12),
              Text(
                g.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: g.isMyTurn ? const Color(0xFFFFD700) : Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (g.isGameOver && g.revealOpp != null) ...[
                const Text(
                  'Đối thủ:',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                _DiceRow(
                  dice: g.revealOpp!,
                  glyphs: _diceGlyphs,
                  highlight: g.bidFace,
                ),
                const SizedBox(height: 16),
              ],
              if (!g.isGameOver) ...[
                _BidStepper(
                  qty: _qty,
                  face: _face,
                  glyphs: _diceGlyphs,
                  total: g.totalDice,
                  enabled: g.isMyTurn,
                  onQty: (v) => setState(() => _qty = v),
                  onFace: (v) => setState(() => _face = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (g.isMyTurn && g.isValidRaise(_qty, _face))
                            ? () => g.submitBid(_qty, _face)
                            : null,
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text('Nâng giá'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (g.isMyTurn && g.hasOpponentBid)
                            ? () => g.submitCall()
                            : null,
                        icon: const Icon(Icons.gavel, size: 18),
                        label: const Text('TỐ!'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6584),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiceRow extends StatelessWidget {
  final List<int> dice;
  final List<String> glyphs;
  final int? highlight;
  const _DiceRow({required this.dice, required this.glyphs, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dice.map((d) {
        final hot = highlight != null && d == highlight;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hot
                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hot
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.15),
              width: hot ? 2 : 1,
            ),
          ),
          child: Text(
            glyphs[d],
            style: const TextStyle(color: Colors.white, fontSize: 30),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrentBid extends StatelessWidget {
  final int? qty;
  final int? face;
  final List<String> glyphs;
  const _CurrentBid({
    required this.qty,
    required this.face,
    required this.glyphs,
  });

  @override
  Widget build(BuildContext context) {
    if (qty == null) {
      return const Text(
        'Chưa có giá',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white24, fontSize: 14),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'Giá hiện tại:  ≥ $qty  ×  ${glyphs[face!]}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BidStepper extends StatelessWidget {
  final int qty;
  final int face;
  final List<String> glyphs;
  final int total;
  final bool enabled;
  final ValueChanged<int> onQty;
  final ValueChanged<int> onFace;
  const _BidStepper({
    required this.qty,
    required this.face,
    required this.glyphs,
    required this.total,
    required this.enabled,
    required this.onQty,
    required this.onFace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stepper(
          label: 'Số lượng',
          value: '$qty',
          enabled: enabled,
          onMinus: qty > 1 ? () => onQty(qty - 1) : null,
          onPlus: qty < total ? () => onQty(qty + 1) : null,
        ),
        _Stepper(
          label: 'Mặt',
          value: glyphs[face],
          enabled: enabled,
          onMinus: face > 1 ? () => onFace(face - 1) : null,
          onPlus: face < 6 ? () => onFace(face + 1) : null,
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  const _Stepper({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              onPressed: enabled ? onMinus : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.white70,
            ),
            SizedBox(
              width: 44,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: enabled ? onPlus : null,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.white70,
            ),
          ],
        ),
      ],
    );
  }
}
