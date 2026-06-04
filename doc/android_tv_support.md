# Android TV Support — Party Game Hub

Tài liệu này mô tả **use case, kiến trúc, các thay đổi kỹ thuật cần thiết và kế hoạch triển khai** để Party Game Hub hoạt động trên Android TV. Đọc kết hợp với [tv_ui_ux_spec.md](./tv_ui_ux_spec.md) cho phần UI/UX.

---

## 1. Tổng Quan Use Case

### 1.1 Mô Hình Triển Khai Lý Tưởng

```
                 ┌─────────────────────────────────────┐
                 │          Android TV (Host)          │
                 │  ┌───────────────────────────────┐  │
                 │  │  Party Game Hub — Console Mode│  │
                 │  │  • Hiển thị QR + Emoji code   │  │
                 │  │  • Sân khấu avatar người chơi │  │
                 │  │  • Flame Game Canvas          │  │
                 │  │  • Bảng điểm                  │  │
                 │  └───────────────────────────────┘  │
                 └─────────────────┬───────────────────┘
                                   │ TCP/WiFi LAN
               ┌───────────────────┼───────────────────┐
               │                   │                   │
    ┌──────────▼──────┐  ┌─────────▼───────┐  ┌───────▼─────────┐
    │  Điện thoại A   │  │  Điện thoại B   │  │  Điện thoại C   │
    │ (Client/Tay cầm)│  │ (Client/Tay cầm)│  │ (Client/Tay cầm)│
    └─────────────────┘  └─────────────────┘  └─────────────────┘
```

**Kịch bản:** TV là **màn hình trung tâm** — chạy ở vai trò Host + Console Mode. Điện thoại của mỗi người chơi quét QR/nhập emoji để kết nối và hoạt động như tay cầm không dây.

### 1.2 Các Kịch Bản Hỗ Trợ

| #   | Kịch bản                             | Mô tả                                                   | Độ ưu tiên            |
| --- | ------------------------------------ | ------------------------------------------------------- | --------------------- |
| 1   | **TV-as-Host + Phone-as-Controller** | TV chạy Host, điện thoại làm tay cầm                    | ✅ Chính yếu          |
| 2   | **Tablet HDMI → TV**                 | Tablet/điện thoại lớn cắm HDMI ra TV                    | ✅ Hỗ trợ ngay        |
| 3   | **TV thuần túy**                     | Người dùng điều hướng bằng remote D-pad để tự tạo phòng | 🔄 Cần thêm D-pad nav |
| 4   | **Gamepad vật lý trên TV**           | Tay cầm Bluetooth/USB cắm vào TV tham gia như player    | 🔮 Roadmap tương lai  |

### 1.3 Luồng Người Dùng Chi Tiết (Use Case 1)

```
[Người chơi bật TV]
       │
       ▼
[Mở Party Game Hub trên TV]
       │
       ▼ App tự nhận diện màn hình lớn
[Console Mode Lobby hiện lên]
  • QR code khổng lồ góc trái
  • Emoji code 4 ký tự góc phải
  • "Đang chờ người chơi..." animation
       │
       ▼ Mỗi người chơi:
[Quét QR / Nhập emoji trên điện thoại]
       │
       ▼
[Avatar neon rơi xuống "sân khấu" trên TV]  ← Drop-in animation
       │
       ▼ [Host nhấn Start trên remote]
[Màn hình đếm ngược + hint game]
       │
       ▼
[Game Canvas full-screen trên TV]
  • HUD điểm 4 góc
  • Điện thoại = tay cầm real-time
       │
       ▼ [Game kết thúc]
[Bảng điểm animate trên TV]
       │
       ▼
[Quay về sảnh chờ — chọn game tiếp]
```

---

## 2. Trạng Thái Tương Thích Hiện Tại

### 2.1 Những Thứ Đã Hoạt Động ✅

| Thành phần                       | Lý do hoạt động                                   |
| -------------------------------- | ------------------------------------------------- |
| Flutter Engine                   | Flutter hỗ trợ Android TV natively từ Flutter 3.x |
| Flame Game Canvas                | Canvas render fullscreen, không phụ thuộc touch   |
| TCP Socket / mDNS (`nsd`)        | Hoạt động bình thường trên Android TV WiFi        |
| Dark Neon Theme                  | Màu tối tương phản cao — lý tưởng cho TV          |
| `isConsoleMode` flag             | App đã có kiến trúc phân biệt Host màn hình lớn   |
| `ConstrainedBox(maxWidth: 500)`  | Giao diện Lobby không bị stretch                  |
| `PopScope` trong `GameHubScreen` | Đã có dialog xác nhận thoát                       |
| Localization (vi/en)             | Sẵn sàng cho mọi thị trường                       |

