/// Thông tin cấu hình mô tả một mini-game trong Registry.
class MiniGameMetadata {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final int minPlayers;
  final int maxPlayers;

  const MiniGameMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.minPlayers,
    required this.maxPlayers,
  });
}
