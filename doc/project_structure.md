# Cấu Trúc Thư Mục & Quy Chuẩn Code

---

## Cây Thư Mục (`code/lib/`)

```
lib/
├── core/
│   ├── network/
│   │   ├── game_packet.dart        # Model gói tin + PacketType constants
│   │   └── network_service.dart    # TCP server/client + mDNS wrapper (tiện ích)
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 dark theme, Google Fonts
│   └── utils/
│       └── app_logger.dart         # Logger qua dart:developer (không dùng print)
│
├── features/
│   ├── lobby/
│   │   ├── data/
│   │   │   └── connection_repository.dart  # TCP Socket + NSD, tầng thấp nhất
│   │   ├── domain/
│   │   │   └── player.dart                 # Entity người chơi (id, name, isHost, score)
│   │   └── presentation/
│   │       ├── lobby_provider.dart          # ChangeNotifier — quản lý kết nối + trạng thái phòng
│   │       ├── lobby_screen.dart            # Màn hình chọn Host/Join
│   │       ├── discover_screen.dart         # Danh sách phòng đang quảng bá
│   │       └── room_screen.dart             # Phòng chờ + chọn mini-game (Host only)
│   │
│   └── game/
│       ├── data/
│       │   └── game_network_router.dart     # Định tuyến gói tin đến game active
│       ├── domain/
│       │   ├── base_mini_game.dart          # Abstract class — interface mọi mini-game
│       │   ├── mini_game_metadata.dart      # Thông tin cấu hình game (id, title, players)
│       │   └── mini_game_registry.dart      # Đăng ký + factory tạo game instance
│       ├── presentation/
│       │   ├── game_provider.dart           # ChangeNotifier — tournament score + active game
│       │   └── game_hub_screen.dart         # GameWidget host + ScoreboardScreen
│       └── mini_games/
│           ├── tug_of_war/
│           │   ├── tug_of_war_game.dart
│           │   └── components/
│           │       ├── rope_component.dart
│           │       └── button_component.dart
│           ├── sumo_bumper/
│           │   └── sumo_game.dart
│           └── penalty_shootout/
│               ├── penalty_game.dart
│               └── components/
│                   ├── soccer_ball.dart
│                   └── goalkeeper_hand.dart
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
