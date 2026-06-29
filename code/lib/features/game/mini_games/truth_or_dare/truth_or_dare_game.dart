import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../../lobby/domain/player.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Thật Hay Thách — party game nhiều người.
///
/// Mỗi vòng Host quay ngẫu nhiên chọn 1 người. Người đó nhận thẻ Sự Thật
/// (phải trả lời) hoặc Thách (phải làm). Họ có thể Chấp nhận (+10 điểm)
/// hoặc Bỏ qua (uống và mất điểm). 8 vòng tổng.
class TruthOrDareGame extends BaseMiniGame {
  static const int _totalRounds = 8;
  static const double _responseTimeout = 20.0;

  static const List<String> _truthCards = [
    'Lần cuối cùng bạn nói dối là khi nào và nói với ai?',
    'Bí mật lớn nhất bạn chưa kể với ai trong nhóm này?',
    'Crush hiện tại của bạn là ai?',
    'Điều xấu hổ nhất bạn từng làm trước mặt người khác?',
    'Bạn có bao giờ nhìn trộm điện thoại của người khác không?',
    'Lần gần nhất bạn khóc là vì điều gì?',
    'Điều bạn ghét nhất ở bản thân là gì?',
    'Bạn đánh giá ai trong nhóm này hấp dẫn nhất?',
    'Điều kỳ quặc nhất bạn từng tìm kiếm trên Google?',
    'Bạn đã từng nói xấu ai trong nhóm này chưa?',
    'Điều ngu ngốc nhất bạn từng làm vì ai đó là gì?',
    'Kỷ niệm đáng xấu hổ nhất của bạn là gì?',
    'Bạn nghĩ ai trong nhóm có nhiều bí mật nhất?',
    'Điều bạn muốn thay đổi về quá khứ nhất là gì?',
    'Bạn thích ai trong nhóm này nhất và tại sao?',
    'Bạn đã từng giả vờ bệnh để trốn việc chưa?',
    'App nào bạn hay xóa khi đưa điện thoại cho người khác?',
    'Điều gì về bạn mà ít người trong nhóm biết?',
    'Lần cuối bạn làm điều gì đó mà cha mẹ không biết?',
    'Nếu được đọc tâm trí 1 người trong nhóm, bạn chọn ai?',
  ];

  static const List<String> _dareCards = [
    'Nhái giọng một người trong phòng trong 30 giây',
    'Gọi điện cho ai đó và hát 1 bài trong 20 giây',
    'Làm 10 cái squat ngay bây giờ',
    'Nói thật lòng một điều với người ngồi bên phải',
    'Giả làm robot nói chuyện trong 1 phút tới',
    'Kể 1 truyện cười — không ai cười thì uống thêm',
    'Nhảy tự do trong 30 giây',
    'Đặt biệt danh hài hước cho tất cả mọi người',
    'Làm mặt xấu nhất và giữ trong 10 giây',
    'Bắt chước con vật yêu thích của bạn',
    'Nói 5 điều bạn thích ở người ngồi đối diện',
    'Đọc to tin nhắn cuối cùng bạn nhận được',
    'Hát 1 câu theo điệu bài nhạc bạn đang nghĩ trong đầu',
    'Thực hiện động tác yoga khó nhất bạn biết',
    'Kể chuyện cười bằng giọng địa phương khác',
    'Mô tả crush lý tưởng trong 30 giây',
    "Nói 'Tôi yêu bạn' với giọng thật buồn cười",
    'Đứng im như tượng 1 phút, mọi người cố làm bạn cười',
    'Massage vai cho người bên cạnh trong 1 phút',
    'Nói điều bạn thật sự nghĩ về người ngồi bên trái',
  ];

  TruthOrDareGame(super.gameProvider);

  @override
  String get gameId => GameIds.truthOrDare;

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  // phases: waiting | card_shown | responded | result | game_over
  String _phase = 'waiting';
  String? _chosenId;
  String _cardType = '';
  String _cardText = '';
  bool? _completed;
  double _timeLeft = _responseTimeout;
  bool _timerActive = false;
  bool _roundResultSent = false;
  bool _gameOver = false;
  Map<String, int> _scores = {};

  void _notify() => notifyOverlay();

