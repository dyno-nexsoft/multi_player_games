import 'package:flutter/foundation.dart';
import '../../../core/network/game_packet.dart';
import '../../lobby/presentation/lobby_provider.dart';
import '../domain/base_mini_game.dart';
import '../domain/mini_game_registry.dart';

/// Quản lý vòng lặp tournament (nhiều vòng chơi), điểm tổng kết và mini-game đang active.
class GameProvider extends ChangeNotifier {
  final LobbyProvider lobbyProvider;

  GameProvider(this.lobbyProvider) {
    lobbyProvider.onGamePacket = _handleGamePacket;
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

  // ── Methods ────────────────────────────────────────────────────────────────

  /// Khởi chạy mini-game theo gameId nhận từ LobbyProvider.
  void launchGame(String gameId) {
    _clearActiveGame();
    _lastGameId = gameId;
    _lastLaunchToken = lobbyProvider.gameStartToken;
    _currentRound++;
    _isSeriesOver = false;
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
  void onMiniGameEnded(Map<String, int> roundScores) {
    for (final entry in roundScores.entries) {
      _totalScores[entry.key] = (_totalScores[entry.key] ?? 0) + entry.value;
    }

    // Tìm người thắng hiệp này và cộng win
    if (roundScores.isNotEmpty) {
      final best = roundScores.values.fold(0, (a, b) => a > b ? a : b);
      if (best > 0) {
        final winnerId = roundScores.entries
            .firstWhere((e) => e.value == best)
            .key;
        _roundWins[winnerId] = (_roundWins[winnerId] ?? 0) + 1;

        final winsNeeded = (lobbyProvider.seriesLength / 2).ceil();
        if ((_roundWins[winnerId] ?? 0) >= winsNeeded) {
          _isSeriesOver = true;
        }
      }
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
    super.dispose();
  }
}
