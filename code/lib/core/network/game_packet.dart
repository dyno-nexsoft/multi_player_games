import 'dart:convert';
import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:messagepack/messagepack.dart';

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
    final p = Packer();
    _packValue(p, toJson());
    return p.takeBytes();
  }

  /// Kept for legacy / debug use.
  String toWire() => '${jsonEncode(toJson())}\n';

  /// Deserializes a packet from MessagePack bytes.
  static GamePacket? fromBytes(Uint8List bytes) {
    try {
      final (raw, _) = _msgDecode(bytes, 0);
      if (raw is! Map) return null;
      return GamePacket.fromJson(_toStringDynamic(raw));
    } catch (_) {
      return null;
    }
  }

  /// Tries to parse a raw JSON string into a [GamePacket] (legacy / debug).
  static GamePacket? tryParse(String raw) {
    try {
      final json = jsonDecode(raw.trim()) as Map<String, dynamic>;
      return GamePacket.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // ── MessagePack encoder ───────────────────────────────────────────────────

  static void _packValue(Packer p, dynamic v) {
    if (v == null) {
      p.packNull();
    } else if (v is bool) {
      p.packBool(v);
    } else if (v is int) {
      p.packInt(v);
    } else if (v is double) {
      p.packDouble(v);
    } else if (v is String) {
      p.packString(v);
    } else if (v is List) {
      p.packListLength(v.length);
      for (final e in v) {
        _packValue(p, e);
      }
    } else if (v is Map) {
      p.packMapLength(v.length);
      v.forEach((k, val) {
        _packValue(p, k);
        _packValue(p, val);
      });
    } else {
      p.packString(v.toString());
    }
  }

  // ── MessagePack decoder ───────────────────────────────────────────────────
  // Custom decoder because messagepack 0.2.x Unpacker lacks unpackValue().

  static (dynamic, int) _msgDecode(Uint8List d, int i) {
    final b = d[i];
    if (b < 0x80) return (b, i + 1); // positive fixint
    if (b >= 0xe0) return (b - 256, i + 1); // negative fixint
    if (b & 0xf0 == 0x80) return _decodeMap(d, i + 1, b & 0x0f); // fixmap
    if (b & 0xf0 == 0x90) return _decodeList(d, i + 1, b & 0x0f); // fixarray
    if (b & 0xe0 == 0xa0) { // fixstr
      final n = b & 0x1f;
      return (utf8.decode(d.sublist(i + 1, i + 1 + n)), i + 1 + n);
    }
    switch (b) {
      case 0xc0: return (null, i + 1);
      case 0xc2: return (false, i + 1);
      case 0xc3: return (true, i + 1);
      case 0xca: // float32
        return (ByteData.sublistView(d, i + 1, i + 5).getFloat32(0, Endian.big), i + 5);
      case 0xcb: // float64
        return (ByteData.sublistView(d, i + 1, i + 9).getFloat64(0, Endian.big), i + 9);
      case 0xcc: return (d[i + 1], i + 2); // uint8
      case 0xcd: // uint16
        return (ByteData.sublistView(d, i + 1, i + 3).getUint16(0, Endian.big), i + 3);
      case 0xce: // uint32
        return (ByteData.sublistView(d, i + 1, i + 5).getUint32(0, Endian.big), i + 5);
      case 0xcf: // uint64
        return (ByteData.sublistView(d, i + 1, i + 9).getUint64(0, Endian.big), i + 9);
      case 0xd0: // int8
        return (ByteData.sublistView(d, i + 1, i + 2).getInt8(0), i + 2);
      case 0xd1: // int16
        return (ByteData.sublistView(d, i + 1, i + 3).getInt16(0, Endian.big), i + 3);
      case 0xd2: // int32
        return (ByteData.sublistView(d, i + 1, i + 5).getInt32(0, Endian.big), i + 5);
      case 0xd3: // int64
        return (ByteData.sublistView(d, i + 1, i + 9).getInt64(0, Endian.big), i + 9);
      case 0xd9: // str8
        final n = d[i + 1];
        return (utf8.decode(d.sublist(i + 2, i + 2 + n)), i + 2 + n);
      case 0xda: // str16
        final n = ByteData.sublistView(d, i + 1, i + 3).getUint16(0, Endian.big);
        return (utf8.decode(d.sublist(i + 3, i + 3 + n)), i + 3 + n);
      case 0xdb: // str32
        final n = ByteData.sublistView(d, i + 1, i + 5).getUint32(0, Endian.big);
        return (utf8.decode(d.sublist(i + 5, i + 5 + n)), i + 5 + n);
      case 0xdc: // array16
        final n = ByteData.sublistView(d, i + 1, i + 3).getUint16(0, Endian.big);
        return _decodeList(d, i + 3, n);
      case 0xdd: // array32
        final n = ByteData.sublistView(d, i + 1, i + 5).getUint32(0, Endian.big);
        return _decodeList(d, i + 5, n);
      case 0xde: // map16
        final n = ByteData.sublistView(d, i + 1, i + 3).getUint16(0, Endian.big);
        return _decodeMap(d, i + 3, n);
      case 0xdf: // map32
        final n = ByteData.sublistView(d, i + 1, i + 5).getUint32(0, Endian.big);
        return _decodeMap(d, i + 5, n);
      default:
        throw FormatException('Unknown msgpack byte 0x${b.toRadixString(16)}');
    }
  }

  static (List<dynamic>, int) _decodeList(Uint8List d, int i, int n) {
    final list = <dynamic>[];
    for (int k = 0; k < n; k++) {
      final (v, next) = _msgDecode(d, i);
      list.add(v);
      i = next;
    }
    return (list, i);
  }

  static (Map<dynamic, dynamic>, int) _decodeMap(Uint8List d, int i, int n) {
    final map = <dynamic, dynamic>{};
    for (int k = 0; k < n; k++) {
      final (key, i2) = _msgDecode(d, i);
      final (val, i3) = _msgDecode(d, i2);
      map[key] = val;
      i = i3;
    }
    return (map, i);
  }

  static Map<String, dynamic> _toStringDynamic(Map<dynamic, dynamic> raw) {
    return raw.map((k, v) => MapEntry(
      k.toString(),
      v is Map<dynamic, dynamic>
          ? _toStringDynamic(v)
          : v is List
              ? v.map((e) => e is Map<dynamic, dynamic> ? _toStringDynamic(e) : e).toList()
              : v,
    ));
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
}
