import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../../../lobby/domain/player.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

enum TodPhase { waiting, cardShown, responded, result, gameOver }

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
    'Điều gì bạn đã làm mà nếu cha mẹ biết họ sẽ rất buồn?',
    'Bạn đã từng cảm thấy ghen tị với ai trong nhóm này không?',
    'Lần gần nhất bạn thực sự khóc một mình là bao giờ?',
    'Bạn có bí mật nào mà bạn nghĩ sẽ không bao giờ kể với ai không?',
    'Điều tồi tệ nhất bạn từng nghĩ về một người bạn thân?',
    'Nếu có thể xóa 1 kỷ niệm, bạn sẽ xóa cái gì?',
    'Bạn đã từng thích ai trong nhóm này không (hiện tại hoặc quá khứ)?',
    'Điều bạn giả vờ thích nhưng thực ra không thích là gì?',
    'Lần cuối bạn nói dối để bảo vệ ai đó là khi nào?',
    'Bạn có kế hoạch bí mật nào mà chưa ai biết không?',
    'Điều bạn hối tiếc nhất trong 1 năm gần đây là gì?',
    'Thứ gì trên điện thoại của bạn mà bạn sẽ xấu hổ nếu ai đó thấy?',
    'Bạn nghĩ người nào trong nhóm phù hợp với bạn nhất không phải là bạn bè?',
    'Bạn đã từng giả vờ thích quà của ai đó dù thực ra không thích không?',
    'Mô tả lần bạn cảm thấy cô đơn nhất trong 2 năm qua.',
  ];

  static const List<String> _truthCardsEn = [
    'When was the last time you lied and to whom?',
    'What is the biggest secret you have not shared with anyone in this group?',
    'Who is your current crush?',
    'What is the most embarrassing thing you have ever done in public?',
    'Have you ever looked through someone else\'s phone without permission?',
    'What was the last thing that made you cry?',
    'What is the one thing you hate most about yourself?',
    'Who do you find the most attractive person in this group?',
    'What is the strangest thing you have ever searched on Google?',
    'Have you ever talked bad about anyone in this group?',
    'What is the dumbest thing you have ever done for someone?',
    'What is your most embarrassing memory?',
    'Who in this group do you think has the most secrets?',
    'What is the one thing from your past you wish you could change?',
    'Who in this group do you like the most and why?',
    'Have you ever faked being sick to skip something?',
    'What app do you delete when handing your phone to someone?',
    'What is something about you that few people in this group know?',
    'When was the last time you did something your parents do not know about?',
    'If you could read one person\'s mind in this group, whose would it be?',
    'What have you done that would deeply disappoint your parents if they knew?',
    'Have you ever felt jealous of anyone in this group?',
    'When was the last time you truly cried alone?',
    'Do you have a secret you think you will never tell anyone?',
    'What is the worst thought you have ever had about a close friend?',
    'If you could erase one memory, what would it be?',
    'Have you ever had a crush on anyone in this group — past or present?',
    'What is something you pretend to like but actually do not?',
    'When was the last time you lied to protect someone?',
    'Do you have any secret plans that nobody knows about?',
    'What is your biggest regret from the past year?',
    'What is on your phone that you would be embarrassed if someone saw?',
    'Who in this group do you think would be more than just a friend?',
    'Have you ever pretended to like a gift even though you did not?',
    'Describe the loneliest moment you have felt in the past two years.',
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
    'Làm mặt xấu nhất có thể và giữ trong 10 giây',
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
    'Làm 5 lần push-up ngay bây giờ (nếu không được thì uống)',
    'Gọi tên pet name yêu thích và gọi người bên trái bằng tên đó cả vòng này',
    'Mô tả cảm xúc của bạn bằng âm thanh — không dùng chữ — trong 15 giây',
    'Thực hiện 3 kiểu chào hỏi khác nhau với 3 người trong nhóm',
    'Đặt điện thoại xuống và không sờ vào trong 15 phút tiếp theo',
    'Nói chuyện bằng giọng siêu nhân cho đến vòng tiếp theo',
    'Chụp ảnh mặt ngốc nhất và đặt làm ảnh đại diện zalo/fb trong 10 phút',
    'Gọi điện ngẫu nhiên cho 1 người trong danh bạ và nói "Em nhớ anh/chị"',
    'Nhờ người ngồi bên phải viết gì đó lên mặt bạn bằng bút',
    'Giữ biểu cảm nghiêm trang nhất trong 2 phút, ai làm bạn cười thì bạn uống',
    'Làm một bài thơ ngẫu hứng về người ngồi đối diện trong 30 giây',
    'Thực hiện nghi thức bắt tay bí mật với người ngồi bên cạnh, cả nhóm học theo',
    'Nói 3 điều thật lòng bạn đánh giá cao về người vừa chọn bạn',
    'Điều khiển điện thoại của người ngồi bên cạnh trong 30 giây (họ có thể canh)',
    'Đeo mắt kính hoặc dùng tay che một mắt cho đến hết vòng tiếp theo',
  ];

  static const List<String> _dareCardsEn = [
    'Imitate someone in the room for 30 seconds',
    'Call someone and sing a song for 20 seconds',
    'Do 10 squats right now',
    'Say one honest thing to the person on your right',
    'Speak like a robot for the next minute',
    'Tell a joke — if no one laughs you drink more',
    'Dance freely for 30 seconds',
    'Give everyone a funny nickname',
    'Make the ugliest face possible and hold it for 10 seconds',
    'Imitate your favorite animal',
    'Say 5 things you like about the person across from you',
    'Read out the last text message you received',
    'Sing one line from whatever song is stuck in your head',
    'Do the most difficult yoga pose you know',
    'Tell a joke in a different accent',
    'Describe your ideal crush in 30 seconds',
    'Say "I love you" in the funniest voice possible',
    'Stand still like a statue for 1 minute — everyone tries to make you laugh',
    'Give the person next to you a shoulder massage for 1 minute',
    'Say what you truly think about the person on your left',
    'Do 5 push-ups right now (or drink if you can\'t)',
    'Give the person on your left a cute pet name and call them by it this round',
    'Express your current emotion using only sounds — no words — for 15 seconds',
    'Greet 3 different people in 3 completely different ways',
    'Put your phone down and do not touch it for the next 15 minutes',
    'Speak in a superhero voice until the next round',
    'Take the goofiest photo you can and set it as your profile picture for 10 minutes',
    'Call a random contact and say "I miss you so much"',
    'Let the person on your right write something on your face with a pen',
    'Keep the most serious expression you can for 2 minutes — drink if you laugh',
    'Compose an improvised poem about the person across from you in 30 seconds',
    'Create a secret handshake with the person next to you — everyone must learn it',
    'Say 3 genuine things you appreciate about the person who chose you',
    'Take control of the phone of the person next to you for 30 seconds (they can watch)',
    'Wear glasses or cover one eye for the rest of this round',
  ];

  TruthOrDareGame(super.gameProvider);

  @override
  String get gameId => GameIds.truthOrDare;

  bool get _isEnglish =>
      PlatformDispatcher.instance.locale.languageCode == 'en';

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  TodPhase _phase = TodPhase.waiting;
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
  TodPhase get phase => _phase;
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
      _phase == TodPhase.cardShown;

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
    final truthList = _isEnglish ? _truthCardsEn : _truthCards;
    final dareList = _isEnglish ? _dareCardsEn : _dareCards;
    final cards = isTruth ? truthList : dareList;
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
    _phase = TodPhase.cardShown;
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
    _phase = TodPhase.responded;
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
    _phase = TodPhase.result;
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
        _phase = TodPhase.waiting;
        _notify();
      }
    });
  }

  void _endGame() {
    _gameOver = true;
    _phase = TodPhase.gameOver;
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
          _phase = TodPhase.responded;
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
    if (widget.game.phase == TodPhase.cardShown) {
      _cardCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final l10n = AppLocalizations.of(context)!;
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
            if (g.phase == TodPhase.waiting)
              Expanded(child: _WaitingPane(label: l10n.todWaiting))
            else ...[
              _PlayerChip(label: l10n.todChosen(g.chosenPlayerName)),
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
                      truthLabel: l10n.todTruthLabel,
                      dareLabel: l10n.todDareLabel,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (g.phase == TodPhase.cardShown && g.isMyTurn)
                _ActionRow(
                  acceptLabel: l10n.todAcceptBtn,
                  skipLabel: l10n.todSkipBtn,
                  onAccept: () => g.respond(true),
                  onSkip: () => g.respond(false),
                )
              else if (g.phase == TodPhase.result ||
                  g.phase == TodPhase.responded)
                _ResultBanner(
                  completed: g.completed ?? false,
                  acceptedText: l10n.todAccepted,
                  skippedText: l10n.todSkipped,
                )
              else if (g.phase == TodPhase.cardShown && !g.isMyTurn)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.todWaitingForPlayer(g.chosenPlayerName),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              const SizedBox(height: 12),
              _ScoreRow(
                scores: g.scores,
                players: g.gameProvider.lobbyProvider.players,
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.gameRoundLabel(round + 1, total),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.todGameTitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String label;
  const _PlayerChip({required this.label});

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
        label,
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
  final TodPhase phase;
  final String truthLabel;
  final String dareLabel;

  const _CardWidget({
    required this.isTruth,
    required this.cardColor,
    required this.text,
    required this.timeLeft,
    required this.timeout,
    required this.phase,
    required this.truthLabel,
    required this.dareLabel,
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
                isTruth ? truthLabel : dareLabel,
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
              if (phase == TodPhase.cardShown)
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
  final String acceptLabel;
  final String skipLabel;
  final VoidCallback onAccept;
  final VoidCallback onSkip;
  const _ActionRow({
    required this.acceptLabel,
    required this.skipLabel,
    required this.onAccept,
    required this.onSkip,
  });

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
              label: Text(
                acceptLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
              label: Text(
                skipLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
  final String acceptedText;
  final String skippedText;
  const _ResultBanner({
    required this.completed,
    required this.acceptedText,
    required this.skippedText,
  });

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
        completed ? acceptedText : skippedText,
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.pointsText(score),
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
  final String label;
  const _WaitingPane({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎴', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
