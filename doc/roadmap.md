# Party Game Hub — Feature Roadmap & Backlog

Tài liệu này lưu trữ tiến độ phát triển và các ý tưởng tính năng (Backlog) chưa được triển khai.

---

## 1. 🚀 Tiến Độ & Roadmap Ngắn Hạn

*Ghi chú: Các Phase 1 (Haptic, Rematch), Phase 2 (QR, Color), Phase 3 (Network) đã hoàn thành 95%.*

### Phase 4: Mở rộng Mini-Games (Sắp tới)
- [ ] **Khúc Côn Cầu Chéo (Cross Air Hockey):** Sân đấu chia đôi 2 thiết bị. Chuyển giao vật lý (Ownership) khi puck bay qua màn hình.
- [ ] **Đấu Xe Tăng (Tank Fight):** Cơ chế "Fog of War" che khuất tầm nhìn chéo.
- [ ] **Bắn Cung (Archer Duel):** Bắn cung vượt màn hình theo quỹ đạo Parabol.
- [ ] **Hải Chiến Không Gian (Battleship):** 2 màn hình riêng biệt, đặt tàu và phán đoán bắn.
- [ ] **Trốn Tìm Mê Cung (Maze Hide & Seek):** Đuổi bắt với tầm nhìn giới hạn, có dùng skill (Radar, Dash).
- [ ] **Rà Mìn Cảm Tử (Boomerang Hot Potato):** Ném bom hẹn giờ qua lại giữa 2 thiết bị.

### Phase 5: Advanced & Scaling
- [ ] **Hỗ trợ 3-4 Người Chơi:** Mở rộng `ConnectionRepository` và UI Lobby.
- [ ] **Chế Độ Giải Đấu Xoay Vòng (Roulette Cup):** Quay ngẫu nhiên mini-game, tính điểm Best of 5 với cúp pha lê.
- [ ] **Play Store CI/CD Deploy:** Đẩy AAB lên Internal Track (Cần setup Secret Keys).

---

## 2. 📺 Chế Độ Console-Controller (Asymmetric Mode)

Chế độ chia tách 1 thiết bị làm màn hình (Host) và các thiết bị khác làm tay cầm (Client).

*   **Host (TV/Tablet):** Chạy Flame Engine, xử lý đồ họa, tính toán vật lý (Source of Truth). Giao diện TV tối ưu cho Remote (10-foot UI), hiển thị Mã QR to và Sân Khấu Avatar Drop-in.
*   **Client (Phone):** Chỉ hiển thị **Tay Cầm Vạn Năng** (UI Flutter tĩnh cực nhẹ tiết kiệm pin). 
    *   *Bố cục:* Joystick trái, 4 nút (A, B, X, Y) phải.
    *   *Input:* Gửi tọa độ Joystick và trạng thái Nút qua UDP/TCP ở tần số 30-60Hz. Kèm theo dữ liệu Cảm Biến Nghiêng (Gyro) chạy ngầm.
    *   *Feedback:* Lắng nghe lệnh từ Host để rung (Haptic) hoặc chớp viền.

---

## 3. ✨ Tính Năng Đột Phá (Killer Features)

*   **Mật Khẩu Phòng Emoji:** Thay vì nhập PIN 4 số, người chơi nhập 4 Emoji (vd: 🍎🍕👻👽) qua bàn phím custom. Rút ngắn thời gian giao tiếp, tạo không khí vui nhộn.
*   **Thẻ Game Thủ (Neon Gamer Cards):** Profile cá nhân dạng 3D/Neon. Có danh hiệu (vd "Vua Sút Phạt"). Slide-in lúc vào phòng và phóng to (Hero transition) khi thắng game.
*   **Âm Thanh Không Gian (Spatial Audio):** Âm thanh (vd: tiếng bom đếm ngược) di chuyển từ loa máy này sang máy khác cùng với vật thể.
*   **Chế Độ Khán Giả (Spectator):** Người chơi thứ 5 trở đi khi quét QR sẽ thành khán giả. Có thanh công cụ ném "Tương Cà / Bom Khói" che màn hình người đang chơi (có Cooldown).
*   **Bắn Cảm Xúc (Emotes):** Vuốt khay emote để ném 1 con gà khổng lồ bay thẳng sang màn hình đối phương.
*   **Đồng Bộ Rung (Haptic Sync):** Hai thiết bị rung chính xác cùng một mili-giây khi có sự kiện va chạm lớn.

---

## 4. 🎯 Trải Nghiệm Điều Hướng & Onboarding

*   **First-Time Carousel:** Màn hình hướng dẫn vuốt ngang lúc mới cài App. Quan trọng nhất là yêu cầu "Bật chung WiFi/LAN".
*   **The 3-Second Rule (Luật 3 giây):** Không có trang text hướng dẫn dài dòng. Trước khi bắt đầu mini-game, hiện 1 màn hình mờ che Flame kèm Lottie animation (Minh họa thao tác) + Chữ to "TAP FAST!". Đếm 3-2-1 rồi chiến.
*   **Tay Cầm Động (Dynamic Controller Hints):** Nút nào không dùng sẽ bị mờ đi. Nút nào quan trọng sẽ chớp Glow. Host có thể gửi nhãn dán chữ (BẮN, NHẢY) đè lên tay cầm Client.
*   **Navigation Gestures:** Chặn nút Back hệ thống (`PopScope`). Chơi game bằng thao tác vuốt xuống (Mở Menu Pause), Nhấn giữ (Dừng game), Chụm ngón tay (Thoát nhanh).

---

## 5. 🛠 Chiến Lược Kiểm Thử (QA Checklist)

Bắt buộc test thủ công bằng **thiết bị thật** (1 Android, 1 iOS cùng Wi-Fi) do Simulator không hỗ trợ mDNS chính xác.

*   [ ] Host tạo phòng < 3s Client thấy mDNS.
*   [ ] Client join, danh sách Avatar sync chính xác 2 bên.
*   [ ] Cả hai vào màn hình Game (Flame) không lệch quá 0.5s.
*   [ ] Game Tap liên tục không bị crash do nghẽn MessagePack.
*   [ ] Tắt WiFi Client, Host phải báo Disconnect sau 3-5s.
*   [ ] iOS: Hộp thoại xin quyền Local Network hiển thị mượt mà.
