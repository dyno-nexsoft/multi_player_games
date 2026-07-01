# Party Game Hub — Feature Roadmap & Backlog

Tài liệu này lưu trữ tiến độ phát triển và các ý tưởng tính năng (Backlog) chưa được triển khai.

---

## 1. 🚀 Tiến Độ & Roadmap Ngắn Hạn

_Ghi chú: Các Phase 1 (Haptic, Rematch), Phase 2 (QR, Color), Phase 3 (Network) đã hoàn thành 95%._

### Phase 4: Mở rộng Mini-Games

- ~~[x] **Khúc Côn Cầu Chéo (Cross Air Hockey)**~~ — Đã xóa (quá phức tạp cho party)
- [x] **Đấu Xe Tăng (Tank Fight):** Cơ chế "Fog of War" che khuất tầm nhìn chéo.
- ~~[x] **Bắn Cung (Archer Duel)**~~ — Đã xóa (2 người)
- ~~[x] **Hải Chiến Không Gian (Battleship)**~~ — Đã xóa (2 người)
- ~~[x] **Kéo Co Tốc Độ (Tug of War)**~~ — Đã xóa (chỉ 2 người, không phù hợp party)
- ~~[x] **Xúc Xắc Tố (Liars Dice)**~~ — Đã xóa (chỉ 2 người)
- ~~[x] **Vẽ & Đoán (Draw & Guess)**~~ — Đã xóa (chỉ 2 người)
- [x] **Trốn Tìm Mê Cung (Maze Hide & Seek):** Đuổi bắt với tầm nhìn giới hạn, có dùng skill (Radar, Dash).
- [x] **Bom Hẹn Giờ (Hot Potato):** Ném bom ngẫu nhiên sang bất kỳ ai trong nhóm (2–6 người).

### Phase 4b: Party / Drinking Games (Hoàn thành)

- [x] **Thật Hay Thách (Truth or Dare):** Vòng quay chọn ngẫu nhiên 1 người, bộ câu hỏi/thách tiếng Việt. 3–8 người, 8 vòng.
- [x] **Vòng Quay Số Phận (Spin Picker):** Bánh xe quay chỉ vào ai — họ nhận nhiệm vụ ngẫu nhiên (uống, hát, bắt chước...). 3–8 người, 10 vòng.
- [x] **Tôi Chưa Bao Giờ (Never Have I Ever):** 5 ngón tay, ai đã từng làm mất 1 ngón. Bộ 24 câu tiếng Việt phù hợp nhậu. 3–8 người, 12 vòng.

### Phase 4c: Technical Debt + Nội Dung (Hoàn thành 2026-06-30)

- [x] **Phase Enums:** `TodPhase`, `SpinPhase`, `NhiePhase` — thay raw string `_phase` bằng sealed enum, compile-safe.
- [x] **Registry Factory Map:** Thay 13-case switch trong `MiniGameRegistry.createGame()` bằng `_factories` map — OCP compliant, thêm game mới chỉ cần 2 chỗ.
- [x] **Localize Party Game Labels:** Tất cả UI label (button text, status, title) trong Truth or Dare / Spin Picker / Never Have I Ever đã localiz qua ARB. Thêm 36+ key vào `app_vi.arb` và `app_en.arb`.
- [x] **Mở rộng nội dung Truth or Dare:** 20 → 35 câu truth (VI), thêm 35 câu truth (EN) + 35 câu dare (VI + EN).
- [x] **Mở rộng nội dung Spin Picker:** 20 → 40 nhiệm vụ (VI, chia safe/18+), thêm 40 nhiệm vụ (EN).
- [x] **Mở rộng nội dung Never Have I Ever:** 24 → 48 câu (VI), thêm 48 câu (EN). Locale-aware via `PlatformDispatcher`.

### Phase 5: Advanced & Scaling

- [x] **Hỗ trợ 3-4 Người Chơi:** Mở rộng `ConnectionRepository` và UI Lobby để thêm Slot người chơi (Xanh lá, Vàng). Scale các Mini-Game lên 4 player (Tank, Sumo, Maze).
- [x] **Chế Độ Giải Đấu Xoay Vòng (Roulette Cup):** Thay vì chơi 1 game lẻ, quay ngẫu nhiên mini-game, tính điểm Best of 5 với cúp pha lê.
- [ ] **Play Store CI/CD Deploy:** Đẩy AAB lên Internal Track (Cần setup Secret Keys).

---

## 2. 📺 Chế Độ Console-Controller (Asymmetric Mode)

Chế độ chia tách 1 thiết bị làm màn hình (Host) và các thiết bị khác làm tay cầm (Client).

