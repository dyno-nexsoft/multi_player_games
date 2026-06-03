import 'dart:convert';

/// Gói tin truyền nhận qua socket TCP giữa Host và Client.
/// Tất cả giao tiếp mạng đều đi qua cấu trúc này để đảm bảo nhất quán.
class GamePacket {
  final String type;
  final String? gameId;
  final String? senderId;
  final int timestamp;
  final Map<String, dynamic> payload;

  const GamePacket({
    required this.type,
    this.gameId,
    this.senderId,
    required this.timestamp,
    required this.payload,
  });

  factory GamePacket.fromJson(Map<String, dynamic> json) {
    return GamePacket(
      type: json['type'] as String,
      gameId: json['game_id'] as String?,
      senderId: json['sender_id'] as String?,
      timestamp: json['timestamp'] as int? ?? 0,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (gameId != null) 'game_id': gameId,
        if (senderId != null) 'sender_id': senderId,
        'timestamp': timestamp,
        'payload': payload,
      };

  /// Chuyển thành chuỗi JSON kết thúc bằng '\n' để phân tách gói tin trên stream.
  String toWire() => '${jsonEncode(toJson())}\n';

  static GamePacket? tryParse(String raw) {
    try {
      final json = jsonDecode(raw.trim()) as Map<String, dynamic>;
      return GamePacket.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Các hằng số loại gói tin dùng chung.
abstract class PacketType {
  static const String join = 'join';
  static const String leave = 'leave';
  static const String lobbySync = 'lobby_sync';
  static const String startGame = 'start_game';
  static const String endGame = 'end_game';
  static const String gameData = 'game_data';
  static const String worldState = 'world_state';
  static const String heartbeat = 'heartbeat';
  static const String systemPause = 'system_pause';
}