### 2.2 Những Thứ Cần Thay Đổi ❌

| Vấn đề                                      | Mức độ        | Giải pháp                        |
| ------------------------------------------- | ------------- | -------------------------------- |
| `AndroidManifest.xml` thiếu TV declarations | 🔴 Blocker    | Thêm 3 dòng XML                  |
| `mobile_scanner` yêu cầu camera             | 🔴 Blocker    | Khai báo `required="false"`      |
| Không có D-pad navigation                   | 🟡 Quan trọng | Thêm `Focus` widget cho lobby    |
| `android:banner` cho TV launcher            | 🟡 Quan trọng | Tạo ảnh banner 320×180px         |
| Auto-detect màn hình lớn                    | 🟡 Quan trọng | Logic `isConsoleMode` tự động    |
| `WakeLock` — TV tự tối màn hình             | 🟠 Trung bình | Thêm `wakelock_plus`             |
| `sensors_plus` — TV không có sensor         | 🟢 Nhỏ        | Package graceful-fail, cần guard |
| Nhập văn bản (tên, phòng) trên TV           | 🟠 Trung bình | Virtual keyboard hoặc hide field |

---

## 3. Thay Đổi Kỹ Thuật Cần Thiết

### 3.1 AndroidManifest.xml

**File:** `code/android/app/src/main/AndroidManifest.xml`

Cần thêm các khai báo sau để app hiển thị đúng trên TV launcher và không bị reject:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- ✅ THÊM: Khai báo hỗ trợ TV -->
    <!-- required="false" → app vẫn install được trên điện thoại thường -->
    <uses-feature
        android:name="android.software.leanback"
        android:required="false" />

    <!-- ✅ THÊM: TV không có màn hình cảm ứng -->
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />

    <!-- ✅ THÊM: Camera là optional (mobile_scanner) -->
    <uses-feature
        android:name="android.hardware.camera"
        android:required="false" />

    <application
        android:label="Party Game Hub"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon"
        android:banner="@drawable/tv_banner"> <!-- ✅ THÊM: Banner cho TV launcher -->

        <activity
            android:name=".MainActivity"
            android:exported="true"
            ...>
            <!-- Intent filter hiện tại (giữ nguyên) -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

            <!-- ✅ THÊM: Intent filter cho TV launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

> **Lưu ý:** `android:required="false"` trên tất cả `uses-feature` là bắt buộc. Nếu để `true`, Google Play sẽ chặn app trên điện thoại không có tính năng đó.

### 3.2 TV Banner Asset

Tạo file ảnh banner tại `code/android/app/src/main/res/drawable/tv_banner.png`:

- **Kích thước:** 320 × 180 px (tỷ lệ 16:9)
- **Nội dung:** Logo app + tên "Party Game Hub" trên nền tối neon
- **Mục đích:** Hiển thị trên màn hình chọn app của Android TV Launcher

### 3.3 Auto-Detect Console Mode

**File:** `lib/features/lobby/presentation/lobby_screen.dart` (hoặc `main.dart`)

Thêm logic tự động nhận diện màn hình TV/lớn khi app khởi động:

```dart
/// Kiểm tra thiết bị có phải màn hình lớn (TV/Tablet landscape) không.
/// Trả về true nếu chiều rộng > 900dp và thiết bị ở landscape.
bool _isLargeScreen(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final orientation = MediaQuery.orientationOf(context);
  return size.width > 900 && orientation == Orientation.landscape;
}
```

Kích hoạt trong `LobbyScreen.build`:

```dart
@override
Widget build(BuildContext context) {
  // Tự động bật Console Mode nếu màn hình lớn
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_isLargeScreen(context) && mounted) {
      context.read<LobbyProvider>().setConsoleMode(true);
    }
  });
  // ...
}
```

> **Quan trọng:** Cần đặt trong `addPostFrameCallback` để tránh `setState` trong `build`.

### 3.4 D-Pad Navigation cho Lobby

TV remote điều hướng bằng D-pad (lên/xuống/trái/phải/OK). Flutter hỗ trợ thông qua `FocusNode` và `Focus` widget.

**Nguyên tắc:**

1. Mỗi nút tương tác phải có `FocusNode` riêng
2. Bọc bằng `FocusTraversalGroup` để xác định thứ tự tab
3. Thêm hiệu ứng visual khi focus (scale + glow)

