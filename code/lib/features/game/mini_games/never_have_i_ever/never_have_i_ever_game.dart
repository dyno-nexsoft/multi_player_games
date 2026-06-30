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

enum NhiePhase { waiting, voting, reveal, gameOver }

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
    // Thêm mới
    '...ăn sầu riêng xong bị người xung quanh chê mùi',
    '...quên sinh nhật bạn thân rồi phải xin lỗi rất lâu',
    '...lộn xe hoặc té xe trước mặt người đông đúc',
    '...bị bắt gặp đang nói xấu người đang đứng ngay sau lưng',
    '...gọi nhầm tên thầy/cô hoặc sếp bằng "mẹ" hoặc "ba"',
    '...thức đến 5 giờ sáng không vì lý do gì chính đáng',
    '...ăn đồ ăn của người khác vì tưởng là của mình',
    '...đứng chờ thang máy 1 phút rồi mới nhận ra cửa đang mở sẵn',
    '...tự hứa sẽ ăn kiêng rồi phá luật ngay hôm đó',
    '...nhìn giá trước khi order rồi vẫn order đồ đắt nhất',
    '...khóc vì 1 bộ phim hoạt hình',
    '...gửi nhầm ảnh/video cho người không đúng',
    '...bị block trên mạng xã hội mà không biết lý do',
    '...nói "mình sắp đến rồi" trong khi chưa ra khỏi nhà',
    '...bình luận trên post cũ của người ta rồi bị tụi bạn tease',
    '...ngủ quên trong buổi họp hoặc lớp học',
    '...đặt báo thức nhưng tắt đi tiếp mà không nhớ gì',
    '...mua vé xem phim xong ngủ gật trong rạp',
    '...nhảy vào hồ bơi hoặc biển mà quên là có điện thoại trong túi',
    '...đi chơi xa quên mang thứ quan trọng nhất',
    '...cố nuôi cây hoặc thú cưng rồi để nó chết',
    '...nói "1 phút nữa thôi" nhưng thực ra mất cả tiếng',
    '...giả vờ không nghe thấy khi ai đó gọi tên mình',
    '...lỡ fart trước mặt người khác và cố giả vờ không có gì',
  ];

  static const List<String> _statementsEn = [
    '...walked home alone at 4 in the morning',
    '...sent a message to the wrong person and wanted to disappear',
    '...pretended not to be home when someone rang the doorbell',
    '...eaten food that dropped on the floor (5-second rule)',
    '...fallen asleep in public (train, bus, library...)',
    '...texted a crush and immediately regretted it',
    '...made up an excuse to skip an event you didn\'t want to attend',
    '...eaten or taken someone else\'s food from the shared fridge',
    '...sung loudly when alone in the car or bathroom',
    '...stayed up all night watching shows then regretted it next morning',
    '...bought something just because it was on sale even though you didn\'t need it',
    '...lied to your parents about where you were going',
    '...taken more than 10 selfies to get just one good shot',
    '...drunk more than you planned at a party',
    '...deliberately ignored a call then texted "I\'m busy"',
    '...met a stranger online and became close friends in real life',
    '...stayed up late reading social media comments and got stressed',
    '...broken a traffic rule (at least once)',
    '...gotten back together with an ex at least once',
    '...sent a confession text then couldn\'t sleep waiting for the reply',
    '...told yourself "just a little" but ended up drinking a lot',
    '...shared someone else\'s secret with a third person',
    '...done something purely because of peer pressure',
    '...set 10 alarms but turned them all off and went back to sleep',
    '...eaten durian and been told you smell bad by everyone nearby',
    '...forgotten a best friend\'s birthday and had to apologize for days',
    '...crashed a bike or fallen off in front of a crowd',
    '...been caught talking badly about someone standing right behind you',
    '...accidentally called a teacher or boss "mom" or "dad"',
    '...stayed up until 5am for absolutely no good reason',
    '...eaten someone else\'s food thinking it was yours',
    '...waited a full minute for an elevator that was already open',
    '...promised yourself you\'d diet then broke it that same day',
    '...checked the menu prices then still ordered the most expensive thing',
    '...cried at an animated movie',
    '...sent a photo or video to the wrong person',
    '...been blocked on social media without knowing why',
    '...said "I\'m almost there" while still at home',
    '...liked an old post while stalking someone and panicked',
    '...fallen asleep in a meeting or class',
    '...set an alarm then turned it off while half asleep and remembered nothing',
    '...bought a movie ticket then slept through it at the cinema',
    '...jumped in a pool or ocean and remembered your phone was in your pocket',
    '...gone on a trip and forgotten the most important thing',
    '...tried to keep a plant or pet alive and failed',
    '...said "just one more minute" but it turned into over an hour',
    '...pretended not to hear someone calling your name',
    '...accidentally farted in front of others and pretended nothing happened',
  ];

  NeverHaveIEverGame(super.gameProvider);

  @override
  String get gameId => GameIds.neverHaveIEver;

  bool get _isEnglish =>
      PlatformDispatcher.instance.locale.languageCode == 'en';

  // ── State ──────────────────────────────────────────────────────────────────
  int _round = 0;
  NhiePhase _phase = NhiePhase.waiting;
  String _statementText = '';
  double _voteTimer = 0;
  bool _voteSubmitted = false;
  bool _myVote = false;
  Map<String, int> _lives = {};
  List<String> _revealedVoterIds = [];
  bool _gameOver = false;

  // Host-only: accumulate votes before reveal
  final List<String> _pendingVoters = [];
  bool _revealSent = false;

  void _notify() => notifyOverlay();

  // ── Getters ────────────────────────────────────────────────────────────────
  int get round => _round;
  int get totalRounds => _totalRounds;
  NhiePhase get phase => _phase;
  String get statement => _statementText;
  double get voteTimer => _voteTimer;
  bool get voteSubmitted => _voteSubmitted;
  bool get isGameOver => _gameOver;
  Map<String, int> get lives => Map.unmodifiable(_lives);
  List<String> get revealedVoterIds => List.unmodifiable(_revealedVoterIds);

  String? get myId => gameProvider.lobbyProvider.localPlayer?.id;

  bool get iRevealed => _revealedVoterIds.contains(myId);

  List<String> get revealedVoterNames =>
      _revealedVoterIds.map(playerNameFor).toList();

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
    if (_gameOver || cancelled) return;
    final rng = Random();
    final stmts = _isEnglish ? _statementsEn : _statements;
    final text = stmts[(_round + rng.nextInt(3)) % stmts.length];

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
    _phase = NhiePhase.voting;
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
    if (_voteSubmitted || _phase != NhiePhase.voting) return;
    _myVote = hasDone;
    _voteSubmitted = true;
    HapticFeedback.lightImpact();

    if (hasDone) {
      final id = myId;
      if (id == null) return;
      gameProvider.sendGameData(gameId, {'action': 'vote', 'voter_id': id});
      if (gameProvider.lobbyProvider.isHost) {
        _pendingVoters.add(id);
      }
    }
    _notify();
  }

  int _lastTimerTick = -1;

  // ── Game loop (Host only) ──────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (_phase != NhiePhase.voting ||
        _gameOver ||
        !gameProvider.lobbyProvider.isHost) {
      return;
    }
    _voteTimer -= dt;
    if (_voteTimer <= 0) {
      _voteTimer = 0;
      _broadcastReveal();
    }
    // Only rebuild when the displayed second changes — avoids 60fps setState.
    final tick = _voteTimer.ceil();
    if (tick != _lastTimerTick) {
      _lastTimerTick = tick;
      _notify();
    }
  }

  void _broadcastReveal() {
    if (_revealSent) return;
    _revealSent = true;

    final voters = List<String>.from(_pendingVoters);
    for (final id in voters) {
      final current = _lives[id] ?? _initialLives;
      _lives[id] = (current - 1).clamp(0, _initialLives);
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
    _phase = NhiePhase.reveal;
    if (voters.isNotEmpty) {
      AppAudio.playLose();
    } else {
      AppAudio.playGoal();
    }
    _notify();

    Future.delayed(const Duration(seconds: 4), () {
      if (cancelled) return;
      _round++;
      if (_round >= _totalRounds) {
        _endGame();
      } else if (gameProvider.lobbyProvider.isHost) {
        _startRound();
      } else {
        _phase = NhiePhase.waiting;
        _notify();
      }
    });
  }

  void _endGame() {
    _gameOver = true;
    _phase = NhiePhase.gameOver;
    AppAudio.playWin();
    // Score = lives remaining * 20 pts
    final scores = _lives.map((id, l) => MapEntry(id, l * 20));
    _notify();
    Future.delayed(const Duration(seconds: 2), () {
      if (!cancelled) endMiniGame(scores);
    });
  }

  // ── Network ────────────────────────────────────────────────────────────────
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    switch (payload['action'] as String?) {
      case 'new_statement':
        _applyNewStatement(payload['round'] as int, payload['text'] as String);

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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
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
            l10n.nhieGameTitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LivesBar extends StatelessWidget {
  final Map<String, int> lives;
  final List<Player> players;
  const _LivesBar({required this.lives, required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
    final l10n = AppLocalizations.of(context)!;
    final g = game;
    return switch (g.phase) {
      NhiePhase.waiting => _WaitingPane(label: l10n.nhiePreparing),
      NhiePhase.voting => _VotingPane(game: g),
      NhiePhase.reveal => _RevealPane(game: g),
      NhiePhase.gameOver => _WaitingPane(label: l10n.nhiePreparing),
    };
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
          const Text('✋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 15),
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
    final l10n = AppLocalizations.of(context)!;
    final g = game;
    final timeRatio = (g.voteTimer / NeverHaveIEverGame._votingDuration).clamp(
      0.0,
      1.0,
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            l10n.nhieStatementHeader,
            style: const TextStyle(
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
            Text(
              l10n.nhieQuestion,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    child: Column(
                      children: [
                        const Text('✋', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          l10n.nhieDoneBtn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                    child: Column(
                      children: [
                        const Text('🙅', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          l10n.nhieSafeBtn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                color:
                    (g.voteSubmitted && g._myVote
                            ? const Color(0xFFFF6584)
                            : const Color(0xFF43A047))
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      (g.voteSubmitted && g._myVote
                              ? const Color(0xFFFF6584)
                              : const Color(0xFF43A047))
                          .withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                g._myVote ? l10n.nhieVotedDone : l10n.nhieVotedSafe,
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
    final l10n = AppLocalizations.of(context)!;
    final g = game;
    final names = g.revealedVoterNames;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.nhieResultTitle,
            style: const TextStyle(
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
            Column(
              children: [
                const Text('😇', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  l10n.nhieNobodyConfessed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
              l10n.nhieSipCount(names.length),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
          const SizedBox(height: 24),
          if (g.iRevealed)
            Text(
              l10n.nhieYouInGroup,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            l10n.nhieNextRound,
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
