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

  /// Khởi chạy mini-game theo gameId nhận từ LobbyProvider.
  void launchGame(String gameId) {
    _activeGame = MiniGameRegistry.createGame(gameId, this);
    _showScoreboard = false;
    notifyListeners();
  }

  /// Được gọi bởi BaseMiniGame khi kết thúc trận đấu.
  void onMiniGameEnded(Map<String, int> roundScores) {
    for (final entry in roundScores.entries) {
      _totalScores[entry.key] = (_totalScores[entry.key] ?? 0) + entry.value;
    }
    _activeGame = null;
    _showScoreboard = true;
    notifyListeners();
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
