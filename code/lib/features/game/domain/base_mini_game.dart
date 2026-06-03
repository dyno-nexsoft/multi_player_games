import 'package:flame/game.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';
import '../presentation/game_provider.dart';

/// Interface chuẩn cho mọi mini-game Flame trong hệ thống.
/// Kế thừa lớp này để đăng ký vào MiniGameRegistry và nhận sự kiện mạng.
abstract class BaseMiniGame extends FlameGame {
  final GameProvider gameProvider;

  BaseMiniGame(this.gameProvider);

  /// Mã định danh duy nhất của mini-game, khớp với MiniGameMetadata.id.
  String get gameId;

  /// Gọi khi nhận gói tin mạng có game_id trùng với gameId này.
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload);

  /// Kết thúc trận đấu và báo kết quả lên GameProvider.
  void endMiniGame(Map<String, int> playerScores) {
    final localId = gameProvider.lobbyProvider.localPlayer?.id;
    final myScore = localId != null ? (playerScores[localId] ?? 0) : 0;
    final best = playerScores.values.fold(0, (a, b) => a > b ? a : b);
    // Không phát audio nếu tất cả điểm bằng 0 (hòa / không có ai ghi điểm)
    if (best > 0) {
      myScore >= best ? AppAudio.playWin() : AppAudio.playLose();
    }
    gameProvider.onMiniGameEnded(playerScores);
  }
}
