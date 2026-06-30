import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import 'package:party_game_hub/l10n/app_localizations.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

enum SpinPhase { waiting, spinning, result, gameOver }

/// Vòng Quay Số Phận — bánh xe quay chọn ngẫu nhiên ai trong nhóm.
///
/// Mỗi vòng Host quay bánh xe, nó dừng ngẫu nhiên tại một người và hiển thị
/// nhiệm vụ vui. 10 vòng, mọi người đều vui — không ai thua!
class SpinPickerGame extends BaseMiniGame {
  static const int _totalRounds = 10;

  static const List<String> _tasks = [
    '🍺 Uống 1 ngụm',
    '🤫 Kể 1 bí mật nhỏ của bạn',
    '🎵 Hát 1 câu bất kỳ ngay bây giờ',
    '💪 Làm 10 cái squat ngay bây giờ',
    '😄 Nói điều bạn thích nhất về người ngồi bên phải',
    '🎭 Bắt chước 1 người trong phòng — mọi người đoán ai',
    '💃 Nhảy tự do 20 giây',
    '😂 Kể chuyện cười — không ai cười thì uống thêm',
    '🍺🍺 Uống 2 ngụm',
    '📱 Đọc to tin nhắn cuối cùng bạn nhận được',
    '🤗 Ôm tất cả mọi người trong phòng',
    '😜 Đặt biệt danh hài hước cho người ngồi bên trái',
    '🙈 Mô tả crush lý tưởng của bạn trong 30 giây',
    '🍺🍺🍺 Uống 3 ngụm (hoặc chọn người uống thay)',
    '🎤 Hát bài yêu thích theo kiểu opera',
    '🙏 Nói lời xin lỗi ai đó trong nhóm mà bạn nợ',
    '📸 Đổi ảnh đại diện mạng xã hội thành ảnh buồn cười nhất có thể',
    '🤡 Làm mặt hề trong 15 giây',
    '👑 Chọn 1 người phải uống cùng bạn',
    '💬 Nói điều thật sự nghĩ về người ngồi đối diện',
    '🎤 Hát bài quốc ca với giọng opera',
    '🤸 Đứng 1 chân trong 30 giây không được té',
    '👁️ Nhìn vào mắt người bên cạnh 10 giây không cười',
    '🎭 Diễn tả 1 bộ phim không nói — mọi người đoán',
    '💌 Đọc to lời yêu thương gửi đến người ngồi đối diện',
    '🚶 Đi lại trong phòng theo kiểu catwalk 20 giây',
    '🔢 Đếm ngược từ 50 càng nhanh càng tốt',
    '💃 Dạy mọi người 1 điệu nhảy trong 30 giây',
    '🎯 Tung đồ vật lên và bắt được 5 lần liên tiếp',
    '📸 Pose ảnh đẹp nhất có thể trong 5 giây',
    '🍺🍺🍺🍺 Uống 4 ngụm — xứng đáng là vua tiệc!',
    '💋 Mô tả nụ hôn đầu tiên của bạn',
    '🛁 Kể trải nghiệm ngại nhất khi ở nhà người khác',
    '🤫 Tiết lộ 1 điều bạn chưa bao giờ nói với ai trong nhóm',
    '😏 Mô tả kiểu người bạn thích trong 15 giây',
    '🎰 Chọn 2 người phải uống cùng bạn ngay bây giờ',
    '🙊 Đọc to tin nhắn lãng mạn nhất trong điện thoại của bạn',
    '👗 Mặc đồ ngược hoặc lộn trong 2 vòng tiếp theo',
    '🤦 Mô tả khoảnh khắc xấu hổ nhất của bạn năm nay',
    '💸 Cho biết bạn chi tiêu nhiều nhất vào việc gì từ trước đến nay',
  ];

