import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nsd/nsd.dart' as nsd;
import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';
import 'connection_repository.dart';

ConnectionRepository getConnectionRepository() => IoConnectionRepository();

Future<String?> getLocalIpAddress() async {
  for (final iface in await NetworkInterface.list()) {
    for (final addr in iface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return null;
}

class IoConnectionRepository implements ConnectionRepository {
  static const String _serviceType = '_pgamehub._tcp';
  static const int _port = ConnectionRepository.kPort;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  Socket? _hostSocket;

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
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
    AppLogger.info('Server listening on port $_port', tag: 'Connection');

    _serverSocket!.listen(
      (socket) {
        AppLogger.info(
          'Client connected: ${socket.remoteAddress.address}',
          tag: 'Connection',
        );
        _clients.add(socket);
        onClientConnected?.call(socket);
        _listenSocket(
          socket,
          onPacket: (packet) => onClientPacket?.call(socket, packet),
          onDone: () {
            _clients.remove(socket);
            onClientDisconnected?.call(socket);
            AppLogger.info('Client disconnected', tag: 'Connection');
          },
        );
      },
      onError: (e) =>
          AppLogger.error('Server socket error', error: e, tag: 'Connection'),
    );

    _registration = await nsd.register(
      nsd.Service(name: roomName, type: _serviceType, port: _port),
    );
    AppLogger.info('NSD registered: $roomName', tag: 'Connection');
  }

  @override
  void broadcastPacket(GamePacket packet) {
    _broadcast(packet, null);
  }

  @override
  void broadcastPacketExcept(GamePacket packet, Object except) {
    _broadcast(packet, except);
  }

  void _broadcast(GamePacket packet, Object? except) {
    final frame = _frame(packet.toBytes());
    final deadSockets = <Socket>[];
    for (final s in List.of(_clients)) {
      if (except != null && identical(s, except)) continue;
      try {
        s.add(frame);
      } catch (e) {
        AppLogger.warning('Broadcast failed: $e', tag: 'Connection');
        deadSockets.add(s);
      }
    }
    for (final s in deadSockets) {
      _clients.remove(s);
      s.close().ignore();
    }
  }

  static Uint8List _frame(Uint8List payload) {
    final header = Uint8List(4);
    ByteData.view(header.buffer).setUint32(0, payload.length, Endian.big);
    return Uint8List.fromList([...header, ...payload]);
  }

  @override
  Future<void> startDiscovery() async {
    _discovery = await nsd.startDiscovery(_serviceType);
    _discovery!.addServiceListener((service, status) {
      if (status == nsd.ServiceStatus.found) {
        AppLogger.info('Found room: ${service.name}', tag: 'Connection');
        _serviceController.add(service);
      }
    });
  }

  @override
  Future<void> connectToService(nsd.Service service) async {
    final addrs = service.addresses;
    final host =
        service.host ??
        (addrs != null && addrs.isNotEmpty ? addrs.first.address : null);
    final port = service.port ?? _port;
    if (host == null) throw Exception('Cannot resolve host address');

    _hostSocket = await Socket.connect(host, port).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException(
        'Connection to $host:$port timed out after 10s',
      ),
    );
    AppLogger.info('Connected to host $host:$port', tag: 'Connection');
    _listenSocket(_hostSocket!, onDone: () => onHostDisconnected?.call());
  }

  @override
  Future<void> connectToAddress(String ip, int port) async {
    _hostSocket = await Socket.connect(ip, port).timeout(
      const Duration(seconds: 10),
      onTimeout: () =>
          throw TimeoutException('QR-connect to $ip:$port timed out after 10s'),
    );
    AppLogger.info('QR-connected to $ip:$port', tag: 'Connection');
    _listenSocket(_hostSocket!, onDone: () => onHostDisconnected?.call());
  }

  @override
  void sendToClient(Object client, GamePacket packet) {
    if (client is Socket) {
      try {
        client.add(_frame(packet.toBytes()));
      } catch (e) {
        AppLogger.warning('sendToClient failed: $e', tag: 'Connection');
        _clients.remove(client);
        client.close().ignore();
      }
    }
  }

  @override
  void sendPacket(GamePacket packet) {
    try {
      _hostSocket?.add(_frame(packet.toBytes()));
    } catch (e) {
      AppLogger.warning('sendPacket failed: $e', tag: 'Connection');
      _hostSocket?.close().ignore();
      _hostSocket = null;
    }
  }

  void _listenSocket(
    Socket socket, {
    void Function()? onDone,
    void Function(GamePacket packet)? onPacket,
  }) {
    final buf = <int>[];
    socket.listen(
      (data) {
        buf.addAll(data);
        while (buf.length >= 4) {
          final len = ByteData.view(
            Uint8List.fromList(buf.sublist(0, 4)).buffer,
          ).getUint32(0, Endian.big);
          if (buf.length < 4 + len) break;
          final payload = Uint8List.fromList(buf.sublist(4, 4 + len));
          buf.removeRange(0, 4 + len);
          final packet = GamePacket.fromBytes(payload);
          if (packet != null) (onPacket ?? onPacketReceived)?.call(packet);
        }
      },
      onDone: onDone,
      onError: (e) {
        AppLogger.error('Socket error', error: e, tag: 'Connection');
        onDone?.call();
      },
    );
  }

  @override
  Future<void> dispose() async {
    if (_registration != null) await nsd.unregister(_registration!);
    if (_discovery != null) await nsd.stopDiscovery(_discovery!);
    for (final s in _clients) {
      await s.close();
    }
    await _hostSocket?.close();
    await _serverSocket?.close();
    await _serviceController.close();
  }
}
