import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';
import '../data/connection_repository.dart';
import '../domain/player.dart';

enum LobbyState { idle, hosting, discovering, inRoom, inGame, reconnecting }

/// Quản lý toàn bộ vòng đời kết nối phòng chờ (Socket server/client, danh sách người chơi).
class LobbyProvider extends ChangeNotifier {
  final ConnectionRepository _repo = ConnectionRepository();

  LobbyState _state = LobbyState.idle;
  LobbyState get state => _state;

  Player? _localPlayer;
  Player? get localPlayer => _localPlayer;
  bool get isHost => _localPlayer?.isHost ?? false;

  int _selectedColor = 0xFF6C63FF;
  int get selectedColor => _selectedColor;

  void setColor(int color) {
    _selectedColor = color;
    notifyListeners();
  }

  final List<Player> _players = [];
  List<Player> get players => List.unmodifiable(_players);

  final List<Service> _discoveredRooms = [];
  List<Service> get discoveredRooms => List.unmodifiable(_discoveredRooms);

  StreamSubscription<Service>? _discoverySubscription;

  String? _pendingGameId;
  String? get pendingGameId => _pendingGameId;

  /// Tăng mỗi khi game được bắt đầu (kể cả rematch cùng game).
  /// GameHubScreen dùng để phát hiện khi nào cần launch game mới.
  int _gameStartToken = 0;
  int get gameStartToken => _gameStartToken;

  int _seriesLength = 1;
  int get seriesLength => _seriesLength;

  void setSeriesLength(int n) {
    if (!isHost) return;
    _seriesLength = n;
    notifyListeners();
  }

  /// Callback để GameProvider đăng ký nhận gói tin trong lúc chơi.
  OnPacket? onGamePacket;

  /// Callback để EmoteLayer nhận emoji từ đối thủ.
  void Function(String emoji)? onEmoteReceived;

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> hostRoom(String playerName, String roomName) async {
    _localPlayer = Player(
      id: _generateId(),
      name: playerName,
      isHost: true,
      color: _selectedColor,
      playerIndex: 0,
    );
    _players
      ..clear()
      ..add(_localPlayer!);

    _repo.onPacketReceived = _handleIncomingPacket;
    _repo.onClientConnected = (_) => _syncLobby();

    await _repo.startServer(roomName);
    _state = LobbyState.hosting;
    notifyListeners();
  }

  void startGame(String gameId) {
    if (!isHost) return;
    final packet = GamePacket(
      type: PacketType.startGame,
      timestamp: _now(),
      payload: {'game_id': gameId, 'series_length': _seriesLength},
    );
    _repo.broadcastPacket(packet);
    _pendingGameId = gameId;
    _gameStartToken++;
    _state = LobbyState.inGame;
    notifyListeners();
  }

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> discoverRooms(String playerName) async {
    _localPlayer = Player(
      id: _generateId(),
      name: playerName,
      color: _selectedColor,
    );
    _discoveredRooms.clear();
    _repo.onPacketReceived = _handleIncomingPacket;

    await _discoverySubscription?.cancel();
    _discoverySubscription = _repo.discoveredServices.listen((service) {
      _discoveredRooms.add(service);
      notifyListeners();
    });

    await _repo.startDiscovery();
    _state = LobbyState.discovering;
    notifyListeners();
  }

  Service? _lastJoinedService;

  Future<void> joinRoom(Service service) async {
    _lastJoinedService = service;
    _repo.onHostDisconnected = _onHostDisconnected;
    await _repo.connectToService(service);
    final packet = GamePacket(
      type: PacketType.join,
      senderId: _localPlayer!.id,
      timestamp: _now(),
      payload: {'name': _localPlayer!.name, 'color': _localPlayer!.color},
    );
    _repo.sendPacket(packet);
    _state = LobbyState.inRoom;
    notifyListeners();
  }

