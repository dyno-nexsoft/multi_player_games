import 'dart:async';
import 'package:nsd/nsd.dart' as nsd;
import '../../../core/network/game_packet.dart';

import 'connection_repository_stub.dart'
    if (dart.library.js_interop) 'web_connection_repository.dart'
    if (dart.library.io) 'io_connection_repository.dart';

typedef OnPacket = void Function(GamePacket packet);
typedef OnClientConnected = void Function(Object client);

/// Tầng data: quản lý mạng.
/// Sử dụng conditional imports để tách biệt hoàn toàn Web và IO.
abstract class ConnectionRepository {
  /// Public constant so other layers can reference the port.
  static const int kPort = 4567;

  factory ConnectionRepository() => getConnectionRepository();

  Stream<nsd.Service> get discoveredServices;

  OnPacket? onPacketReceived;
  OnClientConnected? onClientConnected;
  void Function(Object client, GamePacket packet)? onClientPacket;
  void Function(Object client)? onClientDisconnected;
  void Function()? onHostDisconnected;
  String? webLocalClientId;

  Future<void> startServer(String roomName);
  void broadcastPacket(GamePacket packet);
  void broadcastPacketExcept(GamePacket packet, Object except);
  Future<void> startDiscovery();
  Future<void> connectToService(nsd.Service service);
  Future<void> connectToAddress(String ip, int port);
  void sendToClient(Object client, GamePacket packet);
  void sendPacket(GamePacket packet);
  Future<void> dispose();

  static Future<String?> localIpAddress() => getLocalIpAddress();
}
