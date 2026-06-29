import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/theme/app_theme.dart';
import '../../domain/base_mini_game.dart';
import '../../domain/game_ids.dart';

/// Tôi Chưa Bao Giờ — drinking party game nhiều người.
///
/// Mỗi vòng Host hiển thị câu "Tôi chưa bao giờ...". Ai đã từng làm thì tap
/// "Tôi đã làm!" → mất 1 ngón tay (= phải uống 1 ngụm). Người còn nhiều
/// ngón tay nhất khi kết thúc 12 vòng thắng.
class NeverHaveIEverGame extends BaseMiniGame {
  static const int _totalRounds = 12;
  static const int _initialLives = 5;
  static const double _votingDuration = 12.0;

  static const List<String> _statements = [
    '...đi bộ về nhà một mình lúc 4 giờ sáng',
    '...gửi tin nhắn nhầm người và cảm thấy muốn độn thổ',
    '...giả vờ không có nhà khi ai đó gọi chuông cửa',
    '...ăn đồ ăn rơi xuống sàn (5 giây rule)',
    '...ngủ quên ở nơi công cộng (tàu, xe, thư viện...)',
    '...nhắn tin cho crush rồi lập tức hối hận',
    '...bịa lý do để trốn sự kiện mà thực ra không muốn đi',
    '...ăn/lấy đồ ăn của người khác trong tủ lạnh chung',
    '...hát thật to khi một mình trong xe hoặc phòng tắm',
    '...thức trắng đêm xem phim/chơi game rồi hối hận sáng hôm sau',
    '...mua thứ gì đó chỉ vì sale dù thực ra không cần',
    '...nói dối cha mẹ về việc đi đâu',
    '...chụp ảnh selfie hơn 10 lần để ra được 1 ảnh ưng',
    '...uống nhiều hơn dự định trong buổi tiệc',
    '...cố tình lờ cuộc gọi rồi nhắn "Em đang bận"',
    '...gặp người lạ online rồi trở thành bạn thân ngoài đời',
    '...thức khuya đọc bình luận mạng xã hội và stress',
    '...vi phạm luật giao thông (ít nhất 1 lần)',
    '...quay lại với người cũ ít nhất 1 lần',
    '...nhắn tin tỏ tình rồi thức không ngủ được chờ trả lời',
    '...tự nhủ "uống ít thôi" nhưng cuối cùng uống rất nhiều',
    '...kể chuyện của người khác cho người thứ ba nghe',
    '...làm điều gì đó chỉ vì peer pressure',
    '...đặt 10 cái báo thức nhưng tắt hết rồi ngủ tiếp',
  ];

  NeverHaveIEverGame(super.gameProvider);

  @override
  String get gameId => GameIds.neverHaveIEver;

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  // phases: waiting | voting | reveal | game_over
  String _phase = 'waiting';
  String _statementText = '';
  double _voteTimer = 0;
  bool _voteSubmitted = false;
  bool _myVote = false;
  Map<String, int> _lives = {};
  List<String> _revealedVoterIds = [];
  bool _gameOver = false;
  bool _cancelled = false;

  // Host-only: accumulate votes before reveal
  final List<String> _pendingVoters = [];
  bool _revealSent = false;

  void Function()? onStateChanged;
  void _notify() => onStateChanged?.call();

  // ── Getters ────────────────────────────────────────────────────────────────
  int get round => _round;
  int get totalRounds => _totalRounds;
  String get phase => _phase;
  String get statement => _statementText;
  double get voteTimer => _voteTimer;
  bool get voteSubmitted => _voteSubmitted;
  bool get isGameOver => _gameOver;
  Map<String, int> get lives => Map.unmodifiable(_lives);
  List<String> get revealedVoterIds => List.unmodifiable(_revealedVoterIds);

  String? get myId => gameProvider.lobbyProvider.localPlayer?.id;

  bool get iRevealed => _revealedVoterIds.contains(myId);

  String _playerName(String id) => gameProvider.lobbyProvider.players
      .where((p) => p.id == id)
      .map((p) => p.name)
      .firstOrNull ?? id;

