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
    'tug_of_war': MiniGameHint(emoji: '👆', instruction: 'TAP NHANH!'),
    'sumo_bumper': MiniGameHint(emoji: '💥', instruction: 'HÚC THẬT MẠNH!'),
    'penalty_shootout': MiniGameHint(emoji: '⚽', instruction: 'SÚT VÀO KHUNG!'),
    'air_hockey': MiniGameHint(emoji: '🏒', instruction: 'KÉO ĐỂ ĐỠ!'),
    'reaction_tap': MiniGameHint(emoji: '⚡', instruction: 'TAP KHI SÁNG!'),
    'minesweeper': MiniGameHint(emoji: '💣', instruction: 'TRÁNH Ô MÌN!'),
    'billiards': MiniGameHint(emoji: '🎱', instruction: 'NGẮM VÀ BẮN!'),
    'draw_guess': MiniGameHint(emoji: '✏️', instruction: 'VẼ - ĐOÁN!'),
    'battleship': MiniGameHint(emoji: '🚢', instruction: 'ĐẶT TÀU - BẮN!'),
    'hot_potato': MiniGameHint(emoji: '💣', instruction: 'VUỐT ĐỂ NÉM!'),
    'code_breaker': MiniGameHint(emoji: '🔐', instruction: 'ĐOÁN MÃ SỐ!'),
    'liars_dice': MiniGameHint(emoji: '🎲', instruction: 'TỐ BÀI DỐI!'),
    'neon_dodge': MiniGameHint(emoji: '🕹️', instruction: 'NÉ CHƯỚNG NGẠI!'),
  };

  static MiniGameHint? forGame(String gameId) => _hints[gameId];
}
