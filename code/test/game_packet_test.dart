import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game_hub/core/network/game_packet.dart';

void main() {
  group('GamePacket MessagePack codec', () {
    test('round-trips a simple packet', () {
      const packet = GamePacket(
        type: PacketType.gameData,
        gameId: 'air_hockey',
        senderId: 'abc123',
        timestamp: 1700000000000,
        payload: {'action': 'paddle', 'x': 0.5},
      );

      final decoded = GamePacket.fromBytes(packet.toBytes());

      expect(decoded, isNotNull);
      expect(decoded!.type, PacketType.gameData);
      expect(decoded.gameId, 'air_hockey');
      expect(decoded.senderId, 'abc123');
      expect(decoded.timestamp, 1700000000000);
      expect(decoded.payload['action'], 'paddle');
      expect((decoded.payload['x'] as num).toDouble(), closeTo(0.5, 1e-9));
    });

    test('preserves mixed value types (bool, double, negative int, null)', () {
      const packet = GamePacket(
        type: PacketType.worldState,
        payload: {
          'flag': true,
          'ratio': -3.75,
          'count': -42,
          'big': 9007199254740991,
          'nothing': null,
        },
      );

      final decoded = GamePacket.fromBytes(packet.toBytes())!;

      expect(decoded.payload['flag'], true);
      expect(
        (decoded.payload['ratio'] as num).toDouble(),
        closeTo(-3.75, 1e-9),
      );
      expect(decoded.payload['count'], -42);
      expect(decoded.payload['big'], 9007199254740991);
      expect(decoded.payload['nothing'], isNull);
    });

    test('preserves nested maps and lists', () {
      const packet = GamePacket(
        type: PacketType.endGame,
        payload: {
          'scores': {'p1': 100, 'p2': 0},
          'dice': [1, 2, 3, 4, 5],
          'nested': {
            'list': [
              {'k': 'v'},
            ],
          },
        },
      );

      final decoded = GamePacket.fromBytes(packet.toBytes())!;
      final scores = (decoded.payload['scores'] as Map).cast<String, dynamic>();
      expect(scores['p1'], 100);
      expect(scores['p2'], 0);
      expect((decoded.payload['dice'] as List).cast<int>(), [1, 2, 3, 4, 5]);
      final nestedList = (decoded.payload['nested'] as Map)['list'] as List;
      expect((nestedList.first as Map)['k'], 'v');
    });

    test('omits null gameId/senderId after round-trip', () {
      const packet = GamePacket(type: PacketType.heartbeat);
      final decoded = GamePacket.fromBytes(packet.toBytes())!;
      expect(decoded.gameId, isNull);
      expect(decoded.senderId, isNull);
      expect(decoded.timestamp, 0);
      expect(decoded.payload, isEmpty);
    });

    test('handles a long string (>31 bytes triggers str8/str16 path)', () {
      final longText = 'x' * 500;
      final packet = GamePacket(
        type: PacketType.chat,
        payload: {'text': longText},
      );
      final decoded = GamePacket.fromBytes(packet.toBytes())!;
      expect(decoded.payload['text'], longText);
    });

    test('fromBytes returns null on non-map input', () {
      // 0xc0 = msgpack nil → decodes to a non-Map value → rejected.
      expect(GamePacket.fromBytes(Uint8List.fromList([0xc0])), isNull);
      // Truncated string header → throws internally → caught → null.
      expect(GamePacket.fromBytes(Uint8List.fromList([0xd9, 0x10])), isNull);
    });

    test('tryParse parses JSON and rejects invalid', () {
      final ok = GamePacket.tryParse('{"type":"join","timestamp":5}');
      expect(ok, isNotNull);
      expect(ok!.type, 'join');
      expect(ok.timestamp, 5);

      expect(GamePacket.tryParse('not json'), isNull);
    });

    test('toWire produces newline-terminated JSON', () {
      const packet = GamePacket(type: PacketType.join);
      final wire = packet.toWire();
      expect(wire.endsWith('\n'), isTrue);
      expect(wire.contains('"type":"join"'), isTrue);
    });
  });
}
