/// Thông tin cấu hình mô tả một mini-game trong Registry.
class MiniGameMetadata {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int minPlayers;
  final int maxPlayers;

  /// True = game chạy ở chế độ Console (Host là màn hình, Client là tay cầm).
  final bool supportsConsoleMode;

  const MiniGameMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.minPlayers,
    required this.maxPlayers,
    this.supportsConsoleMode = false,
  });
}