  List<String> get revealedVoterNames =>
      _revealedVoterIds.map(_playerName).toList();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final p in gameProvider.lobbyProvider.players) {
      _lives[p.id] = _initialLives;
    }
    if (gameProvider.lobbyProvider.isHost) {
      Future.delayed(const Duration(milliseconds: 800), _startRound);
    }
  }

  void _startRound() {
    if (_gameOver || _cancelled) return;
    final rng = Random();
    final text = _statements[(_round + rng.nextInt(3)) % _statements.length];

    gameProvider.sendGameData(gameId, {
      'action': 'new_statement',
      'round': _round,
      'text': text,
    });
    _applyNewStatement(_round, text);
  }

  void _applyNewStatement(int round, String text) {
    _round = round;
    _statementText = text;
    _phase = 'voting';
    _voteTimer = _votingDuration;
    _voteSubmitted = false;
    _myVote = false;
    _revealedVoterIds = [];
    _pendingVoters.clear();
    _revealSent = false;
    AppAudio.playTap();
    _notify();
  }

  // ── Input ──────────────────────────────────────────────────────────────────
  void tapVote(bool hasDone) {
    if (_voteSubmitted || _phase != 'voting') return;
    _myVote = hasDone;
    _voteSubmitted = true;
    HapticFeedback.lightImpact();

    if (hasDone) {
      // Send to host
      gameProvider.sendGameData(gameId, {
        'action': 'vote',
        'voter_id': myId,
      });
      // If I am host, add to pending
      if (gameProvider.lobbyProvider.isHost) {
        _pendingVoters.add(myId!);
      }
    }
    _notify();
  }

  // ── Game loop (Host only) ──────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (_phase != 'voting' || _gameOver || !gameProvider.lobbyProvider.isHost) {
      return;
    }
    _voteTimer -= dt;
    if (_voteTimer <= 0) {
      _voteTimer = 0;
      _broadcastReveal();
    }
    _notify();
  }

  void _broadcastReveal() {
    if (_revealSent) return;
    _revealSent = true;

    final voters = List<String>.from(_pendingVoters);
    for (final id in voters) {
      _lives[id] = (_lives[id] ?? 1) - 1;
      if (_lives[id]! < 0) _lives[id] = 0;
    }

    gameProvider.sendGameData(gameId, {
      'action': 'reveal',
      'voters': voters,
      'lives': Map<String, dynamic>.from(_lives),
    });
    _applyReveal(voters, Map.from(_lives));
  }

  void _applyReveal(List<String> voters, Map<String, int> newLives) {
    _revealedVoterIds = voters;
    _lives = Map.from(newLives);
    _phase = 'reveal';
    if (voters.isNotEmpty) {
      AppAudio.playLose();
    } else {
      AppAudio.playGoal();
    }
    _notify();

    Future.delayed(const Duration(seconds: 4), () {
      if (_cancelled) return;
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
    AppAudio.playWin();
    // Score = lives remaining * 20 pts
    final scores = _lives.map((id, l) => MapEntry(id, l * 20));
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!_cancelled) endMiniGame(scores);
    });
  }

  // ── Network ────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'new_statement':
        _applyNewStatement(
          payload['round'] as int,
          payload['text'] as String,
        );

      case 'vote':
        if (gameProvider.lobbyProvider.isHost) {
          final voterId = payload['voter_id'] as String;
          if (!_pendingVoters.contains(voterId)) {
            _pendingVoters.add(voterId);
          }
        }

      case 'reveal':
        final voters = (payload['voters'] as List).cast<String>();
        final rawLives = payload['lives'] as Map;
        final newLives = rawLives.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
        _applyReveal(voters, newLives);
    }
  }

  @override
  void onDetach() {
    _cancelled = true;
    super.onDetach();
  }

  Widget buildOverlay(BuildContext context) =>
      _NeverHaveIEverOverlay(game: this);
}

// ── Overlay ────────────────────────────────────────────────────────────────

class _NeverHaveIEverOverlay extends StatefulWidget {
  final NeverHaveIEverGame game;
  const _NeverHaveIEverOverlay({required this.game});

  @override
  State<_NeverHaveIEverOverlay> createState() => _NeverHaveIEverOverlayState();
}

class _NeverHaveIEverOverlayState extends State<_NeverHaveIEverOverlay> {
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
        child: Column(
          children: [
            _RoundHeader(round: g.round, total: g.totalRounds),
            _LivesBar(
              lives: g.lives,
              players: g.gameProvider.lobbyProvider.players,
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(child: _MainContent(game: g)),
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
    return Padding(
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
            '✋ Tôi Chưa Bao Giờ',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LivesBar extends StatelessWidget {
  final Map<String, int> lives;
  final List players;
  const _LivesBar({required this.lives, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = players[i];
          final l = lives[p.id] ?? 5;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                p.name,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                List.generate(5, (j) => j < l ? '🍺' : '💀').join(),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final NeverHaveIEverGame game;
  const _MainContent({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    return switch (g.phase) {
      'waiting' => const _WaitingPane(),
      'voting' => _VotingPane(game: g),
      'reveal' => _RevealPane(game: g),
      _ => const _WaitingPane(),
    };
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
          Text('✋', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text(
            'Đang chuẩn bị câu tiếp theo...',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _VotingPane extends StatelessWidget {
  final NeverHaveIEverGame game;
  const _VotingPane({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final timeRatio = (g.voteTimer / NeverHaveIEverGame._votingDuration).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'TÔI CHƯA BAO GIỜ...',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Text(
              g.statement,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Timer bar
          SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: timeRatio,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                Color.lerp(Colors.red, const Color(0xFF6C63FF), timeRatio)!,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Text(
            '${g.voteTimer.ceil()}s',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          if (!g.voteSubmitted) ...[
            const Text(
              'Bạn đã từng làm điều này chưa?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => g.tapVote(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6584),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text('✋', style: TextStyle(fontSize: 24)),
                        SizedBox(height: 4),
                        Text(
                          'Tôi đã làm!\n(uống 1 ngụm)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => g.tapVote(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Text('🙅', style: TextStyle(fontSize: 24)),
                        SizedBox(height: 4),
                        Text(
                          'Tôi chưa bao giờ\n(an toàn)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (g.voteSubmitted && g._myVote
                        ? const Color(0xFFFF6584)
                        : const Color(0xFF43A047))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (g.voteSubmitted && g._myVote
                          ? const Color(0xFFFF6584)
                          : const Color(0xFF43A047))
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                g._myVote
                    ? '✋ Bạn đã bỏ phiếu "Tôi đã làm" — Đang chờ kết quả...'
                    : '🙅 Bạn đã bỏ phiếu "Chưa bao giờ" — An toàn!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: g._myVote
                      ? const Color(0xFFFF6584)
                      : const Color(0xFF81C784),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RevealPane extends StatelessWidget {
  final NeverHaveIEverGame game;
  const _RevealPane({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final names = g.revealedVoterNames;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'KẾT QUẢ',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            g.statement,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (names.isEmpty)
            const Column(
              children: [
                Text('😇', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text(
                  'Không ai thú nhận!\nMọi người vẫn an toàn 👏',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else ...[
            const Text('🍺', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              names.join(', '),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF6584),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'phải uống ${names.length} ngụm! 🍺',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (g.iRevealed)
            const Text(
              '👆 Bạn nằm trong nhóm này!',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Vòng tiếp theo...',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
