import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import 'package:party_game_hub/core/storage/stats_service.dart';
import '../../../core/network/game_packet.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../domain/base_mini_game.dart';
import '../domain/mini_game_registry.dart';

/// Quản lý vòng lặp tournament (nhiều vòng chơi), điểm tổng kết và mini-game đang active.
class GameProvider extends ChangeNotifier {
  final LobbyProvider lobbyProvider;

  GameProvider(this.lobbyProvider) {
    lobbyProvider.onGamePacket = _handleGamePacket;
    lobbyProvider.onGameEnded = _handleEndGamePacket;
    lobbyProvider.onHapticReceived = () => HapticFeedback.heavyImpact();
  }

  /// Phát rung cục bộ ngay lập tức và yêu cầu các thiết bị khác rung cùng lúc.
  /// Dùng cho các khoảnh khắc "vật lý nối liền" (dây đứt, puck qua mép sân).
  void triggerSyncHaptic() {
    HapticFeedback.heavyImpact();
    lobbyProvider.sendHaptic();
  }

  BaseMiniGame? _activeGame;
  BaseMiniGame? get activeGame => _activeGame;

  final Map<String, int> _totalScores = {};
  Map<String, int> get totalScores => Map.unmodifiable(_totalScores);

  bool _showScoreboard = false;
  bool get showScoreboard => _showScoreboard;

  String? _lastGameId;
  String? get lastGameId => _lastGameId;

  /// Token đồng bộ với LobbyProvider.gameStartToken khi game được launch.
  int _lastLaunchToken = -1;
  int get lastLaunchToken => _lastLaunchToken;

  // ── Series ─────────────────────────────────────────────────────────────────
  int _currentRound = 0;
  int get currentRound => _currentRound;

  int get seriesLength => lobbyProvider.seriesLength;

  final Map<String, int> _roundWins = {};
  Map<String, int> get roundWins => Map.unmodifiable(_roundWins);

  bool _isSeriesOver = false;
  bool get isSeriesOver => _isSeriesOver;

  /// Đảm bảo mỗi hiệp chỉ tính kết quả một lần (idempotent).
  /// Reset mỗi khi launch game/hiệp mới.
  bool _roundEnded = false;

  // ── Methods ────────────────────────────────────────────────────────────────

  /// Khởi chạy mini-game theo gameId nhận từ LobbyProvider.
  void launchGame(String gameId) {
    _clearActiveGame();
    _lastGameId = gameId;
    _lastLaunchToken = lobbyProvider.gameStartToken;
    _currentRound++;
    _isSeriesOver = false;
    _roundEnded = false;
    _activeGame = MiniGameRegistry.createGame(gameId, this);
    _showScoreboard = false;
    notifyListeners();
  }

  /// Gọi khi user quay về lobby — dọn dẹp game instance cũ.
  void leaveGame() {
    _clearActiveGame();
    _showScoreboard = false;
    notifyListeners();
  }

  /// Host gọi khi muốn bắt đầu hiệp tiếp trong series.
  void startNextRound() {
    if (_lastGameId == null || !lobbyProvider.isHost) return;
    lobbyProvider.startGame(_lastGameId!);
    notifyListeners();
  }

  /// Host gọi khi muốn chơi lại từ đầu (reset toàn bộ series).
  void startRematch() {
    if (_lastGameId == null || !lobbyProvider.isHost) return;
    _totalScores.clear();
    _roundWins.clear();
    _currentRound = 0;
    _isSeriesOver = false;
    lobbyProvider.startGame(_lastGameId!);
    notifyListeners();
  }

  /// Được gọi bởi BaseMiniGame khi kết thúc trận đấu.
  ///
  /// Host là nguồn chân lý: broadcast kết quả authoritative để client cũng
  /// chuyển sang scoreboard với cùng điểm số. `_applyRoundResult` idempotent
  /// nên client gọi local (game tự tính 2 phía) và gói tin từ host không bị
  /// cộng đôi.
  void onMiniGameEnded(Map<String, int> roundScores) {
    if (lobbyProvider.isHost && !_roundEnded) {
      final packet = GamePacket(
        type: PacketType.endGame,
        senderId: lobbyProvider.localPlayer?.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: {'scores': roundScores},
      );
      lobbyProvider.sendGamePacket(packet);
    }
    _applyRoundResult(roundScores);
  }

