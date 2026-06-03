# Kế Hoạch Cải Thiện Giao Diện (UI Improvement Plan)

Dựa trên phân tích các ứng dụng nổi tiếng như "2 Player Games: The Challenge" trên thị trường và kết hợp với định hướng thiết kế **Neon Dark / Glassmorphism** cùng cơ chế **P2P Chéo Thiết Bị** của dự án hiện tại, dưới đây là kế hoạch chi tiết để nâng cấp trải nghiệm người dùng (UX) và giao diện (UI) cho game.

## 1. Triết Lý Thiết Kế Cốt Lõi

*   **Tối giản để tập trung (Hyper-focus Minimalism):** Giống như các game 2 người chơi kinh điển, giao diện cần loại bỏ hoàn toàn các yếu tố gây nhiễu. Trong game chỉ giữ lại thông tin tối quan trọng (Điểm số, Thời gian, Thông báo).
*   **Trực quan & Cảm xúc (Visual & Emotional Feedback):** Giao diện Neon Dark cần phải "tỏa sáng". Mọi thao tác chạm, ghi điểm, chiến thắng đều phải có hiệu ứng hạt (particles), glow (phát sáng), hoặc haptic feedback (rung).
*   **Đồng nhất phong cách (Consistent Theme):** Sử dụng triệt để bộ màu `primary` (Tím Neon) và `secondary` (Hồng Neon) cho 2 người chơi để dễ phân biệt, kể cả khi chơi trên 2 thiết bị khác nhau.

## 2. Nâng Cấp Từng Màn Hình (Screen Upgrades)

### 2.1. Màn Hình Chính & Menu (Lobby / Game Selection)
Lấy cảm hứng từ cách chọn game cực nhanh của "2 Player Games: The Challenge":
*   **Grid Lựa Chọn Lớn:** Các mini-games không hiển thị dưới dạng list text nhàm chán mà là một **Grid các thẻ (Cards) lớn**.
*   **Card Design:** 
    *   Sử dụng hiệu ứng kính mờ (Glassmorphism) trên nền `surface` tối (`Color(0xFF1E1E2E)`).
    *   Mỗi card có một icon đại diện 3D hoặc Minimalist sáng màu (phát sáng neon khi được chọn).
*   **Nút "Quick Play / Random":** Cho phép hệ thống chọn ngẫu nhiên một game để cả 2 người bắt đầu ngay lập tức mà không cần suy nghĩ.

### 2.2. Trải Nghiệm Kết Nối (Connection Experience - P2P)
Vì đặc thù là chơi qua WiFi/Lan, trải nghiệm kết nối cần mượt như AirDrop:
*   **Radar Sweep Animation:** (Đã đề xuất trong `ui_ux_design.md`). Khi nhấn "Join", màn hình tối lại và hiện sóng radar phát sáng tìm phòng (Lottie animation).
*   **Avatars:** Khi 2 thiết bị kết nối thành công, có hiệu ứng 2 Avatar "va chạm" vào nhau trên màn hình để thể hiện đã ghép cặp xong.

### 2.3. Trong Trận Đấu (In-Game HUD)
*   **Khu vực điều khiển "Vô hình":** Ở các game như Air Hockey hay Sút Phạt Đền, chia đôi màn hình thành các vùng cảm ứng lớn, không viền (invisible touch zones), tránh các nút bấm giả lập cứng nhắc.
*   **Scoreboard:** Điểm số nổi bật bằng phông chữ đậm (GoogleFonts.nunito), phát sáng ở viền màn hình thay vì chiếm diện tích chính giữa. 
*   **Hiệu ứng viền màn hình (Edge Glow):** Khi có sự kiện quan trọng (ví dụ: máu yếu, sắp hết giờ, hoặc khi bóng sang phần sân của mình), viền màn hình thiết bị có thể nhấp nháy màu Đỏ hoặc Tím Neon để cảnh báo.