  // ── Getters ────────────────────────────────────────────────────────────────
  int get round => _round;
  int get totalRounds => _totalRounds;
  String get phase => _phase;
  String? get chosenId => _chosenId;
  String get cardType => _cardType;
  String get cardText => _cardText;
  bool? get completed => _completed;
  double get timeLeft => _timeLeft;
  bool get isGameOver => _gameOver;
  Map<String, int> get scores => Map.unmodifiable(_scores);

  bool get isMyTurn =>
      _chosenId != null &&
      _chosenId == gameProvider.lobbyProvider.localPlayer?.id &&
      _phase == 'card_shown';

  String get chosenPlayerName =>
      _chosenId != null ? playerNameFor(_chosenId!) : '?';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final p in gameProvider.lobbyProvider.players) {
      _scores[p.id] = 0;
    }
    if (gameProvider.lobbyProvider.isHost) {
      Future.delayed(const Duration(seconds: 1), _startRound);
    }
  }

  void _startRound() {
    if (_gameOver || cancelled) return;
    final players = gameProvider.lobbyProvider.players;
    final rng = Random();
    final chosen = players[rng.nextInt(players.length)];
    final isTruth = rng.nextBool();
    final cards = isTruth ? _truthCards : _dareCards;
    final text = cards[rng.nextInt(cards.length)];
    final type = isTruth ? 'truth' : 'dare';

    gameProvider.sendGameData(gameId, {
      'action': 'new_round',
      'round': _round,
      'player_id': chosen.id,
      'card_type': type,
      'card_text': text,
    });
    _applyNewRound(_round, chosen.id, type, text);
  }

  void _applyNewRound(int round, String playerId, String type, String text) {
    _round = round;
    _chosenId = playerId;
    _cardType = type;
    _cardText = text;
    _completed = null;
    _phase = 'card_shown';
    _timeLeft = _responseTimeout;
    _timerActive = true;
    _roundResultSent = false;
    AppAudio.playTap();
    _notify();
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void respond(bool accepted) {
    if (!isMyTurn) return;
    _completed = accepted;
    _timerActive = false;
    _phase = 'responded';
    accepted ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    AppAudio.playTap();

    gameProvider.sendGameData(gameId, {
      'action': 'response',
      'player_id': _chosenId,
      'completed': accepted,
    });
    _notify();

    final chosen = _chosenId;
    if (gameProvider.lobbyProvider.isHost && chosen != null) {
      _processResponse(chosen, accepted);
    }
  }

  // ── Host authority ─────────────────────────────────────────────────────────
  void _processResponse(String playerId, bool completed) {
    if (_roundResultSent) return;
    _roundResultSent = true;
    _timerActive = false;

    if (completed) {
      _scores[playerId] = (_scores[playerId] ?? 0) + 10;
    }

    gameProvider.sendGameData(gameId, {
      'action': 'round_result',
      'player_id': playerId,
      'completed': completed,
      'scores': Map<String, dynamic>.from(_scores),
    });
    _applyRoundResult(playerId, completed, _scores);
  }

  void _applyRoundResult(
    String playerId,
    bool completed,
    Map<String, int> scores,
  ) {
    _scores = Map.from(scores);
    _completed = completed;
    _phase = 'result';
    _timerActive = false;
    completed ? AppAudio.playGoal() : AppAudio.playLose();
    _notify();

    Future.delayed(const Duration(seconds: 3), () {
      if (cancelled) return;
      _round++;
      if (_round >= _totalRounds) {
        _endGame();
      } else if (gameProvider.lobbyProvider.isHost) {
        _startRound();
      } else {
        _phase = 'waiting';
        _notify();
      }
    });
  }

  void _endGame() {
    _gameOver = true;
    _phase = 'game_over';
    _timerActive = false;
    AppAudio.playWin();
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(Map.from(_scores));
    });
  }

  int _lastTimerTick = -1;

  // ── Game loop ──────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_timerActive || _gameOver) return;
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _timerActive = false;
      final chosen = _chosenId;
      if (gameProvider.lobbyProvider.isHost && chosen != null) {
        _processResponse(chosen, false);
      }
    }
    // Only rebuild when the displayed second changes — avoids 60fps setState.
    final tick = _timeLeft.ceil();
    if (tick != _lastTimerTick) {
      _lastTimerTick = tick;
      _notify();
    }
  }

  // ── Network ────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'new_round':
        _applyNewRound(
          payload['round'] as int,
          payload['player_id'] as String,
          payload['card_type'] as String,
          payload['card_text'] as String,
        );

      case 'response':
        if (gameProvider.lobbyProvider.isHost) {
          _processResponse(
            payload['player_id'] as String,
            payload['completed'] as bool,
          );
        } else {
          _completed = payload['completed'] as bool;
          _phase = 'responded';
          _timerActive = false;
          _notify();
        }

      case 'round_result':
        final rawScores = payload['scores'] as Map;
        final scores = rawScores.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
        _applyRoundResult(
          payload['player_id'] as String,
          payload['completed'] as bool,
          scores,
        );
    }
  }


  Widget buildOverlay(BuildContext context) => _TruthOrDareOverlay(game: this);
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _TruthOrDareOverlay extends StatefulWidget {
  final TruthOrDareGame game;
  const _TruthOrDareOverlay({required this.game});

  @override
  State<_TruthOrDareOverlay> createState() => _TruthOrDareOverlayState();
}

