# Hướng Dẫn Thêm Mini-Game Mới

Hệ thống được thiết kế để thêm game mới **không chạm vào code network hay lobby**. Chỉ cần 4 bước.

---

## Bước 1: Tạo Thư Mục Game

```
lib/features/game/mini_games/
└── ten_game/                        # snake_case, ví dụ: air_hockey
    ├── ten_game_game.dart           # File game chính
    └── components/                  # Các Flame component (tùy chọn)
        ├── component_a.dart
        └── component_b.dart
```

---

## Bước 2: Viết Class Game

Kế thừa `BaseMiniGame` và implement 2 method bắt buộc:

```dart
// lib/features/game/mini_games/air_hockey/air_hockey_game.dart
import 'package:flame/components.dart';
import '../../domain/base_mini_game.dart';

class AirHockeyGame extends BaseMiniGame {
  AirHockeyGame(super.gameProvider);

  // Phải khớp với id trong MiniGameRegistry
  @override
  String get gameId => 'air_hockey';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.visibleGameSize = Vector2(400, 800);
    // Thêm components...
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Host tính physics và broadcast
    if (gameProvider.lobbyProvider.isHost) {
      // tính toán...
      gameProvider.sendGameData(gameId, {
        'action': 'sync',
        'puck': [puck.position.x, puck.position.y],
      });
    }
  }

  // Nhận dữ liệu từ thiết bị khác
  @override
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload) {
    final action = payload['action'] as String?;
    switch (action) {
      case 'sync':
        // Client cập nhật vị trí từ Host
        final puckData = payload['puck'] as List;
        // ...
      case 'paddle_move':
        // Host nhận vị trí paddle của Client
        // ...
    }
  }
}
```

**Quy tắc trong class game:**
- Chỉ `gameProvider.lobbyProvider.isHost` mới tính physics
- Gọi `endMiniGame(playerScores)` khi game kết thúc — `playerScores` là map `{ playerId: điểm }`
- Dùng `gameProvider.sendGameData(gameId, payload)` để gửi gói tin

---

## Bước 3: Đăng Ký vào Registry

Mở `lib/features/game/domain/mini_game_registry.dart` và thêm vào **2 chỗ**:

```dart
// Chỗ 1: danh sách availableGames
static const List<MiniGameMetadata> availableGames = [
  // ... game cũ ...
  MiniGameMetadata(
    id: 'air_hockey',
    title: 'Khúc Côn Cầu',
    description: 'Đánh puck qua màn hình đối phương!',
    iconPath: 'assets/icons/air_hockey.png',
    minPlayers: 2,
    maxPlayers: 2,
  ),
];

// Chỗ 2: factory createGame
static BaseMiniGame createGame(String gameId, GameProvider provider) {
  switch (gameId) {
    // ... case cũ ...
    case 'air_hockey':
      return AirHockeyGame(provider);  // import class ở đầu file
    default:
      throw Exception('Game ID "$gameId" không tồn tại');
  }
}
```

---

## Bước 4: Thêm Icon (Tùy Chọn)

Đặt file icon vào `assets/icons/air_hockey.png`. Nếu chưa có thì để placeholder, `RoomScreen` vẫn chạy bình thường.

---

## Checklist Trước Khi PR

```
[ ] flutter analyze → 0 errors
[ ] gameId trong class khớp với id trong Registry
[ ] Host-only physics: có check gameProvider.lobbyProvider.isHost trước khi tính toán
[ ] endMiniGame() được gọi khi game kết thúc
[ ] sendGameData() dùng đúng gameId của game này
[ ] Test thủ công: chạy trên 2 thiết bị thực
```

---

## Ví Dụ: Network Pattern Theo Loại Game

**Game tap (Tug of War pattern)** — dữ liệu nhẹ, tần suất cao:
```dart
// Client: mỗi tap
gameProvider.sendGameData(gameId, {'action': 'tap'});

// Host: broadcast kết quả ~10Hz
gameProvider.sendGameData(gameId, {'action': 'result', 'value': 0.3});
```

**Game physics realtime (Sumo pattern)** — Host authority, broadcast 30Hz:
```dart
// Client: joystick input
gameProvider.sendGameData(gameId, {'action': 'input', 'dx': 0.5, 'dy': -0.3});

// Host: world state broadcast
gameProvider.sendGameData(gameId, {
  'action': 'sync',
  'objects': [{'id': 'p1', 'x': 0.4, 'y': 0.5}, ...]
});
```

**Game turn-based / event-driven (Penalty pattern)** — chỉ gửi khi có sự kiện:
```dart
// Shooter → Keeper: khi bắn
gameProvider.sendGameData(gameId, {'action': 'shoot', 'dx': -0.4});

// Keeper → Shooter: khi di chuyển tay
gameProvider.sendGameData(gameId, {'action': 'slide', 'x': 0.3});
```

**Game chéo màn hình (Air Hockey pattern)** — chuyển giao physics ownership:
```dart
// Khi puck vượt biên → chuyển cho máy kia làm chủ
gameProvider.sendGameData(gameId, {
  'action': 'puck_transfer',
  'x': 1.0 - puck.normalizedX,  // đảo x
  'vx': -puck.vx,               // đảo hướng
  'vy': -puck.vy,
});
```