**Ví dụ — Nút với D-pad support:**

```dart
class _TvFocusButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color glowColor;

  const _TvFocusButton({
    required this.onPressed,
    required this.child,
    required this.glowColor,
  });

  @override
  State<_TvFocusButton> createState() => _TvFocusButtonState();
}

class _TvFocusButtonState extends State<_TvFocusButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: AnimatedScale(
        scale: _isFocused ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [BoxShadow(color: widget.glowColor, blurRadius: 20, spreadRadius: 2)]
                : null,
          ),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

### 3.5 WakeLock — Giữ Màn Hình Sáng

Thêm dependency:

```yaml
# pubspec.yaml
dependencies:
  wakelock_plus: ^1.2.10
```

Kích hoạt trong `RoomScreen` khi là Host Console Mode:

```dart
import 'package:wakelock_plus/wakelock_plus.dart';

class _RoomScreenState extends State<RoomScreen> {
  @override
  void initState() {
    super.initState();
    final lobby = context.read<LobbyProvider>();
    // Giữ màn hình sáng khi là Host (TV không nhận touch → auto-sleep)
    if (lobby.isHost && lobby.isConsoleMode) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // Tắt khi rời phòng
    super.dispose();
  }
}
```

### 3.6 Guard sensors_plus trên TV

`sensors_plus` có thể throw error trên thiết bị không có accelerometer/gyroscope. Bọc tất cả sensor calls:

```dart
// ❌ Sai — crash trên TV
accelerometerEventStream().listen((event) { ... });

// ✅ Đúng — graceful fallback
try {
  accelerometerEventStream().listen((event) { ... });
} catch (_) {
  // TV không có sensor — bỏ qua
}
```

---

## 4. Phân Tích Tương Thích Package

| Package              | TV Compatible? | Ghi chú                                                            |
| -------------------- | -------------- | ------------------------------------------------------------------ |
| `flutter`            | ✅ Đầy đủ      |                                                                    |
| `flame`              | ✅ Đầy đủ      | Canvas không phụ thuộc touch                                       |
| `go_router`          | ✅ Đầy đủ      |                                                                    |
| `provider`           | ✅ Đầy đủ      |                                                                    |
| `nsd` (mDNS)         | ✅ Đầy đủ      | WiFi hoạt động bình thường                                         |
| `google_fonts`       | ✅ Đầy đủ      |                                                                    |
| `flutter_svg`        | ✅ Đầy đủ      |                                                                    |
| `qr_flutter`         | ✅ Đầy đủ      | QR hiển thị tốt trên TV                                            |
| `shared_preferences` | ✅ Đầy đủ      |                                                                    |
| `audioplayers`       | ✅ Đầy đủ      |                                                                    |
| `flame_audio`        | ✅ Đầy đủ      |                                                                    |
| `mobile_scanner`     | ⚠️ Cần guard   | TV không có camera → khai báo `required="false"`, ẩn QR scanner UI |
| `sensors_plus`       | ⚠️ Cần guard   | Bọc try-catch, graceful fail                                       |
| `message_pack_dart`  | ✅ Đầy đủ      |                                                                    |
| `json_annotation`    | ✅ Đầy đủ      |                                                                    |

---

## 5. Kiến Trúc Console Mode (Đã Có Sẵn)

App đã có `isConsoleMode` flag trong `LobbyProvider`. Đây là nền tảng để xây dựng TV support:

```
LobbyProvider
├── isHost: bool          — Thiết bị này là TCP Server
├── isConsoleMode: bool   — Thiết bị này là "màn hình lớn"
└── localPlayer           — Người chơi tại thiết bị này

Console Mode (isConsoleMode = true):
  ├── UI: ConsoleLobbyScreen (QR lớn + sân khấu avatar)
  ├── Game: GameHubScreen full-screen Flame canvas
  └── HUD: Score overlay 4 góc, không có touch controls
```

### 5.1 Luồng Kích Hoạt Console Mode

```dart
// Người dùng bật TV Mode thủ công trong LobbyScreen
Switch(
  value: _tvMode,
  onChanged: (v) {
    setState(() => _tvMode = v);
    // isConsoleMode được truyền vào createRoom()
  },
)