class _TruthOrDareOverlayState extends State<_TruthOrDareOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardScale = CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    _cardCtrl.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {});
    if (widget.game.phase == 'card_shown') {
      _cardCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final isTruth = g.cardType == 'truth';
    final cardColor = isTruth
        ? const Color(0xFF6C63FF)
        : const Color(0xFFFF6584);

    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            _RoundHeader(round: g.round, total: g.totalRounds),
            const SizedBox(height: 12),
            if (g.phase == 'waiting')
              const Expanded(child: _WaitingPane())
            else ...[
              _PlayerChip(name: g.chosenPlayerName),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ScaleTransition(
                    scale: _cardScale,
                    child: _CardWidget(
                      isTruth: isTruth,
                      cardColor: cardColor,
                      text: g.cardText,
                      timeLeft: g.timeLeft,
                      timeout: TruthOrDareGame._responseTimeout,
                      phase: g.phase,
                      completed: g.completed,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (g.phase == 'card_shown' && g.isMyTurn)
                _ActionRow(
                  onAccept: () => g.respond(true),
                  onSkip: () => g.respond(false),
                )
              else if (g.phase == 'result' || g.phase == 'responded')
                _ResultBanner(completed: g.completed ?? false)
              else if (g.phase == 'card_shown' && !g.isMyTurn)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Chờ ${g.chosenPlayerName} trả lời...',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              const SizedBox(height: 12),
              _ScoreRow(scores: g.scores, players: g.gameProvider.lobbyProvider.players),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final int round;
  final int total;
  const _RoundHeader({required this.round, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Vòng ${round + 1}/$total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '🃏 Thật Hay Thách',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String name;
  const _PlayerChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '🎯  $name  được chọn!',
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CardWidget extends StatelessWidget {
  final bool isTruth;
  final Color cardColor;
  final String text;
  final double timeLeft;
  final double timeout;
  final String phase;
  final bool? completed;

  const _CardWidget({
    required this.isTruth,
    required this.cardColor,
    required this.text,
    required this.timeLeft,
    required this.timeout,
    required this.phase,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final timeRatio = (timeLeft / timeout).clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardColor.withValues(alpha: 0.6), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTruth ? '❓ SỰ THẬT' : '⭐ THÁCH',
                style: TextStyle(
                  color: cardColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              if (phase == 'card_shown')
                SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: timeRatio,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(Colors.red, cardColor, timeRatio)!,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onSkip;
  const _ActionRow({required this.onAccept, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Text('✅', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Chấp nhận',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onSkip,
              icon: const Text('🍺', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Uống & Bỏ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6584),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool completed;
  const _ResultBanner({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed
            ? const Color(0xFF43A047).withValues(alpha: 0.2)
            : const Color(0xFFFF6584).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? const Color(0xFF43A047).withValues(alpha: 0.5)
              : const Color(0xFFFF6584).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        completed ? '🎉 Hoàn thành! +10 điểm' : '🍺 Bỏ qua — phải uống!',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: completed ? const Color(0xFF81C784) : const Color(0xFFFF6584),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final Map<String, int> scores;
  final List<Player> players;
  const _ScoreRow({required this.scores, required this.players});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = players[i];
          final score = scores[p.id] ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  '$score đ',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WaitingPane extends StatelessWidget {
  const _WaitingPane();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎴', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text(
            'Đang chọn người...',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
