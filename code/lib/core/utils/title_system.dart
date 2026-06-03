/// Hệ thống danh hiệu dựa trên số trận thắng tích lũy.
abstract class TitleSystem {
  static const List<(int, String)> _tiers = [
    (0, 'Tân Binh'),
    (1, 'Chiến Binh'),
    (3, 'Kẻ Thách Đấu'),
    (6, 'Vua Chiến Trường'),
    (11, 'Sát Thủ'),
    (20, 'Huyền Thoại ✨'),
  ];

  static String titleFor(int wins) {
    String title = _tiers.first.$2;
    for (final (threshold, name) in _tiers) {
      if (wins >= threshold) title = name;
    }
    return title;
  }

  static String badgeFor(int wins) {
    if (wins >= 20) return '💎';
    if (wins >= 11) return '⚡';
    if (wins >= 6) return '🏆';
    if (wins >= 3) return '🔥';
    if (wins >= 1) return '⚔️';
    return '🌱';
  }
}