// Hoặc tự động:
if (_isLargeScreen(context)) {
  lobby.setConsoleMode(true);
}
```

---

## 6. Xử Lý Input Trên TV

### 6.1 Remote D-Pad Mapping

Android TV remote gửi các key event chuẩn Android. Flutter nhận thông qua `RawKeyboardListener` hoặc `KeyboardListener` (Flutter 3.18+):

| Nút Remote        | Android KeyCode            | Hành động trong App           |
| ----------------- | -------------------------- | ----------------------------- |
| D-Pad OK / Center | `KEYCODE_DPAD_CENTER`      | Confirm / Select              |
| D-Pad Up          | `KEYCODE_DPAD_UP`          | Focus lên                     |
| D-Pad Down        | `KEYCODE_DPAD_DOWN`        | Focus xuống                   |
| D-Pad Left        | `KEYCODE_DPAD_LEFT`        | Focus trái                    |
| D-Pad Right       | `KEYCODE_DPAD_RIGHT`       | Focus phải                    |
| Back              | `KEYCODE_BACK`             | Pop / Cancel (cần `PopScope`) |
| Play/Pause        | `KEYCODE_MEDIA_PLAY_PAUSE` | Pause game                    |

### 6.2 Màn Hình Cần D-Pad Navigation

| Màn hình                     | Nút cần focus             | Ưu tiên       |
| ---------------------------- | ------------------------- | ------------- |
| `LobbyScreen` (Console Mode) | Nút "Bắt đầu"             | 🔴 Bắt buộc   |
| `RoomScreen`                 | Nút Start game, chọn game | 🔴 Bắt buộc   |
| `GameHubScreen` pause menu   | Tiếp tục / Rời phòng      | 🔴 Bắt buộc   |
| Scoreboard                   | Next Round, Rematch, Back | 🟡 Quan trọng |

### 6.3 Input Không Cần Hỗ Trợ Trên TV

- **TextField nhập tên / phòng:** Trên TV, ẩn hoặc dùng giá trị mặc định "TV Host" / "TV Room". Người dùng không cần gõ bàn phím trên TV.
- **QR Scanner:** Ẩn button quét QR trên TV — TV làm Host, không cần quét vào phòng khác.
- **Emoji join:** Ẩn trên TV vì lý do tương tự.

---

## 7. Kiểm Thử Trên Android TV

### 7.1 Môi Trường Kiểm Thử

**Option A: Android TV Emulator (Khuyến nghị cho dev)**

```
Android Studio → Device Manager → Create Device
→ Category: TV → chọn "Android TV (1080p)"
→ API Level: 33+ (Android 13)
```

**Option B: Thiết Bị Thực**

- Android TV box (Xiaomi Mi Box, NVIDIA Shield, v.v.)
- Chromecast with Google TV
- Smart TV chạy Android TV OS (Sony, Philips, v.v.)

**Option C: Tablet + `--device-id`**

```bash
# Kết nối tablet, đổi orientation sang landscape
fvm flutter run --device-id <tablet_id>
```

### 7.2 Checklist Kiểm Thử

```
Cài đặt & Khởi động
[ ] App cài được từ APK không lỗi
[ ] App hiện đúng trong TV Launcher với banner
[ ] Mở app → vào thẳng Console Mode (màn hình lớn tự detect)

Lobby & Kết nối
[ ] QR code hiển thị rõ, quét được từ xa 3 mét
[ ] Emoji code đủ lớn, đọc được từ sofa
[ ] Điện thoại kết nối qua QR thành công
[ ] Điện thoại kết nối qua emoji thành công
[ ] Avatar người chơi hiện trên "sân khấu" TV
[ ] Không bị crash khi TV không có camera (mobile_scanner guard)

D-Pad Navigation
[ ] Remote có thể focus vào nút Start
[ ] Nhấn OK trên remote → chọn game
[ ] Nhấn Back → hiện dialog xác nhận (không thoát thẳng)
[ ] Focus indicator (glow/scale) hiển thị đúng

In-Game
[ ] Game Canvas full-screen trên TV
[ ] Input từ điện thoại phản hồi < 100ms (cùng WiFi)
[ ] HUD điểm hiển thị đúng 4 góc
[ ] Không bị tối màn hình trong game (WakeLock hoạt động)
[ ] Pause bằng remote → menu pause hiện đúng