  static const List<String> _tasksEn = [
    '🍺 Take 1 sip',
    '🤫 Share 1 small secret of yours',
    '🎵 Sing any one line right now',
    '💪 Do 10 squats right now',
    '😄 Say the thing you like most about the person on your right',
    '🎭 Imitate someone in the room — everyone guesses who',
    '💃 Dance freely for 20 seconds',
    '😂 Tell a joke — if no one laughs you drink more',
    '🍺🍺 Take 2 sips',
    '📱 Read out the last text message you received',
    '🤗 Hug everyone in the room',
    '😜 Give a funny nickname to the person on your left',
    '🙈 Describe your ideal crush in 30 seconds',
    '🍺🍺🍺 Take 3 sips (or pick someone to drink for you)',
    '🎤 Sing your favorite song in an opera voice',
    '🙏 Apologize to someone in the group you owe an apology to',
    '📸 Change your social media profile picture to the funniest photo you can take',
    '🤡 Make a clown face for 15 seconds',
    '👑 Pick 1 person who must drink with you',
    '💬 Say what you truly think about the person across from you',
    '🎤 Sing the national anthem in an opera voice',
    '🤸 Balance on one leg for 30 seconds without falling',
    '👁️ Stare into the eyes of the person next to you for 10 seconds without laughing',
    '🎭 Act out a movie without speaking — everyone guesses',
    '💌 Read out a loving message to the person across from you',
    '🚶 Walk across the room like a catwalk model for 20 seconds',
    '🔢 Count down from 50 as fast as you can',
    '💃 Teach everyone a dance move in 30 seconds',
    '🎯 Toss something up and catch it 5 times in a row',
    '📸 Strike your best pose in 5 seconds',
    '🍺🍺🍺🍺 Drink 4 sips — the king of the party!',
    '💋 Describe your first kiss',
    '🛁 Share your most embarrassing moment at someone else\'s house',
    '🤫 Reveal one thing you\'ve never told anyone in this group',
    '😏 Describe your ideal type in 15 seconds',
    '🎰 Pick 2 people who must drink with you right now',
    '🙊 Read aloud the most romantic text in your phone',
    '👗 Wear your clothes backwards or inside-out for the next 2 rounds',
    '🤦 Describe your most embarrassing moment this year',
    '💸 Share the most money you\'ve ever spent on something embarrassing',
  ];

  SpinPickerGame(super.gameProvider);

  @override
  String get gameId => GameIds.spinPicker;

  bool get _isEnglish =>
      PlatformDispatcher.instance.locale.languageCode == 'en';

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  SpinPhase _phase = SpinPhase.waiting;
  String? _winnerId;
  String _taskText = '';
  bool _gameOver = false;

  void _notify() => notifyOverlay();

  // ── Getters ────────────────────────────────────────────────────────────────
  int get round => _round;
  int get totalRounds => _totalRounds;
  SpinPhase get phase => _phase;
  String? get winnerId => _winnerId;
  String get taskText => _taskText;
  bool get isGameOver => _gameOver;

  bool get isWinner =>
      _winnerId != null &&
      _winnerId == gameProvider.lobbyProvider.localPlayer?.id;

  String get winnerName =>
      _winnerId != null ? playerNameFor(_winnerId!) : '?';

  List<String> get playerNames =>
      gameProvider.lobbyProvider.players.map((p) => p.name).toList();

  int get winnerIndex {
    final players = gameProvider.lobbyProvider.players;
    return players.indexWhere((p) => p.id == _winnerId);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (gameProvider.lobbyProvider.isHost) {
      Future.delayed(const Duration(milliseconds: 800), _spinRound);
    }
  }

  void _spinRound() {
    if (_gameOver || cancelled) return;
    final players = gameProvider.lobbyProvider.players;
    final rng = Random();
    final winner = players[rng.nextInt(players.length)];
    final taskList = _isEnglish ? _tasksEn : _tasks;
    final task = taskList[rng.nextInt(taskList.length)];

    gameProvider.sendGameData(gameId, {
      'action': 'spin_result',
      'round': _round,
      'winner_id': winner.id,
      'task': task,
    });
    _applySpinResult(_round, winner.id, task);
  }

