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

  /// Thông tin gửi về GamepadScreen để hiển thị nút tương ứng.
  final Map<String, dynamic>? controllerConfig;

  const MiniGameMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.minPlayers,
    required this.maxPlayers,
    this.supportsConsoleMode = false,
    this.controllerConfig,
  });
}
