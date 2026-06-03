# Chiến Lược Kiểm Thử

---

## Kiểm Thử Thủ Công (Bắt Buộc)

Simulator/Emulator **không thể** test mDNS và TCP Socket thực. Phải dùng **thiết bị vật lý**.

**Yêu cầu:** 2 thiết bị thực (tốt nhất: 1 Android + 1 iOS), cùng Wi-Fi hoặc một máy bật Hotspot.

### Checklist Test Cơ Bản

| # | Kịch bản | Tiêu chí pass |
|---|---|---|
| 1 | Host tạo phòng → Client quét thấy | Phòng hiện trong vòng < 3 giây |
| 2 | Client tham gia → cả 2 thấy nhau ở RoomScreen | Danh sách player sync đúng |
| 3 | Host bắt đầu game → cả 2 vào Flame cùng lúc | Không lệch quá 0.5 giây |
| 4 | Tap liên tục (5 ngón) trong Tug of War | Không crash, không lỗi JSON parse |
| 5 | Tắt Wi-Fi Client đang chơi | Host phát hiện disconnect trong 3–5 giây |
| 6 | Thu nhỏ app → mở lại trong 2 giây | Game tiếp tục, không crash |
| 7 | iOS: lần đầu mở app | Hộp thoại xin quyền Local Network hiện đúng |
| 8 | iOS: từ chối quyền Local Network | App hiện hướng dẫn bật lại trong Settings |

---

## Kiểm Thử Tự Động

**Unit test** (`test/`): Tập trung vào những gì không cần mạng hay UI.

Ưu tiên test:
```dart
// GamePacket serialize/deserialize
test('GamePacket round-trip JSON', () {
  final packet = GamePacket(type: 'join', timestamp: 0, payload: {'name': 'Tom'});
  final parsed = GamePacket.tryParse(packet.toWire().trim());
  expect(parsed?.payload['name'], 'Tom');
});

// Tọa độ chéo màn hình (khi implement Air Hockey)
test('cross-screen X coordinate mirror', () {
  expect(1.0 - 0.3, 0.7); // x_out = 0.3 → x_in = 0.7
});
```

**Widget test**: Dùng mock `LobbyProvider` để test RoomScreen hiển thị đúng danh sách player.

**Integration test**: Không ưu tiên — mDNS không chạy được trên CI.

---

## Tiêu Chuẩn Chất Lượng Tối Thiểu

- `flutter analyze` → **0 errors, 0 warnings**
- Nút bấm tối thiểu `48×48dp`
- Không dùng `print()`, chỉ dùng `AppLogger`
- Không force unwrap `!` trên dữ liệu từ network