### 2.4. Màn Hình Kết Quả (Victory / Defeat Screen)
*   **Celebration:** Màn hình của người chiến thắng bùng nổ pháo hoa neon, chữ "VICTORY" mạ vàng/phát sáng. Màn hình người thua chuyển sang tone xám tối với chữ "DEFEAT".
*   **Rematch Nhanh:** Các nút CTA to bản (Rematch, Change Game) bo góc 16dp, có hiệu ứng rung nhẹ (pulse animation) kích thích người chơi bấm tiếp.

## 3. Trạng Thái Triển Khai

| Mục | Trạng thái | Ghi chú |
|---|---|---|
| `AppTheme` glow + glassmorphism | ✅ Xong | `glowShadow()`, `glassmorphism()`, thêm `tertiary` cyan, `inputDecorationTheme` |
| `neon_widgets.dart` component library | ✅ Xong | `GlassCard`, `NeonGameCard`, `PulseButton`, `FireworksOverlay`, `RadarWidget`, `NeonTitle` |
| Grid game selection + Quick Play | ✅ Xong | `room_screen.dart` — 4 cột NeonGameCard, nút Quick Play shuffle |
| Radar sweep animation | ✅ Xong | `discover_screen.dart` — thay `CircularProgressIndicator` bằng `RadarWidget` |
| Slide-in room cards | ✅ Xong | `_RoomCard` với `FadeTransition` + `SlideTransition` |
| Victory/Defeat celebration | ✅ Xong | `game_hub_screen.dart` — `FireworksOverlay` cho người thắng, banner VICTORY/DEFEAT |
| Pulse animation trên Rematch | ✅ Xong | `PulseButton` bao `ElevatedButton` với breathing glow |
| Neon rank tiles | ✅ Xong | `_RankTile` viền vàng #1, viền tím local player, crown 👑 |
| Player avatars neon glow | ✅ Xong | `_PlayerList` trong `room_screen.dart` dùng avatar tròn với `boxShadow` màu avatar |

**Còn lại / nâng cao:**
- Lottie animation chính thức (cần `lottie` package + file `.json` từ LottieFiles)
- Avatar "va chạm" animation khi 2 thiết bị kết nối thành công
- Edge glow in-game (viền đỏ khi sắp hết giờ) — cần `timeLeft` getter trên `BaseMiniGame`

---

## 4. Các Bước Triển Khai Ban Đầu (Reference)

1.  **Cập nhật `AppTheme`:** ✅ Bổ sung thêm các hiệu ứng Glow và Glassmorphism cho các Card trong `lib/core/theme/`.
2.  **Thiết kế Lottie Animations:** Tích hợp gói `lottie` vào dự án. Tìm và thêm các file `.json` cho hiệu ứng Radar và Pháo hoa.
3.  **Refactor LobbyScreen:** ✅ Chuyển List hiện tại sang dạng GridView với các Custom Game Cards.
4.  **Tích hợp Haptic Feedback:** ✅ Sử dụng `flutter/services.dart` (`HapticFeedback`) để thiết bị rung khi kết nối phòng thành công.

## 4. Cử Chỉ Điều Hướng (Navigation Gestures)

Thay vì sử dụng nút Back vật lý hoặc thanh điều hướng mặc định của hệ thống (dễ gây ấn nhầm và làm mất cảm giác "đắm chìm" vào game), chúng ta sẽ chặn nút Back và thay thế bằng các thao tác (Gestures) sau:

*   **Vuốt Xuống (Swipe Down):** Người chơi vuốt từ cạnh trên màn hình xuống (hoặc dùng 2 ngón tay vuốt xuống) để mở Menu Pause (Tiếp Tục / Thoát).
*   **Nhấn Giữ (Long Press):** Nhấn và giữ 1.5 giây trên màn hình sẽ xuất hiện một vòng tròn loading (Ripple/Glow). Khi đầy vòng, game tự động dừng lại.
*   **Chụm Ngón Tay (Pinch to Quit):** Dùng 2 ngón tay chụm lại, màn hình game sẽ thu nhỏ thành một card nhỏ và bay ngược về Menu chính.

*Kỹ thuật triển khai:* Sử dụng widget `PopScope(canPop: false)` bọc ngoài màn hình Game trong Flutter để vô hiệu hóa nút Back hệ thống, sau đó kết hợp `GestureDetector` để bắt các thao tác cử chỉ kể trên.
