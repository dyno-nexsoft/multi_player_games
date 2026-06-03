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


---

# Cấu Trúc Thư Mục & Quy Chuẩn Code

---

## Cây Thư Mục (`code/lib/`)

```
lib/
├── core/
│   ├── audio/                      # Quản lý âm thanh và nhạc nền
│   ├── localization/               # Đa ngôn ngữ (i18n)
│   ├── network/
│   │   ├── game_packet.dart        # Model gói tin + PacketType constants
│   │   └── network_service.dart    # TCP server/client + mDNS wrapper (tiện ích)
│   ├── storage/                    # Lưu trữ local (SharedPreferences)
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 dark theme, Google Fonts
│   └── utils/
│       └── app_logger.dart         # Logger qua dart:developer (không dùng print)
│
├── features/
│   ├── console/                    # UI cho chế độ TV/Màn hình lớn (Host Mode)
│   ├── lobby/
│   │   ├── data/
│   │   │   └── connection_repository.dart  # TCP Socket + NSD, tầng thấp nhất
│   │   ├── domain/
│   │   │   └── player.dart                 # Entity người chơi (id, name, isHost, score)
│   │   └── presentation/
│   │       ├── lobby_provider.dart         # ChangeNotifier — quản lý kết nối + trạng thái phòng
│   │       ├── lobby_screen.dart           # Màn hình chọn Host/Join
│   │       ├── discover_screen.dart        # Danh sách phòng đang quảng bá
│   │       └── room_screen.dart            # Phòng chờ + chọn mini-game (Host only)
│   │
│   └── game/
│       ├── data/
│       │   └── game_network_router.dart    # Định tuyến gói tin đến game active
│       ├── domain/
│       │   ├── base_mini_game.dart         # Abstract class — interface mọi mini-game
│       │   ├── mini_game_metadata.dart     # Thông tin cấu hình game (id, title, players)
│       │   └── mini_game_registry.dart     # Đăng ký + factory tạo game instance
│       ├── presentation/
│       │   ├── game_provider.dart          # ChangeNotifier — tournament score + active game
│       │   └── game_hub_screen.dart        # GameWidget host + ScoreboardScreen
│       └── mini_games/                     # Danh sách các Mini-games hiện có
│           ├── air_hockey/
│           ├── battleship/
│           ├── billiards/
│           ├── code_breaker/
│           ├── draw_guess/
│           ├── hot_potato/
│           ├── liars_dice/
│           ├── minesweeper/
│           ├── neon_dodge/
│           ├── penalty_shootout/
│           ├── reaction_tap/
│           ├── sumo_bumper/
│           └── tug_of_war/
│
├── router.dart     # GoRouter — 4 routes: /, /discover, /room, /game
└── main.dart       # MultiProvider + MaterialApp.router
```

---

## Quy Chuẩn Code

**Đặt tên:**
- File: `snake_case` — `lobby_provider.dart`
- Class/Type: `PascalCase` — `LobbyProvider`
- Biến/Hàm: `camelCase` — `isHost`, `sendPacket()`

**Dart:**
- Không dùng toán tử `!` (force unwrap) — dùng `?.`, `??`, hoặc `if (x != null)`
- Không dùng `print()` — dùng `AppLogger.info/warning/error()`
- Widget phức tạp → tách thành private class, không dùng helper function

**Tầng:**
- `data/` không import Flutter Widget hay Flame
- `domain/` không import bất kỳ package ngoài (trừ `json_annotation` nếu cần)
- `presentation/` là nơi duy nhất dùng Provider và Flame


---

# UI/UX Design Reference

Phong cách **Neon Dark / Glassmorphism** — nền tối tôn màu neon, hiệu ứng kính mờ cho card.

---

## Color Palette

```dart
// Đã cấu hình trong AppTheme (lib/core/theme/app_theme.dart)
primary:    Color(0xFF6C63FF)  // Tím neon — CTA chính (Host, Start)
secondary:  Color(0xFFFF6584)  // Hồng neon — CTA phụ (Join, Cancel)
surface:    Color(0xFF1E1E2E)  // Card background
background: Color(0xFF11111B)  // App background (Catppuccin Mocha)
onSurface:  Color(0xFFCDD6F4)  // Text chính
```

---

## Typography

```dart
// Google Fonts đã import trong pubspec.yaml
heading:  GoogleFonts.nunito(fontWeight: FontWeight.bold)   // Vui, mập, dễ đọc
body:     GoogleFonts.nunito()                              // Đồng nhất
```

---

## Component Patterns

**Button:** Bo góc 16dp, padding `32×16`, scale animation khi tap (0.95 → 1.0 với `Curves.elasticOut`)

**Card:** Bo góc 16dp, `Color(0xFF1E1E2E)`, elevation 4

