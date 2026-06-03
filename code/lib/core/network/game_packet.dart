import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_packet.freezed.dart';
part 'game_packet.g.dart';

/// Gói tin truyền nhận qua socket TCP giữa Host và Client.
/// Tất cả giao tiếp mạng đều đi qua cấu trúc này để đảm bảo nhất quán.
@freezed
abstract class GamePacket with _$GamePacket {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory GamePacket({
    required String type,
    @JsonKey(includeIfNull: false) String? gameId,
    @JsonKey(includeIfNull: false) String? senderId,
    @Default(0) int timestamp,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
  }) = _GamePacket;

  const GamePacket._();

  /// Creates a [GamePacket] instance from a JSON map.
  /// Used for parsing incoming network data packages.
  factory GamePacket.fromJson(Map<String, dynamic> json) =>
      _$GamePacketFromJson(json);

  /// Chuyển thành chuỗi JSON kết thúc bằng '\n' để phân tách gói tin trên stream.
  String toWire() => '${jsonEncode(toJson())}\n';

  /// Tries to parse a raw string payload into a [GamePacket].
  /// Returns null if serialization fails.
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
