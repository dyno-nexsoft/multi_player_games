# Party Game Hub – CLAUDE.md

## Flutter / Dart toolchain

**Luôn dùng `fvm flutter` và `fvm dart`** thay cho `flutter` / `dart` trực tiếp.  
Project dùng FVM (Flutter Version Manager) với channel `stable` (hiện tại: Flutter 3.44.1 / Dart 3.12.1).

```bash
# ✅ Đúng
fvm flutter run
fvm flutter pub get
fvm dart run build_runner build

# ❌ Sai – dùng global Flutter 3.35.6 / Dart 3.9.2, sẽ fail khi resolve packages
flutter run
dart run
```

## Cấu trúc dự án

```
code/                          ← thư mục Flutter project
├── lib/
│   ├── main.dart
│   ├── router.dart            ← go_router, tất cả routes
│   ├── core/
│   │   ├── network/           ← GamePacket, NetworkService (TCP socket)
│   │   ├── theme/             ← AppTheme
│   │   ├── localization/      ← LocaleProvider (vi/en toggle)
│   │   └── utils/             ← AppLogger
│   └── features/
│       ├── lobby/
│       │   ├── data/          ← ConnectionRepository (mDNS + socket)
│       │   ├── domain/        ← Player (freezed)
│       │   └── presentation/  ← LobbyScreen, RoomScreen, DiscoverScreen, LobbyProvider
│       └── game/
│           ├── domain/        ← BaseMiniGame, MiniGameMetadata, MiniGameRegistry
│           ├── data/          ← GameNetworkRouter
│           ├── presentation/  ← GameHubScreen, GameProvider, CountdownOverlay
│           └── mini_games/
│               ├── tug_of_war/
│               ├── sumo_bumper/
│               ├── penalty_shootout/
│               └── air_hockey/
├── assets/
│   ├── icons/                 ← icon PNG cho mỗi mini-game
│   └── images/
└── pubspec.yaml               ← sdk: ^3.12.0
```

## Lệnh thường dùng

```bash
# Lấy packages
fvm flutter pub get

# Chạy app (debug)
fvm flutter run

# Build Android APK
fvm flutter build apk --release

# Code generation (freezed, json_serializable, go_router)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch mode cho code gen
fvm dart run build_runner watch --delete-conflicting-outputs

# Analyze
fvm flutter analyze

# Tests
fvm flutter test
```

## Widget Preview (Flutter 3.44.1+)

Các file sau có `@Preview` annotations để dùng tính năng Widget Preview trong VS Code:

- `lib/features/lobby/presentation/lobby_screen.dart` – preview các button và text field
- `lib/features/game/presentation/overlays/countdown_overlay.dart` – preview countdown animation

Cách mở preview: trong VS Code, mở file dart có `@Preview`, sau đó click nút **"Open Widget Preview"** hoặc dùng Command Palette → *Flutter: Open Widget Preview*.

## Kiến trúc

- **State management**: `provider` – `LobbyProvider` quản lý vòng đời phòng chờ, `GameProvider` quản lý game state
- **Navigation**: `go_router` – routes: `/` (Lobby), `/room`, `/discover`, `/game`
- **Networking**: TCP socket trực tiếp qua `ConnectionRepository`; mDNS (`nsd`) để discover phòng trên LAN
- **Game engine**: `flame` – mỗi mini-game kế thừa `BaseMiniGame extends FlameGame`
- **Localization**: vi / en, toggle real-time qua `LocaleProvider`

## Thêm mini-game mới

1. Tạo thư mục `lib/features/game/mini_games/<game_id>/`
2. Implement class kế thừa `BaseMiniGame`
3. Đăng ký trong `MiniGameRegistry.availableGames` và `createGame()`
4. Thêm icon vào `assets/icons/`
5. Thêm localized strings vào `lib/l10n/app_localizations_vi.dart` và `_en.dart`
6. Chạy `fvm dart run build_runner build` nếu có thêm freezed/json models
