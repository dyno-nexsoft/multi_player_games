import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';

import '../../../core/network/game_packet.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/emoji_code.dart';
import '../data/connection_repository.dart';
import '../domain/player.dart';

enum LobbyState {
  idle,
  hosting,
  discovering,
  inRoom,
  inGame,
  inConsole,
  reconnecting,
}

/// Quản lý toàn bộ vòng đời kết nối phòng chờ (Socket server/client, danh sách người chơi).
class LobbyProvider extends ChangeNotifier {
  ConnectionRepository _repo = ConnectionRepository();

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

  bool _isTournamentMode = false;
  bool get isTournamentMode => _isTournamentMode;

  void setTournamentMode(bool enabled) {
    if (!isHost) return;
    _isTournamentMode = enabled;
    if (enabled) {
      _seriesLength = 5; // Best of 5
    } else {
      _seriesLength = 1;
    }
    notifyListeners();
  }

  void setSeriesLength(int n) {
    if (!isHost) return;
    _seriesLength = n;
    notifyListeners();
  }

  /// Callback để GameProvider đăng ký nhận gói tin trong lúc chơi.
  OnPacket? onGamePacket;

  /// Callback để GameProvider nhận kết quả ván đấu (host broadcast authoritative).
  OnPacket? onGameEnded;

  /// Host-side: map socket → playerId để dọn dẹp khi client ngắt kết nối.
  final Map<Socket, String> _socketPlayers = {};

  // ── Console Mode ──────────────────────────────────────────────────────────

  bool _isConsoleMode = false;

  /// True khi Host tạo phòng ở chế độ Màn Hình Lớn (Console).
  bool get isConsoleMode => _isConsoleMode;

  /// 4-emoji code của phòng (host). VD: "🍕🚀👽🔥"
  String _emojiCode = '';
  String get emojiCode => _emojiCode;

  /// Callback khi host nhận input từ tay cầm (joystick, buttons, gyro).
  /// playerId = người gửi, payload = dữ liệu input.
  void Function(String playerId, Map<String, dynamic> payload)?
  onControllerInput;

  /// Callback khi client (tay cầm) nhận feedback từ host (haptic + flash).
  void Function(String hapticType, int? flashColor)? onControllerFeedback;

  /// Callback khi client nhận tick đếm ngược từ host (3, 2, 1, 0=GO).
  void Function(int tick)? onCountdownTick;

  /// ValueNotifier cập nhật mỗi khi nhận tick đếm ngược — CountdownScreen đọc trực tiếp.
  final ValueNotifier<int> countdownTickNotifier = ValueNotifier(0);

  /// Callback khi client nhận cấu hình tay cầm từ host (labels, highlight…).
  void Function(Map<String, dynamic> config)? onControllerInit;
  void Function()? onSystemPause;

  // ── Spectator ─────────────────────────────────────────────────────────────

  bool _iAmSpectator = false;
  bool get iAmSpectator => _iAmSpectator;

  /// Callback khi nhận hiệu ứng phá đám từ khán giả (type: 'tomato'|'smoke'|'ice').
  void Function(String type)? onDisruption;

  void sendSpectatorAction(String type) {
    sendGamePacket(
      GamePacket(
        type: PacketType.spectatorAction,
        senderId: _localPlayer?.id,
        timestamp: _now(),
        payload: {'type': type},
      ),
    );
  }

  // ── Spatial audio ────────────────────────────────────────────────────────

  /// Callback khi nhận lệnh phát/dừng âm thanh vòng lặp (action:'play'|'stop', sound: filename).
  void Function(String action, String sound)? onSpatialAudio;

  void sendSpatialAudio({required String action, required String sound}) {
    sendGamePacket(
      GamePacket(
        type: PacketType.spatialAudio,
        senderId: _localPlayer?.id,
        timestamp: _now(),
        payload: {'action': action, 'sound': sound},
      ),
    );
  }

  /// Host phát tick đếm ngược đến tất cả client.
  void broadcastCountdown(int tick) {
    if (!isHost) return;
    _repo.broadcastPacket(
      GamePacket(
        type: PacketType.countdownTick,
        timestamp: _now(),
        payload: {'tick': tick},
      ),
    );
  }

  /// Host gửi feedback rung/chớp tới một tay cầm cụ thể.
  /// 4.3 — Unicast trực tiếp tới socket của target, không broadcast tới mọi client.
  void sendControllerFeedback(
    String targetPlayerId, {
    required String hapticType,
    int? flashColor,
  }) {
    if (!isHost) return;
    // Tìm socket tương ứng với targetPlayerId trong map.
    final targetSocket = _socketPlayers.entries
        .where((e) => e.value == targetPlayerId)
        .map((e) => e.key)
        .firstOrNull;
    final packet = GamePacket(
      type: PacketType.controllerFeedback,
      senderId: _localPlayer?.id,
      timestamp: _now(),
      payload: {'h': hapticType, 'c': flashColor},
    );
    if (targetSocket != null) {
      _repo.sendToClient(targetSocket, packet);
    } else {
      // Fallback: broadcast nếu socket chưa được map (console mode, spectator, v.v.)
      _repo.broadcastPacket(packet);
    }
  }

