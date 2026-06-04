import 'dart:convert';
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:message_pack_dart/message_pack_dart.dart';
import '../utils/app_logger.dart';

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
  factory GamePacket.fromJson(Map<String, dynamic> json) =>
      _$GamePacketFromJson(json);

  /// Serializes packet to MessagePack bytes (~60% smaller than JSON).
  Uint8List toBytes() {
    return serialize(toJson());
  }

  /// Kept for legacy / debug use.
  String toWire() => '${jsonEncode(toJson())}\n';

  /// Deserializes a packet from MessagePack bytes.
  static GamePacket? fromBytes(Uint8List bytes) {
    try {
      final raw = deserialize(bytes);
      if (raw is! Map) return null;
      return GamePacket.fromJson(_toStringDynamic(raw));
    } catch (e) {
      // 6.3 — Log malformed packets so production issues are observable.
      AppLogger.warning(
        'fromBytes: failed to parse packet — $e',
        tag: 'GamePacket',
      );
      return null;
    }
  }

  /// Tries to parse a raw JSON string into a [GamePacket] (legacy / debug).
  static GamePacket? tryParse(String raw) {
    try {
      final json = jsonDecode(raw.trim()) as Map<String, dynamic>;
      return GamePacket.fromJson(json);
    } catch (e) {
      // 6.3 — Log malformed JSON so debug sessions have visibility.
      AppLogger.warning(
        'tryParse: failed to parse "${raw.length > 80 ? raw.substring(0, 80) : raw}" — $e',
        tag: 'GamePacket',
      );
      return null;
    }
  }

  static Map<String, dynamic> _toStringDynamic(Map<dynamic, dynamic> raw) {
    return raw.map(
      (k, v) => MapEntry(
        k.toString(),
        v is Map<dynamic, dynamic>
            ? _toStringDynamic(v)
            : v is List
            ? v
                  .map(
                    (e) => e is Map<dynamic, dynamic> ? _toStringDynamic(e) : e,
                  )
                  .toList()
            : v,
      ),
    );
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
  static const String emote = 'emote';
  static const String haptic = 'haptic';
  static const String chat = 'chat';
  // Console Mode
  static const String controllerInput = 'ctrl_in';
  static const String controllerFeedback = 'ctrl_fb';
  static const String countdownTick = 'cd_tick';
  static const String initController = 'init_ctrl';
  // Spectator
  static const String joinSpectator = 'join_spec';
  static const String spectatorAction = 'spec_act';
  static const String disruption = 'disruption';
  // Spatial audio
  static const String spatialAudio = 'spatial_audio';
  // Archer Duel
  static const String arrowTransfer = 'arrow_transfer';
}