Kết thúc Game
[ ] Scoreboard hiển thị đúng, animation ổn
[ ] Rematch hoạt động
[ ] Back to Lobby hoạt động
[ ] Thoát app qua remote → dialog xác nhận
```

---

## 8. Kế Hoạch Triển Khai (Implementation Roadmap)

### Phase 1 — Minimum Viable TV (2-3 ngày) 🔴

Để app **install và chạy được** trên Android TV:

- [x] Cập nhật `AndroidManifest.xml` (TV declarations + camera optional + LEANBACK_LAUNCHER)
- [x] Tạo `tv_banner.xml` placeholder (320×180dp — thay bằng PNG thật khi có design)
- [x] Guard `mobile_scanner` — ẩn Join section khi TV mode được phát hiện
- [x] Guard `sensors_plus` với try-catch (đã có trong `ConsoleProvider._startGyro()`)
- [ ] Test trên Android TV emulator

### Phase 2 — Auto-Detect & Polish (3-5 ngày) 🟡

Để app **hoạt động đúng** trên TV không cần cấu hình thủ công:

- [x] Implement `_isLargeScreen()` + auto set `_tvMode` trong `LobbyScreen`
- [x] Thêm `wakelock_plus` vào `TvLobbyScreen` (Console Host)
- [x] Thêm D-pad focus vào `_TvButton` (`TvLobbyScreen`)
- [x] Ẩn TextField nhập tên/phòng trên TV (dùng mặc định "TV Host" / "TV Room")
- [ ] Test end-to-end: TV + 2 điện thoại

### Phase 3 — Full TV Experience (1-2 tuần) 🟢

Để có **trải nghiệm TV premium** theo spec `tv_ui_ux_spec.md`:

- [x] `TvLobbyScreen` riêng (QR lớn + sân khấu 60% màn hình) — route `/tv-lobby`
- [x] Drop-in animation avatar khi người chơi tham gia (elasticOut slide từ trên)
- [ ] Landscape HUD (4 góc / score bar tùy số người)
- [ ] Visual feedback avatar nhấp nháy khi client tap
- [ ] Optimize typography cho 10-foot UI (24sp minimum)
- [ ] Overscan safe area (5% margin)

### Phase 4 — Gamepad Physical (Tương lai) 🔮

- [ ] Tích hợp package `gamepads` để nhận input tay cầm USB/BT
- [ ] Đăng ký tay cầm vật lý như Local Player
- [ ] Mixed mode: vừa phone controllers vừa gamepad

---

## 9. Phân Phối Lên Android TV

### 9.1 Google Play — Android TV Channel

Để xuất hiện trên **Google Play for Android TV**:

1. **App phải có `LEANBACK_LAUNCHER` intent-filter** (đã xử lý ở mục 3.1)
2. **Banner 320×180px** bắt buộc (mục 3.2)
3. **Không có `uses-feature` bắt buộc** mà TV không có (camera, touchscreen)
4. Submit qua Google Play Console → chọn thêm "Android TV" trong Device targeting

### 9.2 Sideload APK (Phân phối trực tiếp)

Cách dễ nhất để test và chia sẻ:

```bash
# Build APK
fvm flutter build apk --release

# Cài qua ADB (TV phải bật Developer Mode)
adb connect <TV_IP>:5555
adb install build/app/outputs/flutter-apk/app-release.apk
```

CI/CD hiện tại (GitHub Actions) đã hỗ trợ build APK tự động — xem [architecture.md](./architecture.md#github-actions-cicd-workflow).

---

## 10. Câu Hỏi Thường Gặp

**Q: Người chơi có cần cài app trên điện thoại không?**

> Có. Điện thoại cài app và chạy vai trò Client (tay cầm). TV cài app và chạy vai trò Host (màn hình).

**Q: Có cần internet không?**

> Không. Tất cả giao tiếp qua TCP/mDNS trong mạng WiFi nội bộ. Xem [architecture.md](./architecture.md#mô-hình-mạng-host-client).

**Q: TV và điện thoại có cần cùng mạng WiFi không?**

> Có — đây là yêu cầu cơ bản của toàn bộ hệ thống P2P.

**Q: Độ trễ input (điện thoại → game trên TV) là bao nhiêu?**

> Trong cùng WiFi, latency thường < 50ms — đủ mượt cho game party. Nếu > 100ms, kiểm tra chất lượng router.

**Q: TV có thể vừa là Host vừa chơi game không?**

> Hiện tại Host chạy Flame game nhưng không có input touch. Trong tương lai (Phase 4), có thể thêm tay cầm vật lý kết nối vào TV để Host cũng là Player.

---

_Cập nhật lần cuối: 2026-06-04 | Phiên bản: 1.0.0_
_Tài liệu liên quan: [tv_ui_ux_spec.md](./tv_ui_ux_spec.md) | [architecture.md](./architecture.md) | [roadmap.md](./roadmap.md)_