  /// Client nhận kết quả authoritative từ host.
  void _handleEndGamePacket(GamePacket packet) {
    if (lobbyProvider.isHost) return; // host đã áp dụng cục bộ
    if (_roundEnded) {
      return; // game đã tự kết thúc 2 phía (tránh phát audio đôi)
    }
    final raw = packet.payload['scores'] as Map<String, dynamic>?;
    if (raw == null) return;
    // 5.2 — v is dynamic from the network; guard against null / wrong type.
    final scores = raw.map((k, v) => MapEntry(k, v is num ? v.toInt() : 0));

    // Phát win/lose cho client ở các game host-authoritative (client không
    // đi qua BaseMiniGame.endMiniGame).
    final localId = lobbyProvider.localPlayer?.id;
    final myScore = localId != null ? (scores[localId] ?? 0) : 0;
    final best = scores.values.fold(0, (a, b) => a > b ? a : b);
    if (best > 0) {
      myScore >= best ? AppAudio.playWin() : AppAudio.playLose();
    }

    _applyRoundResult(scores);
  }

  void _applyRoundResult(Map<String, int> roundScores) {
    if (_roundEnded) return;
    _roundEnded = true;
    for (final entry in roundScores.entries) {
      _totalScores[entry.key] = (_totalScores[entry.key] ?? 0) + entry.value;
    }

    // Tìm người thắng hiệp này và cộng win.
    // Hòa (nhiều người cùng điểm cao nhất) → không cộng win cho ai.
    if (roundScores.isNotEmpty) {
      final best = roundScores.values.fold(0, (a, b) => a > b ? a : b);
      final topPlayers = roundScores.entries
          .where((e) => e.value == best)
          .toList();
      if (best > 0 && topPlayers.length == 1) {
        final winnerId = topPlayers.first.key;
        _roundWins[winnerId] = (_roundWins[winnerId] ?? 0) + 1;

        final winsNeeded = (lobbyProvider.seriesLength / 2).ceil();
        if ((_roundWins[winnerId] ?? 0) >= winsNeeded) {
          _isSeriesOver = true;
        }
      }
    }

    // Ghi nhận thống kê khi trận/series thực sự kết thúc.
    final seriesDone = lobbyProvider.seriesLength <= 1 || _isSeriesOver;
    if (seriesDone) {
      final localId = lobbyProvider.localPlayer?.id;
      final top = _totalScores.values.fold(0, (a, b) => a > b ? a : b);
      final topCount = _totalScores.values.where((v) => v == top).length;
      final won =
          localId != null &&
          top > 0 &&
          topCount == 1 &&
          (_totalScores[localId] ?? 0) == top;
      // 6.2 — fire-and-forget: wrap with unawaited() to make intent clear and silence lint.
      unawaited(StatsService.recordResult(won: won));
    }

    // Không null activeGame — giữ Flame canvas hiển thị dưới scoreboard overlay.
    // Game đã set _gameEnded=true nên update() là no-op, canvas chỉ render static.
    _showScoreboard = true;
    notifyListeners();
  }

  /// Giải phóng game hiện tại — gọi khi user rời phòng hoặc start game mới.
  void _clearActiveGame() {
    _activeGame = null;
  }

  void _handleGamePacket(GamePacket packet) {
    if (_activeGame == null) return;
    if (packet.gameId != _activeGame!.gameId) return;
    _activeGame!.onNetworkDataReceived(packet.senderId ?? '', packet.payload);
  }

  void pauseActiveGame() => _activeGame?.pauseEngine();
  void resumeActiveGame() => _activeGame?.resumeEngine();

  /// Host gửi cấu hình tay cầm tới tất cả client (labels, highlight, joystick_enabled…).
  void sendControllerInit(String gameId, Map<String, dynamic> config) {
    lobbyProvider.sendGamePacket(
      GamePacket(
        type: PacketType.initController,
        gameId: gameId,
        senderId: lobbyProvider.localPlayer?.id,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: config,
      ),
    );
  }

  /// Host gửi feedback rung/chớp tới tay cầm của một người chơi cụ thể.
  void sendControllerFeedback(
    String playerId, {
    required String hapticType,
    int? flashColor,
  }) {
    lobbyProvider.sendControllerFeedback(
      playerId,
      hapticType: hapticType,
      flashColor: flashColor,
    );
  }

  /// Gửi gói tin game data qua LobbyProvider (Host broadcast / Client send).
  void sendGameData(String gameId, Map<String, dynamic> payload) {
    final packet = GamePacket(
      type: PacketType.gameData,
      gameId: gameId,
      senderId: lobbyProvider.localPlayer?.id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: payload,
    );
    lobbyProvider.sendGamePacket(packet);
  }

  @override
  void dispose() {
    lobbyProvider.onGamePacket = null;
    lobbyProvider.onGameEnded = null;
    lobbyProvider.onHapticReceived = null;
    super.dispose();
  }
}