- [x] **Host (TV/Tablet):** Chạy Flame Engine, xử lý đồ họa, tính toán vật lý (Source of Truth). Giao diện TV tối ưu cho Remote (10-foot UI), hiển thị Mã QR to và Sân Khấu Avatar Drop-in. _(Implemented: `TvLobbyScreen` — `/tv-lobby`)_
- [x] **Client (Phone):** Chỉ hiển thị **Tay Cầm Vạn Năng** (UI Flutter tĩnh cực nhẹ tiết kiệm pin). _(Implemented: `GamepadScreen` — `/gamepad`)_
  - [x] _Bố cục:_ Joystick trái, 4 nút (A, B, X, Y) phải.
  - [x] _Input:_ Gửi tọa độ Joystick và trạng thái Nút qua TCP ở tần số 30Hz. Kèm theo dữ liệu Cảm Biến Nghiêng (Gyro) chạy ngầm.
  - [x] _Feedback:_ Lắng nghe lệnh từ Host để rung (Haptic) hoặc chớp viền.

---

## 3. ✨ Tính Năng Đột Phá (Killer Features)

- [x] **Mật Khẩu Phòng Emoji:** Thay vì nhập PIN 4 số, người chơi nhập 4 Emoji (vd: 🍎🍕👻👽) qua bàn phím custom. Rút ngắn thời gian giao tiếp, tạo không khí vui nhộn.
- [x] **Thẻ Game Thủ (Neon Gamer Cards):** Profile cá nhân dạng 3D/Neon. Có danh hiệu (vd "Vua Sút Phạt"). Slide-in lúc vào phòng và phóng to (Hero transition) khi thắng game.
- [ ] **Âm Thanh Không Gian (Spatial Audio):** Âm thanh (vd: tiếng bom đếm ngược) di chuyển từ loa máy này sang máy khác cùng với vật thể.
- [ ] **Chế Độ Khán Giả (Spectator):** Người chơi thứ 5 trở đi khi quét QR sẽ thành khán giả. Có thanh công cụ ném "Tương Cà / Bom Khói" che màn hình người đang chơi (có Cooldown).
- [x] **Bắn Cảm Xúc (Emotes):** Vuốt khay emote để ném 1 con gà khổng lồ bay thẳng sang màn hình đối phương.
- [x] **Đồng Bộ Rung (Haptic Sync):** Hai thiết bị rung chính xác cùng một mili-giây khi có sự kiện va chạm lớn.

---

## 4. 🎯 Trải Nghiệm Điều Hướng & Onboarding

- [x] **Safe Exit**:
  - [x] `WillPopScope` / `PopScope` chặn back button ở các luồng quan trọng (Màn hình Host khi đang chơi, màn hình Gamepad khi đang kết nối).
  - [x] Pop-up xác nhận rõ ràng: "Bạn có chắc muốn giải tán phòng?", "Thoát Controller?".
- [x] **Dynamic Controller Hints (Tay Cầm Động)**:
  - [x] Host gửi cấu hình `init_controller` (bao gồm `labels`, `highlight_button`) trước khi game bắt đầu (vd: Game Penalty chỉ cần nút A - Sút).
  - [x] Gamepad mờ các nút không dùng, thêm glow effect cho nút đang highlight.
- [x] **Điều hướng rảnh tay (TV Mode)**:
  - [x] Thêm thao tác vuốt (swipe down) / long-press trên Gamepad để gọi Menu Pause trên màn hình Host.
  - [x] **Navigation Gestures:** Chặn nút Back hệ thống (`PopScope`). Chơi game bằng thao tác vuốt xuống (Mở Menu Pause), Nhấn giữ (Dừng game), Chụm ngón tay (Thoát nhanh).

---

## 5. 🛠 Chiến Lược Kiểm Thử (QA Checklist)

Bắt buộc test thủ công bằng **thiết bị thật** (1 Android, 1 iOS cùng Wi-Fi) do Simulator không hỗ trợ mDNS chính xác.

- [ ] Host tạo phòng < 3s Client thấy mDNS.
- [ ] Client join, danh sách Avatar sync chính xác 2 bên.
- [ ] Cả hai vào màn hình Game (Flame) không lệch quá 0.5s.
- [x] Game Tap liên tục không bị crash do nghẽn MessagePack. (Đã nâng cấp `message_pack_dart`)
- [ ] Tắt WiFi Client, Host phải báo Disconnect sau 3-5s.
- [ ] iOS: Hộp thoại xin quyền Local Network hiển thị mượt mà.
