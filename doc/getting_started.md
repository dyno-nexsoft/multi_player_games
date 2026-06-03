# Getting Started — Hướng Dẫn Bắt Đầu Phát Triển

---

## Yêu Cầu Môi Trường

| Công cụ                | Phiên bản         | Ghi chú                    |
| ---------------------- | ----------------- | -------------------------- |
| FVM                    | ≥ 3.0             | Flutter Version Manager    |
| Flutter                | `stable` (3.44.x) | Quản lý qua FVM            |
| Dart                   | 3.12.x            | Đi kèm Flutter             |
| Android Studio / Xcode | Mới nhất          | Để build lên thiết bị thực |

---

## Cài Đặt Lần Đầu

```bash
# 1. Cài FVM (nếu chưa có)
dart pub global activate fvm

# 2. Clone project và vào thư mục code
cd multi_player_games/code

# 3. FVM đã được pin sẵn (file .fvm/fvm_config.json)
#    Lần đầu cần setup SDK:
fvm install

# 4. Cài packages
fvm flutter pub get

# 5. Kiểm tra không có lỗi
fvm flutter analyze
```

---

## Chạy Trên Thiết Bị Thực

> **Bắt buộc dùng thiết bị vật lý** — mDNS không hoạt động trên Simulator/Emulator.

```bash
# Liệt kê thiết bị đang kết nối
fvm flutter devices

# Chạy debug (hot reload)
fvm flutter run -d <device-id>

# Build release APK (Android)
fvm flutter build apk --release

# Build release IPA (iOS — cần Mac + provisioning profile)
fvm flutter build ios --release
```

**Cài đồng thời lên 2 máy:**

```bash
# Terminal 1
fvm flutter run -d <android-device-id>

# Terminal 2
fvm flutter run -d <ios-device-id>
```

---

## Cấu Hình Platform Cần Thiết

### Android (`android/app/src/main/AndroidManifest.xml`)

Đã khai báo sẵn trong project:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

### iOS (`ios/Runner/Info.plist`)

Đã khai báo sẵn:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Cần kết nối mạng cục bộ để tìm và chơi game với thiết bị khác.</string>
<key>NSBonjourServices</key>
<array>
    <string>_pgamehub._tcp</string>
</array>
```

> Nếu iOS từ chối quyền Local Network: vào **Settings → Privacy → Local Network** và bật lại cho app.

---

## Cấu Trúc Debug Thường Gặp

**Không tìm thấy phòng (mDNS fail):**

- Kiểm tra cả 2 máy cùng Wi-Fi/Hotspot
- Android 10+: cần cấp quyền Location lúc runtime
- iOS: kiểm tra quyền Local Network trong Settings

**JSON parse error trên socket:**

- Xem log bằng `AppLogger` — filter tag `Connection`
- Nguyên nhân thường: gói tin bị split do buffer — đã xử lý bằng line-framing `\n`

**Flame game không load:**

- `BaseMiniGame.onLoad()` phải gọi `await super.onLoad()`
- Kiểm tra `camera.viewfinder.visibleGameSize` đã set chưa

---

## Lệnh Hữu Ích

```bash
# Xem log realtime (lọc theo tag)
fvm flutter logs | grep "Connection\|Lobby\|Game"

# Chạy tests
fvm flutter test

# Cập nhật packages
fvm flutter pub upgrade

# Dọn build cache
fvm flutter clean && fvm flutter pub get
```
