import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nsd/nsd.dart' as nsd;
import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';

typedef OnPacket = void Function(GamePacket packet);
typedef OnClientConnected = void Function(Socket socket);

/// Tầng data: quản lý TCP socket và mDNS discovery trực tiếp.
class ConnectionRepository {
  /// Public constant so other layers can reference the port without coupling to ConnectionRepository internals.
  static const int kPort = 4567;
  static const String _serviceType = '_pgamehub._tcp';
  static const int _port = kPort;

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

  /// Host-side: gói tin kèm socket nguồn (để map socket → người chơi).
  void Function(Socket socket, GamePacket packet)? onClientPacket;

  /// Host-side: một client ngắt kết nối.
  void Function(Socket socket)? onClientDisconnected;

  void Function()? onHostDisconnected;

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> startServer(String roomName) async {
    if (kIsWeb) {
      AppLogger.info('Web Mock: Server started for room $roomName', tag: 'Connection');
      return;
    }
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

  void broadcastPacket(GamePacket packet) => _broadcast(packet, null);

  /// Relay tới mọi client trừ [except] (dùng cho host mesh-relay gói của client).
  void broadcastPacketExcept(GamePacket packet, Socket except) =>
      _broadcast(packet, except);

  void _broadcast(GamePacket packet, Socket? except) {
    if (kIsWeb) return;
    final frame = _frame(packet.toBytes());
    // 5.3 — Accumulate dead sockets; remove after iteration to avoid modifying
    // the list while iterating and to stop re-broadcasting to closed sockets.
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

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> startDiscovery() async {
    if (kIsWeb) {
      AppLogger.info('Web Mock: Start discovery', tag: 'Connection');
      return;
    }
    _discovery = await nsd.startDiscovery(_serviceType);
    _discovery!.addServiceListener((service, status) {
      if (status == nsd.ServiceStatus.found) {
        AppLogger.info('Found room: ${service.name}', tag: 'Connection');
        _serviceController.add(service);
      }
    });
  }

  Future<void> connectToService(nsd.Service service) async {
    if (kIsWeb) {
      AppLogger.info('Web Mock: Connecting to service ${service.name}', tag: 'Connection');
      return;
    }
    final addrs = service.addresses;
    final host = service.host ?? (addrs != null && addrs.isNotEmpty ? addrs.first.address : null);
    final port = service.port ?? _port;
    if (host == null) throw Exception('Cannot resolve host address');

    // 5.4 — Timeout prevents hanging forever when the host is unreachable.
    _hostSocket = await Socket.connect(host, port).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException(
        'Connection to $host:$port timed out after 10s',
      ),
    );
    AppLogger.info('Connected to host $host:$port', tag: 'Connection');
    _listenSocket(_hostSocket!, onDone: () => onHostDisconnected?.call());
  }

  Future<void> connectToAddress(String ip, int port) async {
    if (kIsWeb) {
      AppLogger.info('Web Mock: Connecting to address $ip:$port', tag: 'Connection');
      return;
    }
    // 5.4 — Timeout prevents hanging forever when the host is unreachable.
    _hostSocket = await Socket.connect(ip, port).timeout(
      const Duration(seconds: 10),
      onTimeout: () =>
          throw TimeoutException('QR-connect to $ip:$port timed out after 10s'),
    );
    AppLogger.info('QR-connected to $ip:$port', tag: 'Connection');
    _listenSocket(_hostSocket!, onDone: () => onHostDisconnected?.call());
  }

  static Future<String?> localIpAddress() async {
    if (kIsWeb) return '127.0.0.1';
    for (final iface in await NetworkInterface.list()) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  /// 4.3 — Send a packet directly to one specific client socket (unicast).
  /// Used by host to target a single controller without broadcasting to all.
  void sendToClient(Socket socket, GamePacket packet) {
    if (kIsWeb) return;
    try {
      socket.add(_frame(packet.toBytes()));
    } catch (e) {
      AppLogger.warning('sendToClient failed: $e', tag: 'Connection');
      _clients.remove(socket);
      socket.close().ignore();
    }
  }

  void sendPacket(GamePacket packet) {
    if (kIsWeb) return;
    try {
      _hostSocket?.add(_frame(packet.toBytes()));
    } catch (e) {
      AppLogger.warning('sendPacket failed: $e', tag: 'Connection');
      _hostSocket?.close().ignore();
      _hostSocket = null;
    }
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  void _listenSocket(
    Socket socket, {
    void Function()? onDone,
    void Function(GamePacket packet)? onPacket,
  }) {
    if (kIsWeb) return;
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

  Future<void> dispose() async {
    if (kIsWeb) return;
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
