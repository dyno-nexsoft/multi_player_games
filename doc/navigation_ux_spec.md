# Đặc Tả Kiến Trúc Điều Hướng (Navigation UX Spec)

Tài liệu này quy định các chuẩn mực về chuyển trang, hiệu ứng chuyển cảnh và xử lý menu để tạo ra trải nghiệm "liền mạch" (seamless) nhất cho tựa game Neon Dark P2P. 

---

## 1. Kiến Trúc GoRouter

Ứng dụng bắt buộc sử dụng `go_router` để quản lý toàn bộ luồng điều hướng, hỗ trợ deep-linking và custom transitions.

### 1.1 Cấu trúc Route
```dart
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LobbyScreen(),
    ),
    GoRoute(
      path: '/room/:id',
      builder: (context, state) {
        final roomId = state.pathParameters['id']!;
        return RoomScreen(roomId: roomId);
      },
      routes: [
        GoRoute(
          path: 'game/:gameId',
          builder: (context, state) {
            final gameId = state.pathParameters['gameId']!;
            return GameHubScreen(gameId: gameId);
          },
        ),
      ]
    ),
  ],
);
```

---

## 2. Hiệu Ứng Chuyển Trang (Custom Transitions)

Tuyệt đối KHÔNG dùng hiệu ứng vuốt ngang mặc định của iOS/Android. Tất cả các page phải được bọc trong `CustomTransitionPage`.

### 2.1 Fade & Scale Transition (Hiệu ứng không gian mạng)
Áp dụng khi chuyển từ `Lobby` vào `Room`.

```dart
CustomTransitionPage(
  key: state.pageKey,
  child: RoomScreen(roomId: id),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
        child: child,
      ),
    );
  },
);
```

### 2.2 Hero Animations
*   Mọi Game Card trên Lobby đều chứa một Widget `Hero` bọc lấy Icon của game (tag là `game_icon_$gameId`).
*   Khi vào màn hình `GameHubScreen`, icon này sẽ "bay" ra giữa màn hình và phóng to trở thành một phần của background, tạo cảm giác người chơi bị hút vào game.

---

## ✅ Trạng Thái Triển Khai

| Mục | Trạng thái | File |
|---|---|---|
| GoRouter Fade+Scale cho tất cả routes | ✅ Xong | `router.dart` — helper `_fadeScale()` dùng `easeInOutCirc` |
| Hero animation game icon | ✅ Xong | `neon_widgets.dart` `NeonGameCard` + `GameHubScreen` loading screen |
| Radar overlay khi kết nối TCP | ✅ Xong | `discover_screen.dart` — `showGeneralDialog` với `RadarWidget` |
| In-game pause menu | ✅ Xong | `game_hub_screen.dart` — long press / nút pause → `_PauseDialog` glassmorphism |
| Scoreboard overlay trên Flame canvas | ✅ Xong | `ScoreboardOverlay` (slide-in + blur backdrop) trong `neon_widgets.dart` |
| `leaveGame()` clean-up | ✅ Xong | `game_provider.dart` — gọi từ "Rời Phòng" và "Back to Lobby" |

---

## 3. Chiến Lược Overlay (Không Chuyển Trang Mới)

Để tránh đứt gãy kết nối P2P và duy trì trạng thái game, các tác vụ phụ sẽ KHÔNG dùng `context.push()`. Thay vào đó, chúng ta dùng Overlay.

### 3.1 Loading Overlay (Radar Sweep)
*   Khi nhấn "Join Room", thay vì hiện màn hình loading trắng, ta dùng `showGeneralDialog` hiển thị hiệu ứng radar quét (Lottie) đè lên màn hình Lobby hiện tại với background trong suốt.
*   Chỉ gọi `context.go('/room/:id')` khi socket báo `connected`.

### 3.2 In-Game Pause & Settings
*   Khi bắt thao tác "Vuốt xuống" (Swipe down) hoặc "Long Press", game kích hoạt `showGeneralDialog` với `barrierColor: Colors.black54` (hoặc áp dụng BackdropFilter tạo hiệu ứng blur Glassmorphism).
*   Chứa 2 nút CTA khổng lồ: **Tiếp Tục** và **Rời Phòng**.

### 3.3 Màn Hình Kết Quả (Victory/Defeat)
*   Hiển thị đè trực tiếp lên bảng game (Flame canvas) thông qua thuộc tính `overlayBuilderMap` của `GameWidget` (trong Flutter Flame). 
*   Việc này giúp người chơi thấy kết quả nhanh nhất, và ấn "Rematch" ngay trên Overlay mà không cần đẩy ra khỏi page hiện tại.