  Future<void> joinRoomByAddress(String ip, int port) async {
    _repo.onPacketReceived = _handleIncomingPacket;
    _repo.onHostDisconnected = _onHostDisconnected;
    await _repo.connectToAddress(ip, port);
    final packet = GamePacket(
      type: PacketType.join,
      senderId: _localPlayer!.id,
      timestamp: _now(),
      payload: {'name': _localPlayer!.name, 'color': _localPlayer!.color},
    );
    _repo.sendPacket(packet);
    _state = LobbyState.inRoom;
    notifyListeners();
  }

  Future<String?> getHostIp() => ConnectionRepository.localIpAddress();

  // ── Internal ──────────────────────────────────────────────────────────────

  void _handleIncomingPacket(GamePacket packet) {
    switch (packet.type) {
      case PacketType.join:
        final player = Player(
          id: packet.senderId ?? _generateId(),
          name: packet.payload['name'] as String? ?? 'Player',
          color: (packet.payload['color'] as int?) ?? 0xFF6C63FF,
          playerIndex: _players.length, // host is 0, first joiner is 1, etc.
        );
        _players.add(player);
        notifyListeners();
        _syncLobby();
      case PacketType.lobbySync:
        final list = packet.payload['players'] as List<dynamic>?;
        if (list != null) {
          _players
            ..clear()
            ..addAll(
              list.map((e) => Player.fromJson(e as Map<String, dynamic>)),
            );
          notifyListeners();
        }
      case PacketType.startGame:
        _pendingGameId = packet.payload['game_id'] as String?;
        _seriesLength = (packet.payload['series_length'] as int?) ?? 1;
        _gameStartToken++;
        _state = LobbyState.inGame;
        notifyListeners();
      case PacketType.gameData:
      case PacketType.worldState:
        onGamePacket?.call(packet);
      case PacketType.emote:
        final emoji = packet.payload['emoji'] as String?;
        if (emoji != null) onEmoteReceived?.call(emoji);
        // Host relays emote to all other clients
        if (isHost) _repo.broadcastPacket(packet);
      default:
        AppLogger.info('Unhandled packet: ${packet.type}', tag: 'Lobby');
    }
  }

  void _syncLobby() {
    final packet = GamePacket(
      type: PacketType.lobbySync,
      timestamp: _now(),
      payload: {'players': _players.map((p) => p.toJson()).toList()},
    );
    _repo.broadcastPacket(packet);
  }

  void sendGamePacket(GamePacket packet) {
    if (isHost) {
      _repo.broadcastPacket(packet);
    } else {
      _repo.sendPacket(packet);
    }
  }

  void returnToLobby() {
    _pendingGameId = null;
    _state = LobbyState.inRoom;
    notifyListeners();
  }

  // ── Reconnect ──────────────────────────────────────────────────────────────

  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 3;
  static const _reconnectDelays = [1, 2, 4]; // seconds

  void _onHostDisconnected() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _lastJoinedService == null) {
      _state = LobbyState.idle;
      notifyListeners();
      return;
    }
    _state = LobbyState.reconnecting;
    notifyListeners();
    _scheduleReconnect();
  }

  Future<void> _scheduleReconnect() async {
    final delay = _reconnectDelays[_reconnectAttempts.clamp(0, 2)];
    _reconnectAttempts++;
    await Future.delayed(Duration(seconds: delay));
    try {
      await _repo.connectToService(_lastJoinedService!);
      final packet = GamePacket(
        type: PacketType.join,
        senderId: _localPlayer!.id,
        timestamp: _now(),
        payload: {'name': _localPlayer!.name, 'color': _localPlayer!.color},
      );
      _repo.sendPacket(packet);
      _reconnectAttempts = 0;
      _state = LobbyState.inRoom;
      AppLogger.info('Reconnected to host', tag: 'Lobby');
    } catch (_) {
      _onHostDisconnected(); // retry
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _repo.dispose();
    super.dispose();
  }

  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(16);

  int _now() => DateTime.now().millisecondsSinceEpoch;
}
