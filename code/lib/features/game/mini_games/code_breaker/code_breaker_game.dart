import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../domain/base_mini_game.dart';

/// Phá Mã (Bulls & Cows) — đối kháng ẩn thông tin thuần túy.
///
/// Mỗi thiết bị tự giữ một mã bí mật 4 chữ số khác nhau. Hai bên luân phiên
/// đoán mã của đối thủ; chủ mã chấm điểm 🎯 (đúng vị trí) / 🐂 (đúng số sai vị trí).
/// Ai đoán đủ 4 🎯 trước sẽ thắng. Không có dữ liệu bí mật nào rời thiết bị
/// trước khi kết thúc → không thể "soi" qua máy host.
class CodeBreakerGame extends BaseMiniGame {
  static const String overlayKey = 'code_breaker_ui';
  static const int _codeLen = 4;

  CodeBreakerGame(super.gameProvider);

  @override
  String get gameId => 'code_breaker';

  // ── State ──────────────────────────────────────────────────────────────────
  late List<int> _mySecret;
  String? _myId;
  String? _opponentId;

  bool _myTurn = false;
  bool _gameOver = false;
  bool _cancelled = false;

  /// Lịch sử đoán của mình (đoán mã đối thủ).
  final List<({List<int> guess, int bulls, int cows})> _history = [];

  /// Theo dõi nỗ lực của đối thủ (để tạo căng thẳng).
  int _oppGuessCount = 0;
  int _oppBestBulls = 0;

  String _status = '';
  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Getters cho overlay ────────────────────────────────────────────────────
  List<int> get mySecret => _mySecret;
  bool get isMyTurn => _myTurn && !_gameOver;
  bool get isGameOver => _gameOver;
  String get statusText => _status;
  List<({List<int> guess, int bulls, int cows})> get history => _history;
  int get opponentGuessCount => _oppGuessCount;
  int get opponentBestBulls => _oppBestBulls;
  int get codeLength => _codeLen;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _mySecret = _randomSecret();

    final players = gameProvider.lobbyProvider.players;
    _myId = gameProvider.lobbyProvider.localPlayer?.id;
    _opponentId = players
        .firstWhere((p) => p.id != _myId, orElse: () => players.first)
        .id;

    _myTurn = gameProvider.lobbyProvider.isHost;
    _status = _myTurn
        ? 'Lượt của bạn — đoán mã đối thủ!'
        : 'Chờ đối thủ đoán...';
    overlays.add(overlayKey);
  }

  static List<int> _randomSecret() {
    final digits = List.generate(10, (i) => i)..shuffle(Random());
    return digits.take(_codeLen).toList();
  }

  /// Chấm điểm: bulls = đúng số đúng vị trí, cows = đúng số sai vị trí.
  (int, int) _evaluate(List<int> guess, List<int> secret) {
    int bulls = 0, cows = 0;
    for (int i = 0; i < _codeLen; i++) {
      if (guess[i] == secret[i]) {
        bulls++;
      } else if (secret.contains(guess[i])) {
        cows++;
      }
    }
    return (bulls, cows);
  }

  // ── Input từ overlay ────────────────────────────────────────────────────────
  void submitGuess(List<int> guess) {
    if (!_myTurn || _gameOver) return;
    _myTurn = false;
    _status = 'Chờ phản hồi...';
    AppAudio.playTap();
    HapticFeedback.lightImpact();
    gameProvider.sendGameData(gameId, {'action': 'guess', 'digits': guess});
    _notify();
  }

  // ── Network ──────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    if (_gameOver) return;
    switch (payload['action'] as String?) {
      case 'guess':
        final digits = (payload['digits'] as List).cast<int>();
        final (bulls, cows) = _evaluate(digits, _mySecret);
        _oppGuessCount++;
        if (bulls > _oppBestBulls) _oppBestBulls = bulls;
        gameProvider.sendGameData(gameId, {
          'action': 'feedback',
          'digits': digits,
          'bulls': bulls,
          'cows': cows,
        });
        if (bulls == _codeLen) {
          // Đối thủ vừa phá mã của mình → đối thủ thắng.
          _finish(_opponentId);
        } else {
          _myTurn = true;
          _status = 'Lượt của bạn — đoán mã đối thủ!';
          _notify();
        }

      case 'feedback':
        final digits = (payload['digits'] as List).cast<int>();
        final bulls = payload['bulls'] as int;
        final cows = payload['cows'] as int;
        _history.insert(0, (guess: digits, bulls: bulls, cows: cows));
        if (bulls == _codeLen) {
          AppAudio.playWin();
          _finish(_myId); // mình vừa phá mã đối thủ
        } else {
          _status = 'Lượt đối thủ...';
          _notify();
        }
    }
  }

  void _finish(String? winnerId) {
    if (_gameOver) return;
    _gameOver = true;
    final scores = <String, int>{};
    for (final p in gameProvider.lobbyProvider.players) {
      scores[p.id] = p.id == winnerId ? 100 : 0;
    }
    _status = winnerId == _myId
        ? '🎉 Bạn đã phá mã đối thủ!'
        : '😢 Đối thủ phá mã trước!';
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

  Widget buildOverlay(BuildContext context) => _CodeBreakerOverlay(game: this);
}