**Avatar:** `CircleAvatar` với chữ cái đầu tên, màu background theo index player

**Scanning state:** Thay `CircularProgressIndicator` bằng animation radar sweep (Lottie) khi implement xong

---

## Flutter + Flame Overlay

```dart
// GameWidget hỗ trợ overlay Flutter Widget lên Flame Canvas
GameWidget(
  game: myGame,
  overlayBuilderMap: {
    'hud': (ctx, game) => HudOverlay(),      // Điểm, timer
    'pause': (ctx, game) => PauseOverlay(),  // Nút pause
  },
)
```

**Quy tắc:** KHÔNG vẽ text và button bằng Flame — dùng Flutter overlay cho mọi UI tĩnh.

---

## Navigation Flow

```
LobbyScreen (/)
  ├── → /room          (sau khi Host tạo phòng)
  ├── → /discover      (sau khi nhấn Join)
  │     └── → /room   (sau khi chọn phòng)
  └── /room
        └── → /game   (khi Host start game)
              └── → /room  (sau khi xem scoreboard)
```


---

# Đặc Tả Giao Thức Mạng

Tất cả giao tiếp giữa Host và Client đều qua **TCP Socket**, mỗi gói tin là một chuỗi JSON kết thúc bằng `\n` (line-framing).

---

## Cấu Trúc Gói Tin Cơ Bản (`GamePacket`)

```json
{
  "type": "game_data",
  "game_id": "tug_of_war",
  "sender_id": "device_abc123",
  "timestamp": 1698374829301,
  "payload": { }
}
```

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| `type` | ✅ | Loại gói tin (xem bảng dưới) |
| `game_id` | Chỉ khi in-game | Mini-game đang chạy |
| `sender_id` | ✅ | ID thiết bị gửi |
| `timestamp` | ✅ | Unix epoch ms |
| `payload` | ✅ | Dữ liệu tùy theo `type` |

**Hằng số `type`** (định nghĩa trong `PacketType`):

| Constant | Hướng | Ý nghĩa |
|---|---|---|
| `join` | Client→Host | Client xin vào phòng |
| `lobby_sync` | Host→All | Cập nhật danh sách player |
| `start_game` | Host→All | Bắt đầu mini-game |
| `end_game` | Host→All | Kết thúc mini-game + điểm |
| `game_data` | Cả hai | Dữ liệu trong game (input / world_state) |
| `heartbeat` | Cả hai | Keep-alive (1s/lần) |
| `system_pause` | Cả hai | App bị pause (điện thoại) |

---

## Lobby Packets

### `join` — Client→Host
```json
{
  "type": "join",
  "sender_id": "client_xyz",
  "payload": { "name": "Tom" }
}
```

### `lobby_sync` — Host→All (broadcast)
```json
{
  "type": "lobby_sync",
  "payload": {
    "players": [
      { "id": "host_id", "name": "Jerry", "is_host": true, "score": 0 },
      { "id": "client_xyz", "name": "Tom", "is_host": false, "score": 0 }
    ]
  }
}
```

### `start_game` — Host→All
```json
{
  "type": "start_game",
  "payload": { "game_id": "tug_of_war" }
}
```

### `end_game` — Host→All
```json
{
  "type": "end_game",
  "payload": {
    "scores": { "host_id": 100, "client_xyz": 0 }
  }
}
```

---

## In-Game Packets (`game_data`)

Trường `game_id` phải khớp với mini-game đang chạy để `GameNetworkRouter` định tuyến đúng.

### Tug of War
```json
// Client→Host: mỗi lần tap
{ "type": "game_data", "game_id": "tug_of_war",
  "payload": { "action": "tap" } }

// Host→All: ~10Hz
{ "type": "game_data", "game_id": "tug_of_war",
  "payload": { "action": "rope_state", "rope_position": 0.15 } }
```

### Sumo Bumper
```json
// Client→Host: joystick input
{ "type": "game_data", "game_id": "sumo_bumper",
  "payload": { "action": "input", "angle": 2.14, "force": 0.8 } }

// Host→All: ~30Hz
{ "type": "game_data", "game_id": "sumo_bumper",
  "payload": { "action": "sync", "p1": [0.4, 0.5], "p2": [0.6, 0.5] } }
```

### Penalty Shootout
```json
// Host (Shooter)→Client
{ "type": "game_data", "game_id": "penalty_shootout",
  "payload": { "action": "shoot", "dx": -0.4 } }

// Client (Keeper) slide
{ "type": "game_data", "game_id": "penalty_shootout",
  "payload": { "action": "slide", "x": 0.3 } }
```

---

## Heartbeat & Disconnect Detection