  /// Callback để EmoteLayer nhận emoji từ đối thủ.
  void Function(String emoji)? onEmoteReceived;

  /// Callback khi nhận lệnh rung đồng bộ từ thiết bị khác.
  void Function()? onHapticReceived;

  /// Callback khi nhận tin nhắn chat trong phòng (tên người gửi, nội dung).
  void Function(String name, String text)? onChatReceived;

  /// Gửi lệnh rung đồng bộ tới các thiết bị khác.
  void sendHaptic() {
    sendGamePacket(
      GamePacket(
        type: PacketType.haptic,
        senderId: _localPlayer?.id,
        timestamp: _now(),
      ),
    );
  }

  void sendSystemPause() {
    sendGamePacket(
      GamePacket(
        type: PacketType.systemPause,
        senderId: _localPlayer?.id,
        timestamp: _now(),
      ),
    );
  }

  /// Gửi tin nhắn chat tới mọi người trong phòng.
  void sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final packet = GamePacket(
      type: PacketType.chat,
      senderId: _localPlayer?.id,
      timestamp: _now(),
      payload: {'name': _localPlayer?.name ?? 'Player', 'text': trimmed},
    );
    // Hiển thị ngay tin của chính mình, rồi gửi đi.
    onChatReceived?.call(_localPlayer?.name ?? 'Player', trimmed);
    sendGamePacket(packet);
  }

  // ── Host ──────────────────────────────────────────────────────────────────

  Future<void> hostRoom(
    String playerName,
    String roomName, {
    bool consoleMode = false,
  }) async {
    if (_state == LobbyState.hosting || _state == LobbyState.inRoom) return;
    _isConsoleMode = consoleMode;
    _localPlayer = Player(
      id: _generateId(),
      name: _sanitizeName(playerName),
      isHost: true,
      color: _selectedColor,
      playerIndex: 0,
    );
    _players
      ..clear()
      ..add(_localPlayer!);
    _socketPlayers.clear();

    _repo.onClientPacket = _handleHostPacket;
    _repo.onClientConnected = (_) => _syncLobby();
    _repo.onClientDisconnected = _handleClientDisconnected;

    _emojiCode = EmojiCode.generate();
    await _repo.startServer(EmojiCode.embed(roomName, _emojiCode));
    _state = LobbyState.hosting;
    notifyListeners();

    if (kIsWeb) {
      Timer(const Duration(seconds: 1), () {
        if (_state == LobbyState.hosting || _state == LobbyState.inRoom) {
          final bot1 = Player(
            id: 'bot_1',
            name: 'Pikachu ⚡',
            color: 0xFFFFD700,
            playerIndex: _players.length,
          );
          _players.add(bot1);
          notifyListeners();
          _syncLobby();
        }
      });
      Timer(const Duration(seconds: 2), () {
        if (_state == LobbyState.hosting || _state == LobbyState.inRoom) {
          final bot2 = Player(
            id: 'bot_2',
            name: 'Charizard 🔥',
            color: 0xFFFF6B35,
            playerIndex: _players.length,
          );
          _players.add(bot2);
          notifyListeners();
          _syncLobby();
        }
      });
    }
  }

  /// Host nhận gói tin kèm socket nguồn — map join → socket để dọn dẹp khi rớt,
  /// đồng thời mesh-relay gói gameplay của client này tới các client còn lại.
  void _handleHostPacket(Socket socket, GamePacket packet) {
    if (packet.type == PacketType.join && packet.senderId != null) {
      _socketPlayers[socket] = packet.senderId!;
    }
    // Relay realtime/gameplay packets giữa các client (host làm hub).
    if (_relayablePacketTypes.contains(packet.type)) {
      _repo.broadcastPacketExcept(packet, socket);
    }
    _handleIncomingPacket(packet);
  }

  /// Số người chơi tối đa trong một phòng; người thứ 7+ sẽ trở thành khán giả.
  static const int _maxRoomPlayers = 6;

  static const _relayablePacketTypes = {
    PacketType.gameData,
    PacketType.worldState,
    PacketType.emote,
    PacketType.haptic,
    PacketType.chat,
    PacketType.disruption,
    PacketType.spatialAudio,
  };

  void _handleClientDisconnected(Socket socket) {
    final playerId = _socketPlayers.remove(socket);
    if (playerId == null) return;
    _players.removeWhere((p) => p.id == playerId);
    notifyListeners();
    _syncLobby();
  }

  void startGame(String gameId) {
    if (!isHost) return;
    final packet = GamePacket(
      type: PacketType.startGame,
      timestamp: _now(),
      payload: {
        'game_id': gameId,
        'series_length': _seriesLength,
        'tournament_mode': _isTournamentMode,
        'console_mode': _isConsoleMode,
      },
    );
    _repo.broadcastPacket(packet);
    _pendingGameId = gameId;
    _gameStartToken++;
    // Host chạy Flame dù là console hay thường.
    _state = LobbyState.inGame;
    notifyListeners();
  }

  // ── Client ────────────────────────────────────────────────────────────────

  Future<void> discoverRooms(String playerName) async {
    _localPlayer = Player(
      id: _generateId(),
      name: _sanitizeName(playerName),
      color: _selectedColor,
    );
    _discoveredRooms.clear();
    _repo.onPacketReceived = _handleIncomingPacket;

    await _discoverySubscription?.cancel();
    _discoverySubscription = _repo.discoveredServices.listen((service) {
      // Dedup — mDNS có thể báo cùng một phòng nhiều lần.
      final exists = _discoveredRooms.any((s) => s.name == service.name);
      if (exists) return;
      _discoveredRooms.add(service);
      notifyListeners();
    });

    await _repo.startDiscovery();
    _state = LobbyState.discovering;
    notifyListeners();

    if (kIsWeb) {
      Timer(const Duration(milliseconds: 600), () {
        if (_state == LobbyState.discovering) {
          _discoveredRooms.add(Service(
            name: 'Web Room 🍎🍕👻👽',
            type: '_pgamehub._tcp',
            host: '127.0.0.1',
            port: 4567,
          ));
          notifyListeners();
        }
      });
    }
  }

  Service? _lastJoinedService;

  Future<void> joinRoom(Service service) async {
    if (_state == LobbyState.inRoom) return;
    _lastJoinedService = service;
    _reconnectAttempts = 0;
    _repo.onPacketReceived = _handleIncomingPacket;
    _repo.onHostDisconnected = _onHostDisconnected;
    await _repo.connectToService(service);

    if (kIsWeb) {
      _players.clear();
      _players.add(Player(
        id: 'host_id',
        name: 'Web Host 🖥️',
        isHost: true,
        color: 0xFF6C63FF,
        playerIndex: 0,
      ));
      _players.add(_localPlayer!.copyWith(playerIndex: 1));
      _state = LobbyState.inRoom;
      notifyListeners();
      return;
    }

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
    _reconnectAttempts = 0;
    _repo.onPacketReceived = _handleIncomingPacket;
    _repo.onHostDisconnected = _onHostDisconnected;
    await _repo.connectToAddress(ip, port);

    if (kIsWeb) {
      _players.clear();
      _players.add(Player(
        id: 'host_id',
        name: 'Web Host 🖥️',
        isHost: true,
        color: 0xFF6C63FF,
        playerIndex: 0,
      ));
      _players.add(_localPlayer!.copyWith(playerIndex: 1));
      _state = LobbyState.inRoom;
      notifyListeners();
      return;
    }

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
        final joinId = packet.senderId ?? _generateId();
        // Bỏ qua nếu người chơi đã tồn tại (rejoin sau khi reconnect).
        if (_players.any((p) => p.id == joinId)) {
          _syncLobby();
          break;
        }
        // Phòng đầy (≥ 6 người hoặc ≥ maxSpectatorThreshold) → trả về joinSpectator.
        if (_players.length >= _maxRoomPlayers) {
          final spec = GamePacket(
            type: PacketType.joinSpectator,
            timestamp: _now(),
            payload: {
              'id': joinId,
              'name': _sanitizeName(packet.payload['name'] as String?),
            },
          );
          _repo.broadcastPacket(spec);
          break;
        }
        final player = Player(
          id: joinId,
          name: _sanitizeName(packet.payload['name'] as String?),
          color: (packet.payload['color'] as int?) ?? 0xFF6C63FF,
          playerIndex: _players.length,
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
        _isTournamentMode =
            (packet.payload['tournament_mode'] as bool?) ?? false;
        _isConsoleMode = (packet.payload['console_mode'] as bool?) ?? false;
        _gameStartToken++;
        // Client trong console mode → trở thành tay cầm, không chạy Flame.
        _state = _isConsoleMode ? LobbyState.inConsole : LobbyState.inGame;
        notifyListeners();
      case PacketType.controllerInput:
        // Host nhận input từ tay cầm — route thẳng tới game.
        final id = packet.senderId ?? '';
        onControllerInput?.call(id, packet.payload);
        // Cũng route qua onGamePacket để các game xử lý nếu muốn.
        onGamePacket?.call(packet);
      case PacketType.controllerFeedback:
        // 4.3 — Packet is now unicast: if we received it, it's addressed to us.
        final hapticType = packet.payload['h'] as String? ?? 'light';
        final flashColor = packet.payload['c'] as int?;
        onControllerFeedback?.call(hapticType, flashColor);
      case PacketType.countdownTick:
        final tick = packet.payload['tick'] as int?;
        if (tick != null) {
          countdownTickNotifier.value = tick;
          onCountdownTick?.call(tick);
        }
      case PacketType.initController:
        onControllerInit?.call(packet.payload);
      case PacketType.systemPause:
        onSystemPause?.call();
      case PacketType.joinSpectator:
        _iAmSpectator = true;
        _state = LobbyState.inRoom;
        notifyListeners();
      case PacketType.spectatorAction:
        // Host nhận lệnh phá đám từ khán giả → relay disruption cho tất cả player.
        if (isHost) {
          final t = packet.payload['type'] as String?;
          if (t != null) {
            _repo.broadcastPacket(
              GamePacket(
                type: PacketType.disruption,
                timestamp: _now(),
                payload: {'type': t},
              ),
            );
          }
        }
      case PacketType.disruption:
        final t = packet.payload['type'] as String?;
        if (t != null) onDisruption?.call(t);
      case PacketType.spatialAudio:
        final action = packet.payload['action'] as String?;
        final sound = packet.payload['sound'] as String?;
        if (action != null && sound != null) {
          onSpatialAudio?.call(action, sound);
        }
      case PacketType.gameData:
      case PacketType.worldState:
        onGamePacket?.call(packet);
      case PacketType.endGame:
        onGameEnded?.call(packet);
      case PacketType.emote:
        final emoji = packet.payload['emoji'] as String?;
        if (emoji != null) onEmoteReceived?.call(emoji);
      // Relay tới các client khác được xử lý ở _handleHostPacket.
      case PacketType.haptic:
        onHapticReceived?.call();
      case PacketType.chat:
        final msg = packet.payload['text'] as String?;
        final from = packet.payload['name'] as String?;
        if (msg != null) onChatReceived?.call(from ?? 'Player', msg);
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
    _isConsoleMode = false;
    _state = LobbyState.inRoom;
    notifyListeners();
  }

  void leaveRoom() {
    _discoverySubscription?.cancel();
    _discoverySubscription = null;
    _repo.dispose();
    _repo = ConnectionRepository();
    _players.clear();
    _pendingGameId = null;
    _iAmSpectator = false;
    _isConsoleMode = false;
    _state = LobbyState.idle;
    notifyListeners();
  }

  // ── Reconnect ──────────────────────────────────────────────────────────────

  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 3;
  static const _reconnectDelays = [1, 2, 4]; // seconds

  void _onHostDisconnected() {
    if (_reconnectAttempts >= _maxReconnectAttempts ||
        _lastJoinedService == null) {
      _state = LobbyState.idle;
      notifyListeners();
      return;
    }
    _state = LobbyState.reconnecting;
    notifyListeners();
    _scheduleReconnect();
  }

  Future<void> _scheduleReconnect() async {
    if (_disposed) return;
    final delay = _reconnectDelays[_reconnectAttempts.clamp(0, 2)];
    _reconnectAttempts++;
    await Future.delayed(Duration(seconds: delay));
    // 4.2 / 5.4 — provider may have been disposed while waiting; bail out.
    if (_disposed) return;
    final local = _localPlayer;
    final service = _lastJoinedService;
    if (local == null || service == null) return;
    try {
      await _repo.connectToService(service);
      final packet = GamePacket(
        type: PacketType.join,
        senderId: local.id,
        timestamp: _now(),
        payload: {'name': local.name, 'color': local.color},
      );
      _repo.sendPacket(packet);
      _reconnectAttempts = 0;
      _state = LobbyState.inRoom;
      AppLogger.info('Reconnected to host', tag: 'Lobby');
    } catch (_) {
      _onHostDisconnected(); // retry
    }
    if (!_disposed) notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _discoverySubscription?.cancel();
    countdownTickNotifier.dispose();
    _repo.dispose();
    super.dispose();
  }

  /// Đảm bảo tên không rỗng (tránh crash khi truy cập name[0] ở UI).
  String _sanitizeName(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? 'Player' : trimmed;
  }

  /// 4.1 — Combine timestamp + secure random suffix to avoid ID collisions
  /// when two devices join within the same millisecond.
  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final rand = math.Random.secure()
        .nextInt(0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    return '$ts$rand';
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;
}