// ── Overlay UI ────────────────────────────────────────────────────────────────
class _CodeBreakerOverlay extends StatefulWidget {
  final CodeBreakerGame game;
  const _CodeBreakerOverlay({required this.game});

  @override
  State<_CodeBreakerOverlay> createState() => _CodeBreakerOverlayState();
}

class _CodeBreakerOverlayState extends State<_CodeBreakerOverlay> {
  final List<int> _draft = [];

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

  void _tapDigit(int d) {
    if (!widget.game.isMyTurn) return;
    if (_draft.contains(d) || _draft.length >= widget.game.codeLength) return;
    setState(() => _draft.add(d));
  }

  void _backspace() {
    if (_draft.isEmpty) return;
    setState(() => _draft.removeLast());
  }

  void _submit() {
    if (_draft.length != widget.game.codeLength) return;
    widget.game.submitGuess(List.of(_draft));
    setState(() => _draft.clear());
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final canSubmit = game.isMyTurn && _draft.length == game.codeLength;

    return Container(
      color: const Color(0xFF0D0D1A),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mã bí mật của mình (đối thủ đang cố phá)
              _SecretBanner(
                secret: game.mySecret,
                oppGuesses: game.opponentGuessCount,
                oppBestBulls: game.opponentBestBulls,
                codeLen: game.codeLength,
              ),
              const SizedBox(height: 8),
              Text(
                game.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: game.isMyTurn
                      ? const Color(0xFFFFD700)
                      : Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Lịch sử đoán
              Expanded(
                child: game.history.isEmpty
                    ? const Center(
                        child: Text(
                          'Đoán mã 4 số khác nhau của đối thủ',
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: game.history.length,
                        itemBuilder: (_, i) {
                          final h = game.history[i];
                          return _GuessRow(
                            guess: h.guess,
                            bulls: h.bulls,
                            cows: h.cows,
                          );
                        },
                      ),
              ),
              // Ô nhập đang soạn
              if (!game.isGameOver) ...[
                _DraftRow(draft: _draft, codeLen: game.codeLength),
                const SizedBox(height: 8),
                _Keypad(
                  used: _draft,
                  enabled: game.isMyTurn,
                  onTap: _tapDigit,
                  onBackspace: _backspace,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    child: const Text('Đoán'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecretBanner extends StatelessWidget {
  final List<int> secret;
  final int oppGuesses;
  final int oppBestBulls;
  final int codeLen;
  const _SecretBanner({
    required this.secret,
    required this.oppGuesses,
    required this.oppBestBulls,
    required this.codeLen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🔐 ', style: TextStyle(fontSize: 16)),
              Text(
                secret.join(' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Text(
            'Đối thủ: $oppGuesses lần · 🎯$oppBestBulls/$codeLen',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GuessRow extends StatelessWidget {
  final List<int> guess;
  final int bulls;
  final int cows;
  const _GuessRow({
    required this.guess,
    required this.bulls,
    required this.cows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...guess.map(
            (d) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '$d',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '🎯$bulls  🐂$cows',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  final List<int> draft;
  final int codeLen;
  const _DraftRow({required this.draft, required this.codeLen});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(codeLen, (i) {
        final filled = i < draft.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.15),
              width: filled ? 2 : 1,
            ),
          ),
          child: Text(
            filled ? '${draft[i]}' : '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final List<int> used;
  final bool enabled;
  final ValueChanged<int> onTap;
  final VoidCallback onBackspace;
  const _Keypad({
    required this.used,
    required this.enabled,
    required this.onTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        ...List.generate(10, (d) {
          final isUsed = used.contains(d);
          final disabled = !enabled || isUsed;
          return SizedBox(
            width: 52,
            height: 44,
            child: ElevatedButton(
              onPressed: disabled ? null : () => onTap(d),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: isUsed
                    ? Colors.white10
                    : const Color(0xFF2D2D44),
              ),
              child: Text('$d', style: const TextStyle(fontSize: 18)),
            ),
          );
        }),
        SizedBox(
          width: 52,
          height: 44,
          child: ElevatedButton(
            onPressed: enabled ? onBackspace : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFF4A1515),
            ),
            child: const Icon(Icons.backspace_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}
