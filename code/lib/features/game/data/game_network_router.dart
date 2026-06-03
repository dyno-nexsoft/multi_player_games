import '../../../core/network/game_packet.dart';
import '../domain/base_mini_game.dart';

/// Định tuyến gói tin mạng đến mini-game đang active dựa theo game_id.
class GameNetworkRouter {
  BaseMiniGame? activeGame;

  void route(GamePacket packet) {
    if (activeGame == null) return;
    if (packet.gameId != activeGame!.gameId) return;
    activeGame!.onNetworkDataReceived(packet.senderId ?? '', packet.payload);
  }
}
