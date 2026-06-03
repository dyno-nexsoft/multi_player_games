import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';
import '../data/connection_repository.dart';
import '../domain/player.dart';

enum LobbyState { idle, hosting, discovering, inRoom, inGame }

/// Quản lý toàn bộ vòng đời kết nối phòng chờ (Socket server/client, danh sách người chơi).
class LobbyProvider extends ChangeNotifier {
  final ConnectionRepository _repo = ConnectionRepository();

  LobbyState _state = LobbyState.idle;
  LobbyState get state => _state;

  Player? _localPlayer;
  Player? get localPlayer => _localPlayer;
  bool get isHost => _localPlayer?.isHost ?? false;

  final List<Player> _players = [];
  List<Player> get players => List.unmodifiable(_players);

  final List<Service> _discoveredRooms = [];
  List<Service> get discoveredRooms => List.unmodifiable(_discoveredRooms);

  StreamSubscription<Service>? _discoverySubscription;

  String? _pendingGameId;
  String? get pendingGameId => _pendingGameId;

  /// Callback để GameProvider đăng ký nhận gói tin trong lúc chơi.
  OnPacket? onGamePacket;

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> hostRoom(String playerName, String roomName) async {
    _localPlayer = Player(id: _generateId(), name: playerName, isHost: true);
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
      payload: {'game_id': gameId},
    );
    _repo.broadcastPacket(packet);
    _pendingGameId = gameId;
    _state = LobbyState.inGame;
    notifyListeners();
  }

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> discoverRooms(String playerName) async {
    _localPlayer = Player(id: _generateId(), name: playerName);
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

  Future<void> joinRoom(Service service) async {
    await _repo.connectToService(service);
    final packet = GamePacket(
      type: PacketType.join,
      senderId: _localPlayer!.id,
      timestamp: _now(),
      payload: {'name': _localPlayer!.name},
    );
    _repo.sendPacket(packet);
    _state = LobbyState.inRoom;
    notifyListeners();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _handleIncomingPacket(GamePacket packet) {
    switch (packet.type) {
      case PacketType.join:
        final player = Player(
          id: packet.senderId ?? _generateId(),
          name: packet.payload['name'] as String? ?? 'Player',
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
        _state = LobbyState.inGame;
        notifyListeners();
      case PacketType.gameData:
      case PacketType.worldState:
        onGamePacket?.call(packet);
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