- Mỗi bên gửi `heartbeat` 1 lần/giây
- Nếu 3 giây không nhận được → **pause game**, hiện "Đang kết nối lại..."
- Nếu 10 giây không kết nối lại → **hủy trận**, về RoomScreen
- Khi app bị pause (`AppLifecycleState.paused`) → gửi `system_pause` ngay lập tức


---

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


---

# GitHub Actions CI/CD Workflow — Build & Release APK

Tài liệu này hướng dẫn cách hoạt động của hệ thống CI/CD (GitHub Actions) để tự động hóa quy trình build và phân phối tệp APK cho dự án Party Game Hub.

---

## 1. Tổng Quan Workflow

Luồng CI/CD được cấu hình để thực hiện 2 nhiệm vụ chính:
1. **Build & Verify**: Biên dịch mã nguồn Flutter sang tệp APK Release khi có thay đổi mã nguồn mới (push/pull request/chạy thủ công).
2. **Release**: Tự động tạo một GitHub Release mới và đính kèm tệp APK Release khi có một phiên bản mới được đánh tag (ví dụ: `v1.0.0`).

Tệp cấu hình nằm tại: [release_apk.yml](file:///e:/Projects/multi_player_games/.github/workflows/release_apk.yml)

---

## 2. Kịch Bản Kích Hoạt (Triggers)

Workflow hỗ trợ 3 hình thức kích hoạt:
- **Push lên nhánh `main`**: Tự động build để xác minh không có lỗi biên dịch.
- **Push thẻ phiên bản (Tags matching `v*`)**: Tự động build và tạo Release trên GitHub kèm APK.
- **Chạy thủ công (`workflow_dispatch`)**: Cho phép dev bấm nút "Run workflow" trên giao diện GitHub Actions để tải APK về bất cứ lúc nào.

---

## 3. Các Bước Build Chi Tiết (Build Steps)

Do mã nguồn Flutter nằm trong thư mục con `code/`, toàn bộ các lệnh build đều được thực thi tại thư mục này thông qua thiết lập `defaults.run.working-directory: code`.

Các bước thực hiện trong runner `ubuntu-latest`:
1. **Checkout Code**: Lấy mã nguồn từ GitHub.
2. **Setup Java 17 (Temurin)**: Cài đặt JDK phiên bản 17 (Gradle yêu cầu để biên dịch Android). Cấu hình cache cho Gradle giúp tăng tốc build các lần sau.
3. **Setup Flutter**: Cài đặt SDK Flutter kênh `stable` và bật tính năng cache SDK.
4. **Install Dependencies**: Chạy lệnh `flutter pub get`.
5. **Build APK**: Chạy lệnh `flutter build apk --release`.
6. **Upload APK Artifact**: Tải tệp `app-release.apk` lên hệ thống lưu trữ tạm thời của GitHub Action (tải về từ trang Summary của Action run).

---

## 4. Quy Trình Tạo Release (Release Step)

Khi tag có định dạng bắt đầu bằng chữ `v` (ví dụ `v1.0.0`) được push lên GitHub:
1. Workflow tải tệp APK đã build thành công từ bước trước.
2. Sử dụng Action `softprops/action-gh-release@v2` để tạo mới một bản Release trên GitHub.
3. Đính kèm tệp `app-release.apk` vào bản Release đó để người dùng tải trực tiếp.

---

## 5. Kiến Trúc Keystore (Dummy & Real)

Dự án áp dụng mô hình quản lý Keystore hiện đại để tự động hóa hoàn toàn việc cấp phép chữ ký (Signing).

### 5.1 Hệ thống Local (Dummy Keystore)
Đã được tích hợp sẵn trong mã nguồn:
*   `code/android/app/dummy-release.jks`: Keystore giả.
*   `code/android/key.properties`: Chứa mật khẩu ảo.

Nhờ cơ chế Fallback trong `build.gradle.kts`, bất kỳ lập trình viên nào clone code về cũng có thể chạy lệnh `flutter build apk --release` ngay lập tức mà không bị lỗi thiếu chữ ký, không cần cấu hình thêm gì.

### 5.2 Hệ thống CI/CD (Real Keystore)
Khi Github Actions kích hoạt, nó sẽ đọc các Biến Môi Trường (Environment Variables) từ GitHub Secrets. Do `build.gradle.kts` ưu tiên lấy biến môi trường trước, file APK sinh ra sẽ tự động được ghi đè bằng chữ ký thật (Real Keystore).

**Các biến Secret cần cấu hình trên GitHub (nếu bạn là Admin):**
*   `KEYSTORE_FILE`: File `.jks` thật được chuyển hóa thành chuỗi Base64.
*   `KEY_ALIAS`: Alias của key.
*   `KEY_PASSWORD`: Mật khẩu alias.
*   `STORE_PASSWORD`: Mật khẩu keystore.