  void _applySpinResult(int round, String winnerId, String task) {
    _round = round;
    _winnerId = winnerId;
    _taskText = task;
    _phase = SpinPhase.spinning;
    AppAudio.playTap();
    _notify();

    // Spin animation duration = 3s, then show result
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (cancelled) return;
      _phase = SpinPhase.result;
      AppAudio.playGoal();
      HapticFeedback.heavyImpact();
      _notify();

      // Auto advance after 5s
      Future.delayed(const Duration(seconds: 5), () {
        if (cancelled) return;
        _round++;
        if (_round >= _totalRounds) {
          _endGame();
        } else if (gameProvider.lobbyProvider.isHost) {
          _spinRound();
        } else {
          _phase = SpinPhase.waiting;
          _notify();
        }
      });
    });
  }

  void _endGame() {
    _gameOver = true;
    _phase = SpinPhase.gameOver;
    AppAudio.playWin();
    // Everyone gets 50 pts — it's a party, everyone wins
    final scores = <String, int>{
      for (final p in gameProvider.lobbyProvider.players) p.id: 50,
    };
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(scores);
    });
  }

  // ── Network ────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'spin_result':
        _applySpinResult(
          payload['round'] as int,
          payload['winner_id'] as String,
          payload['task'] as String,
        );
    }
  }


  Widget buildOverlay(BuildContext context) => _SpinPickerOverlay(game: this);
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _SpinPickerOverlay extends StatefulWidget {
  final SpinPickerGame game;
  const _SpinPickerOverlay({required this.game});

  @override
  State<_SpinPickerOverlay> createState() => _SpinPickerOverlayState();
}

class _SpinPickerOverlayState extends State<_SpinPickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late Animation<double> _spinAngle;

  @override
  void initState() {
    super.initState();
    widget.game.onStateChanged = _rebuild;
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _spinAngle = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    widget.game.onStateChanged = null;
    _spinCtrl.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    if (widget.game.phase == SpinPhase.spinning) {
      _startSpin();
    }
    setState(() {});
  }

  void _startSpin() {
    final g = widget.game;
    final playerCount = g.playerNames.length;
    if (playerCount == 0) return;

    final segmentAngle = (2 * pi) / playerCount;
    final winnerIdx = g.winnerIndex.clamp(0, playerCount - 1);
    // Winner at top = subtract half segment + winner offset
    final landAngle = -(winnerIdx * segmentAngle) - (segmentAngle / 2);
    // Add multiple full rotations for nice spin effect
    final extraSpins = (3 + Random().nextInt(3)) * 2 * pi;
    _spinAngle = Tween<double>(
      begin: _spinAngle.value,
      end: _spinAngle.value + extraSpins + landAngle,
    ).animate(CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOut));
    _spinCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, g),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: g.phase == SpinPhase.result
                    ? _ResultPane(game: g, l10n: l10n)
                    : _WheelPane(game: g, spinAngle: _spinAngle, l10n: l10n),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, SpinPickerGame g) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.gameRoundLabel(g.round + 1, g.totalRounds),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            l10n.spinGameTitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WheelPane extends StatelessWidget {
  final SpinPickerGame game;
  final Animation<double> spinAngle;
  final AppLocalizations l10n;
  const _WheelPane({
    required this.game,
    required this.spinAngle,
    required this.l10n,
  });

  static const _segColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFFFFD700),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFE53935),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final names = game.playerNames;
    if (names.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('▼', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28)),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: spinAngle,
          builder: (context, _) {
            return Transform.rotate(
              angle: spinAngle.value,
              child: CustomPaint(
                size: const Size(280, 280),
                painter: _WheelPainter(names: names, colors: _segColors),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (game.phase == SpinPhase.waiting)
          Text(
            l10n.spinWaiting,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          )
        else
          Text(
            l10n.spinningText,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> names;
  final List<Color> colors;
  _WheelPainter({required this.names, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = (2 * pi) / names.length;

    for (int i = 0; i < names.length; i++) {
      final startAngle = i * segAngle - pi / 2;
      final color = colors[i % colors.length];

      // Segment fill
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        paint,
      );

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segAngle,
        true,
        borderPaint,
      );

      // Label
      final labelAngle = startAngle + segAngle / 2;
      final labelRadius = radius * 0.65;
      final labelPos = Offset(
        center.dx + labelRadius * cos(labelAngle),
        center.dy + labelRadius * sin(labelAngle),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: names[i].length > 8 ? '${names[i].substring(0, 7)}…' : names[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.13,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(labelAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawCircle(
      center,
      radius * 0.08,
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.names != names || old.colors != colors;
}

class _ResultPane extends StatelessWidget {
  final SpinPickerGame game;
  final AppLocalizations l10n;
  const _ResultPane({required this.game, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Text(
            game.winnerName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            game.taskText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (game.isWinner)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6584).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.spinYouAreIt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF6584),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.spinNextRoundAuto,
          style: const TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ],
    );
  }
}
