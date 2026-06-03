import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nsd/nsd.dart' as nsd;

typedef PacketHandler = void Function(String rawJson);

/// Wrapper quản lý đăng ký và quét mDNS/Bonjour, kết nối TCP.
class NetworkService {
  static const String _serviceType = '_pgamehub._tcp';
  static const int defaultPort = 4567;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  ServerSocket? _serverSocket;
  final List<Socket> _connectedClients = [];
  Socket? _clientSocket;

  final StreamController<nsd.Service> _discoveredController =
      StreamController.broadcast();
  Stream<nsd.Service> get onServiceDiscovered => _discoveredController.stream;

  PacketHandler? onPacketReceived;

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> startHosting({
    required String roomName,
    int port = defaultPort,
  }) async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket!.listen(_handleIncomingConnection);

    _registration = await nsd.register(
      nsd.Service(name: roomName, type: _serviceType, port: port),
    );
  }

  void _handleIncomingConnection(Socket socket) {
    _connectedClients.add(socket);
    _listenToSocket(
      socket,
      onDisconnect: () => _connectedClients.remove(socket),
    );
  }

  void broadcastToClients(String wireData) {
    for (final socket in List.of(_connectedClients)) {
      try {
        socket.write(wireData);
      } catch (_) {}
    }
  }

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> beginDiscovery() async {
    _discovery = await nsd.startDiscovery(_serviceType);
    _discovery!.addServiceListener((service, status) {
      if (status == nsd.ServiceStatus.found) {
        _discoveredController.add(service);
      }
    });
  }

  Future<void> connectToHost(String host, int port) async {
    _clientSocket = await Socket.connect(host, port);
    _listenToSocket(_clientSocket!);
  }

  void sendToHost(String wireData) {
    _clientSocket?.write(wireData);
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  void _listenToSocket(Socket socket, {void Function()? onDisconnect}) {
    final buffer = StringBuffer();
    utf8.decoder
        .bind(socket)
        .listen(
          (data) {
            buffer.write(data);
            final raw = buffer.toString();
            final lines = raw.split('\n');
            buffer.clear();
            if (!raw.endsWith('\n')) {
              buffer.write(lines.removeLast());
            } else {
              lines.removeLast();
            }
            for (final line in lines) {
              if (line.isNotEmpty) onPacketReceived?.call(line);
            }
          },
          onDone: onDisconnect,
          onError: (_) => onDisconnect?.call(),
        );
  }

  Future<void> dispose() async {
    if (_registration != null) await nsd.unregister(_registration!);
    if (_discovery != null) await nsd.stopDiscovery(_discovery!);
    for (final s in _connectedClients) {
      await s.close();
    }
    await _clientSocket?.close();
    await _serverSocket?.close();
    await _discoveredController.close();
  }
}
