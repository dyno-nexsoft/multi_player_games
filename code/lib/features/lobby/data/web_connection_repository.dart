import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:nsd/nsd.dart' as nsd;
import 'package:web/web.dart' as web;
import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';
import 'connection_repository.dart';

ConnectionRepository getConnectionRepository() => WebConnectionRepository();
Future<String?> getLocalIpAddress() async => '127.0.0.1';

class WebConnectionRepository implements ConnectionRepository {
  static const String _webRoomChannel = 'pgamehub_web_room';
  web.BroadcastChannel? _webChannel;
  final Set<String> _webKnownClients = {};

  final StreamController<nsd.Service> _serviceController =
      StreamController.broadcast();

  @override
  Stream<nsd.Service> get discoveredServices => _serviceController.stream;

  @override
  OnPacket? onPacketReceived;

  @override
  OnClientConnected? onClientConnected;

  @override
  void Function(Object client, GamePacket packet)? onClientPacket;

  @override
  void Function(Object client)? onClientDisconnected;

  @override
  void Function()? onHostDisconnected;

  @override
  String? webLocalClientId;

  @override
  Future<void> startServer(String roomName) async {
    AppLogger.info(
      'Web: Server started via BroadcastChannel',
      tag: 'Connection',
    );
    _webChannel = web.BroadcastChannel(_webRoomChannel);
    _webChannel!.onmessage = ((web.MessageEvent event) {
      final dartData = event.data.dartify();
      AppLogger.info(
        'Host received dartData: $dartData',
        tag: 'ConnectionDebug',
      );
      if (dartData is String) {
        final str = dartData;
        final splitIndex = str.indexOf('|');
        if (splitIndex == -1) return;
        final target = str.substring(0, splitIndex);
        final payloadStr = str.substring(splitIndex + 1);

        AppLogger.info(
          'Host parsed target: $target, payload length: ${payloadStr.length}',
          tag: 'ConnectionDebug',
        );

        if (target != 'HOST') return;

        final packet = GamePacket.tryParse(payloadStr);
        if (packet != null) {
          final sender = packet.senderId ?? 'unknown';
          if (!_webKnownClients.contains(sender)) {
            _webKnownClients.add(sender);
            onClientConnected?.call(sender);
          }
          onClientPacket?.call(sender, packet);
        }
      }
    }).toJS;
  }

  @override
  void broadcastPacket(GamePacket packet) {
    final json = jsonEncode(packet.toJson());
    _webChannel?.postMessage('ALL|$json'.toJS);
  }

  @override
  void broadcastPacketExcept(GamePacket packet, Object except) {
    final json = jsonEncode(packet.toJson());
    for (final client in _webKnownClients) {
      if (client != except) {
        _webChannel?.postMessage('$client|$json'.toJS);
      }
    }
  }

  @override
  Future<void> startDiscovery() async {
    AppLogger.info('Web: Mocking discovery', tag: 'Connection');
    Future.delayed(const Duration(milliseconds: 500), () {
      _serviceController.add(
        nsd.Service(name: 'Phòng Web Local', type: '_pgamehub._tcp'),
      );
    });
  }

  @override
  Future<void> connectToService(nsd.Service service) async {
    AppLogger.info('Web: Connecting via BroadcastChannel', tag: 'Connection');
    _webChannel = web.BroadcastChannel(_webRoomChannel);
    _webChannel!.onmessage = ((web.MessageEvent event) {
      final dartData = event.data.dartify();
      AppLogger.info(
        'Client received dartData: $dartData',
        tag: 'ConnectionDebug',
      );
      if (dartData is String) {
        final str = dartData;
        final splitIndex = str.indexOf('|');
        if (splitIndex == -1) return;
        final target = str.substring(0, splitIndex);
        final payloadStr = str.substring(splitIndex + 1);

        AppLogger.info(
          'Client parsed target: $target, myId: $webLocalClientId',
          tag: 'ConnectionDebug',
        );

        if (target != 'ALL' && target != webLocalClientId) return;

        final packet = GamePacket.tryParse(payloadStr);
        if (packet != null) onPacketReceived?.call(packet);
      }
    }).toJS;
  }

  @override
  Future<void> connectToAddress(String ip, int port) async {
    await connectToService(nsd.Service(name: 'Web'));
  }

  @override
  void sendToClient(Object client, GamePacket packet) {
    if (client is String) {
      final json = jsonEncode(packet.toJson());
      _webChannel?.postMessage('$client|$json'.toJS);
    }
  }

  @override
  void sendPacket(GamePacket packet) {
    final json = jsonEncode(packet.toJson());
    _webChannel?.postMessage('HOST|$json'.toJS);
  }

  @override
  Future<void> dispose() async {
    _webChannel?.close();
    await _serviceController.close();
  }
}
