import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:party_game_hub/core/audio/audio_service.dart';

import '../presentation/game_provider.dart';

/// Interface chuẩn cho mọi mini-game Flame trong hệ thống.
/// Kế thừa lớp này để đăng ký vào MiniGameRegistry và nhận sự kiện mạng.
abstract class BaseMiniGame extends FlameGame {
  final GameProvider gameProvider;

  BaseMiniGame(this.gameProvider);

  // ── Shared lifecycle ────────────────────────────────────────────────────────

  /// Callback được gọi khi trạng thái game thay đổi để trigger setState trên overlay.
  void Function()? onStateChanged;

  /// Gọi callback này thay vì trực tiếp `onStateChanged?.call()` để dễ override sau này.
  @protected
  void notifyOverlay() => onStateChanged?.call();

  /// True sau khi widget bị dispose — mọi delayed callback phải kiểm tra trước khi chạy.
  bool cancelled = false;

  @override
  void onDetach() {
    cancelled = true;
    super.onDetach();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Tra cứu tên người chơi theo id. Trả về id nếu không tìm thấy.
  String playerNameFor(String id) =>
      gameProvider.lobbyProvider.players
          .where((p) => p.id == id)
          .map((p) => p.name)
          .firstOrNull ??
      id;

  // ── Lifecycle (Flame) ──────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  /// Mã định danh duy nhất của mini-game, khớp với MiniGameMetadata.id.
  String get gameId;

  /// Gọi khi nhận gói tin mạng có game_id trùng với gameId này.
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload);

  /// Kết thúc trận đấu và báo kết quả lên GameProvider.
  void endMiniGame(Map<String, int> playerScores) {
    final localId = gameProvider.lobbyProvider.localPlayer?.id;
    final myScore = localId != null ? (playerScores[localId] ?? 0) : 0;
    final best = playerScores.values.fold(0, (a, b) => a > b ? a : b);
    if (best > 0) {
      myScore >= best ? AppAudio.playWin() : AppAudio.playLose();
    }
    gameProvider.onMiniGameEnded(playerScores);
  }
}
