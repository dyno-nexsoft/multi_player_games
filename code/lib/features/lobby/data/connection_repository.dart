import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nsd/nsd.dart' as nsd;
import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';

typedef OnPacket = void Function(GamePacket packet);
typedef OnClientConnected = void Function(Socket socket);

/// Tầng data: quản lý TCP socket và mDNS discovery trực tiếp.
class ConnectionRepository {
  static const String _serviceType = '_pgamehub._tcp';
  static const int _port = 4567;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  Socket? _hostSocket;

  final StreamController<nsd.Service> _serviceController =
      StreamController.broadcast();
  Stream<nsd.Service> get discoveredServices => _serviceController.stream;

  OnPacket? onPacketReceived;
  OnClientConnected? onClientConnected;

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> startServer(String roomName) async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
    AppLogger.info('Server listening on port $_port', tag: 'Connection');

    _serverSocket!.listen((socket) {
      AppLogger.info(
        'Client connected: ${socket.remoteAddress.address}',
        tag: 'Connection',
      );
      _clients.add(socket);
      onClientConnected?.call(socket);
      _listenSocket(
        socket,
        onDone: () {
          _clients.remove(socket);
          AppLogger.info('Client disconnected', tag: 'Connection');
        },
      );
    });

    _registration = await nsd.register(
      nsd.Service(name: roomName, type: _serviceType, port: _port),
    );
    AppLogger.info('NSD registered: $roomName', tag: 'Connection');
  }

  void broadcastPacket(GamePacket packet) {
    final wire = packet.toWire();
    for (final s in List.of(_clients)) {
      try {
        s.write(wire);
      } catch (e) {
        AppLogger.warning('Broadcast failed: $e', tag: 'Connection');
      }
    }
  }

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> startDiscovery() async {
    _discovery = await nsd.startDiscovery(_serviceType);
    _discovery!.addServiceListener((service, status) {
      if (status == nsd.ServiceStatus.found) {
        AppLogger.info('Found room: ${service.name}', tag: 'Connection');
        _serviceController.add(service);
      }
    });
  }

  Future<void> connectToService(nsd.Service service) async {
    final host = service.host ?? service.addresses?.first.address;
    final port = service.port ?? _port;
    if (host == null) throw Exception('Cannot resolve host address');

    _hostSocket = await Socket.connect(host, port);
    AppLogger.info('Connected to host $host:$port', tag: 'Connection');
    _listenSocket(_hostSocket!);
  }

  void sendPacket(GamePacket packet) {
    _hostSocket?.write(packet.toWire());
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  void _listenSocket(Socket socket, {void Function()? onDone}) {
    final buffer = StringBuffer();
    utf8.decoder
        .bind(socket)
        .listen(
          (chunk) {
            buffer.write(chunk);
            final raw = buffer.toString();
            final lines = raw.split('\n');
            buffer.clear();
            if (!raw.endsWith('\n')) {
              buffer.write(lines.removeLast());
            } else {
              lines.removeLast();
            }
            for (final line in lines) {
              if (line.isEmpty) continue;
              final packet = GamePacket.tryParse(line);
              if (packet != null) onPacketReceived?.call(packet);
            }
          },
          onDone: onDone,
          onError: (e) {
            AppLogger.error('Socket error', error: e, tag: 'Connection');
            onDone?.call();
          },
        );
  }

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
