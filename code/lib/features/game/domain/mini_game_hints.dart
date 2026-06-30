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
    GameIds.sumoBumper: MiniGameHint(
      emoji: '💥',
      instruction: 'HÚC THẬT MẠNH!',
    ),
    GameIds.reactionTap: MiniGameHint(emoji: '⚡', instruction: 'TAP KHI SÁNG!'),
    GameIds.minesweeper: MiniGameHint(emoji: '💣', instruction: 'TRÁNH Ô MÌN!'),
    GameIds.hotPotato: MiniGameHint(emoji: '💣', instruction: 'VUỐT ĐỂ NÉM!'),
    GameIds.neonDodge: MiniGameHint(
      emoji: '🕹️',
      instruction: 'NÉ CHƯỚNG NGẠI!',
    ),
    GameIds.truthOrDare: MiniGameHint(
      emoji: '🃏',
      instruction: 'THẬT HAY THÁCH!',
    ),
    GameIds.spinPicker: MiniGameHint(
      emoji: '🎡',
      instruction: 'VÒNG QUAY QUYẾT ĐỊNH!',
    ),
    GameIds.neverHaveIEver: MiniGameHint(
      emoji: '✋',
      instruction: 'AI ĐÃ TỪNG?',
    ),
  };

  static MiniGameHint? forGame(String gameId) => _hints[gameId];
}
