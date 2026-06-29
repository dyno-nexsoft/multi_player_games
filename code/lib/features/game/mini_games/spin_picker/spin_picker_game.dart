import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

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
  ];

  SpinPickerGame(super.gameProvider);

  @override
  String get gameId => GameIds.spinPicker;

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  // phases: waiting | spinning | result | game_over
  String _phase = 'waiting';
  String? _winnerId;
  String _taskText = '';
  bool _gameOver = false;
  bool _cancelled = false;

  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Getters ────────────────────────────────────────────────────────────────
  int get round => _round;
  int get totalRounds => _totalRounds;
  String get phase => _phase;
  String? get winnerId => _winnerId;
  String get taskText => _taskText;
  bool get isGameOver => _gameOver;

  bool get isWinner =>
      _winnerId != null &&
      _winnerId == gameProvider.lobbyProvider.localPlayer?.id;

  String get winnerName => gameProvider.lobbyProvider.players
      .where((p) => p.id == _winnerId)
      .map((p) => p.name)
      .firstOrNull ?? '?';

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
    if (_gameOver || _cancelled) return;
    final players = gameProvider.lobbyProvider.players;
    final rng = Random();
    final winner = players[rng.nextInt(players.length)];
    final task = _tasks[rng.nextInt(_tasks.length)];

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
    _phase = 'spinning';
    AppAudio.playTap();
    _notify();

    // Spin animation duration = 3s, then show result
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (_cancelled) return;
      _phase = 'result';
      AppAudio.playGoal();
      HapticFeedback.heavyImpact();
      _notify();

      // Auto advance after 5s
      Future.delayed(const Duration(seconds: 5), () {
        if (_cancelled) return;
        _round++;
        if (_round >= _totalRounds) {
          _endGame();
        } else if (gameProvider.lobbyProvider.isHost) {
          _spinRound();
        } else {
          _phase = 'waiting';
          _notify();
        }
      });
    });
  }

  void _endGame() {
    _gameOver = true;
    _phase = 'game_over';
    AppAudio.playWin();
    // Everyone gets 50 pts — it's a party, everyone wins
    final scores = <String, int>{
      for (final p in gameProvider.lobbyProvider.players) p.id: 50,
    };
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(scores);
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

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
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
    if (widget.game.phase == 'spinning') {
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
    return Container(
      color: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            _header(g),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: g.phase == 'result'
                    ? _ResultPane(game: g)
                    : _WheelPane(game: g, spinAngle: _spinAngle),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _header(SpinPickerGame g) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Vòng ${g.round + 1}/${g.totalRounds}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '🎡 Vòng Quay Số Phận',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WheelPane extends StatelessWidget {
  final SpinPickerGame game;
  final Animation<double> spinAngle;
  const _WheelPane({required this.game, required this.spinAngle});

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
        // Arrow pointer
        const Text('▼', style: TextStyle(color: Color(0xFFFFD700), fontSize: 28)),
        const SizedBox(height: 4),
        // Spinning wheel
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
        if (game.phase == 'waiting')
          const Text(
            'Đang chờ...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          )
        else
          const Text(
            'Đang quay...',
            style: TextStyle(
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
  const _ResultPane({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confetti-like effect using big emoji
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
            child: const Text(
              '👆 Đó là BẠN! Hãy thực hiện nhiệm vụ nhé 😄',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF6584),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Vòng tiếp theo tự động...',
          style: TextStyle(color: Colors.white24, fontSize: 12),
        ),
      ],
    );
  }
}
