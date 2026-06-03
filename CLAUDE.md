# Party Game Hub – CLAUDE.md

## 🛑 QUY TẮC BẮT BUỘC (CRITICAL RULES)

1. **Luôn đọc tài liệu trước khi code:** Trước khi triển khai bất kỳ tính năng nào, hoặc tìm kiếm thông tin về kiến trúc, cấu trúc thư mục, cách thêm game mới, bạn BẮT BUỘC phải đọc 2 file sau:
   - `doc/architecture.md` (Kinh thánh dự án - Quy chuẩn & Kiến trúc)
   - `doc/roadmap.md` (Kế hoạch & Đặc tả ý tưởng)
2. **Cập nhật Roadmap:** Sau khi hoàn thành một tính năng bất kỳ, bạn BẮT BUỘC phải chủ động mở file `doc/roadmap.md` và gạch bỏ/cập nhật lại tiến độ (đánh dấu `[x]`) cho tính năng đó.

---

## Flutter / Dart toolchain

**Luôn dùng `fvm flutter` và `fvm dart`** thay cho `flutter` / `dart` trực tiếp.  
Project dùng FVM (Flutter Version Manager) với channel `stable`.

```bash
# ✅ Đúng
fvm flutter run
fvm flutter pub get
fvm dart run build_runner build

# ❌ Sai – dùng global Flutter/Dart sẽ fail khi resolve packages
flutter run
dart run
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
