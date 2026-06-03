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
