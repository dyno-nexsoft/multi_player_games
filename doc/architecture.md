# Kiến Trúc Hệ Thống — Party Game Hub

Game multiplayer cục bộ (Local P2P) cho phép nhiều thiết bị Android/iOS trong cùng mạng Wi-Fi tự động tìm nhau và chơi game mà không cần server cloud.

---

## Stack Công Nghệ

| Tầng | Công nghệ | Lý do |
|---|---|---|
| UI & Navigation | Flutter + GoRouter | Đa nền tảng, Material 3 |
| Game Engine | Flame | ECS, game loop, 60FPS canvas |
| State Management | Provider | Nhẹ, DI rõ ràng |
| Service Discovery | `nsd` (mDNS/Bonjour) | Hoạt động cả Android lẫn iOS |
| Network Transport | `dart:io` TCP Socket | Độ trễ thấp, kiểm soát protocol |

---

## Mô Hình Mạng: Host-Client

Một thiết bị là **Host** (TCP Server + mDNS Register), các thiết bị còn lại là **Client** (mDNS Discover + TCP Connect).

```
Host Device                           Client Device
┌──────────────────────┐              ┌──────────────────────┐
│  LobbyProvider       │◄────TCP─────►│  LobbyProvider       │
│  ConnectionRepository│              │  ConnectionRepository│
└──────────┬───────────┘              └──────────┬───────────┘
           │                                     │
    ┌──────▼──────┐                       ┌──────▼──────┐
    │ GameProvider│                       │ GameProvider│
    │ (Authority) │                       │ (Renderer)  │
    └──────┬──────┘                       └─────────────┘
           │
    ┌──────▼──────────────┐
    │  BaseMiniGame       │  ← Host tính physics, broadcast world_state
    └─────────────────────┘
```

**Nguyên tắc đồng bộ:**
- **Host là authority** — tính toán toàn bộ vật lý, va chạm, điểm số
- **Client gửi input** (tap, joystick)
- **Host broadcast world_state** ~30Hz, Client dùng Lerp để render mượt

---

## Luồng Chơi Game

```
Host                                Client
 │  Tạo phòng (TCP Server + NSD)      │
 │◄──────────── join ─────────────────│  Client kết nối và gửi tên
 │──────────── lobby_sync ───────────►│  Host broadcast danh sách player
 │  Chọn game → startGame()           │
 │──────────── start_game ───────────►│
 │◄────── game_data (input) ──────────│  Client gửi input liên tục
 │──────── game_data (world_state) ──►│  Host broadcast vị trí 30Hz
 │  endMiniGame() → tính điểm         │
 │──────────── end_game ─────────────►│
 │        ← RoomScreen (chọn game tiếp) →
```

---

## Cấu Trúc Code: Clean Architecture + Feature-First

```
lib/
├── core/
│   ├── network/        # GamePacket, NetworkService
│   ├── theme/          # AppTheme (Material 3 dark)
│   └── utils/          # AppLogger
├── features/
│   ├── lobby/
│   │   ├── data/       # ConnectionRepository (TCP + NSD)
│   │   ├── domain/     # Player
│   │   └── presentation/ # LobbyProvider, LobbyScreen, RoomScreen, DiscoverScreen
│   └── game/
│       ├── data/       # GameNetworkRouter
│       ├── domain/     # BaseMiniGame, MiniGameMetadata, MiniGameRegistry
│       ├── presentation/ # GameProvider, GameHubScreen
│       └── mini_games/ # tug_of_war/, sumo_bumper/, penalty_shootout/
├── router.dart
└── main.dart
```

| Tầng | Trách nhiệm | KHÔNG được |
|---|---|---|
| `data/` | Socket, NSD, JSON parse | Chứa UI hay Flame logic |
| `domain/` | Business logic thuần | Phụ thuộc Flutter/Flame |
| `presentation/` | Provider, Widget, Flame | Logic mạng trực tiếp |

---

## Mini-Game Interface

Mọi mini-game kế thừa `BaseMiniGame extends FlameGame`:

```dart
abstract class BaseMiniGame extends FlameGame {
  String get gameId;
  void onNetworkDataReceived(String senderId, Map<String, dynamic> payload);
  void endMiniGame(Map<String, int> playerScores);
}
```

`MiniGameRegistry` đăng ký và khởi tạo game theo `gameId`. Thêm game mới chỉ cần thêm 1 entry vào Registry — không ảnh hưởng code network hay lobby.

---

## Tournament Loop

```
RoomScreen → GameHubScreen → [chơi] → ScoreboardScreen → RoomScreen → ...
```

`GameProvider` tích lũy điểm (`totalScores`) qua nhiều vòng chơi liên tiếp.
