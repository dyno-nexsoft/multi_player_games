import 'game_ids.dart';

/// Gợi ý ngắn hiển thị 1.5 giây trước khi game bắt đầu (§2 Tutorial spec).
class MiniGameHint {
  /// Emoji/biểu tượng minh họa hành động chính.
  final String emoji;

  /// Câu lệnh ngắn gọn — tối đa 3 từ, chữ in hoa.
  final String instruction;

  const MiniGameHint({required this.emoji, required this.instruction});
}

abstract class MiniGameHints {
  static const Map<String, MiniGameHint> _hints = {
    GameIds.tugOfWar: MiniGameHint(emoji: '👆', instruction: 'TAP NHANH!'),
    GameIds.sumoBumper: MiniGameHint(emoji: '💥', instruction: 'HÚC THẬT MẠNH!'),
    GameIds.penaltyShootout: MiniGameHint(emoji: '⚽', instruction: 'SÚT VÀO KHUNG!'),
    GameIds.airHockey: MiniGameHint(emoji: '🏒', instruction: 'KÉO ĐỂ ĐỠ!'),
    GameIds.reactionTap: MiniGameHint(emoji: '⚡', instruction: 'TAP KHI SÁNG!'),
    GameIds.minesweeper: MiniGameHint(emoji: '💣', instruction: 'TRÁNH Ô MÌN!'),
    GameIds.billiards: MiniGameHint(emoji: '🎱', instruction: 'NGẮM VÀ BẮN!'),
    GameIds.drawGuess: MiniGameHint(emoji: '✏️', instruction: 'VẼ - ĐOÁN!'),
    GameIds.battleship: MiniGameHint(emoji: '🚢', instruction: 'ĐẶT TÀU - BẮN!'),
    GameIds.hotPotato: MiniGameHint(emoji: '💣', instruction: 'VUỐT ĐỂ NÉM!'),
    GameIds.codeBreaker: MiniGameHint(emoji: '🔐', instruction: 'ĐOÁN MÃ SỐ!'),
    GameIds.liarsDice: MiniGameHint(emoji: '🎲', instruction: 'TỐ BÀI DỐI!'),
    GameIds.neonDodge: MiniGameHint(emoji: '🕹️', instruction: 'NÉ CHƯỚNG NGẠI!'),
  };

  static MiniGameHint? forGame(String gameId) => _hints[gameId];
}
