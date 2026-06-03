import 'package:flame/game.dart';
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
    gameProvider.onMiniGameEnded(playerScores);
  }
}
