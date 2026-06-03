# Đặc Tả Giao Diện TV (Host Mode UI/UX Spec)

Tài liệu này xác định các quy tắc thiết kế dành riêng cho thiết bị đóng vai trò là Host (Màn hình chính) trong chế độ Console Mode, đặc biệt là khi chạy trên Android TV hoặc Tablet cắm HDMI xuất ra màn hình lớn.

---

## 1. Nguyên Tắc 10-foot UI & Điều Khiển Remote

Màn hình TV được thiết kế để nhìn từ khoảng cách 3 mét. Người chơi không dùng cảm ứng mà dùng Remote (D-Pad).

### 1.1 Focus Node & Navigation
*   Toàn bộ màn hình Host **KHÔNG** sử dụng Touch controls (Joystick, Nút bắn ảo).
*   Các nút bấm menu (như Quick Play, Settings) phải hỗ trợ Focus bằng bàn phím/remote. 
*   **Hiệu ứng Focus:** Khi một nút được chọn, nó phải phóng to `1.15x` và viền Glow sáng lên ít nhất 16dp.

### 1.2 Typography & Kích thước
*   **Font Size:** Font chữ nhỏ nhất được phép hiển thị là `24sp`. Tiêu đề phòng (Room Code) phải từ `64sp` đến `96sp`.
*   **Safe Area:** Tránh đặt các yếu tố quan trọng (HUD, Điểm số) sát mép màn hình vì một số TV cũ có hiện tượng Overscan (cắt viền). Để lề ít nhất `5%` mỗi cạnh.

---

## 2. Giao Diện TV Lobby (Sảnh Chờ Màn Hình Lớn)

Sảnh chờ là khu vực tạo hiệu ứng "Wow" cho nhóm bạn bè khi họ chuẩn bị tham gia chơi.

### 2.1 Bố Cục (Layout)
Màn hình chia làm 2 phần chính:
*   **Bên Trái (40%): Cổng Kết Nối**
    *   Mã QR Code siêu lớn để quét.
    *   Phía dưới là "Mật Khẩu Emoji" (Ví dụ: 🍕 👽 🔥 👻) siêu to để những người không thích quét QR có thể tự nhập trên điện thoại.
*   **Bên Phải (60%): Sân Khấu (The Stage)**
    *   Khu vực hiển thị những người chơi đã vào phòng. Ban đầu trống rỗng.

### 2.2 Hiệu Ứng Tham Gia (Drop-in Animation)
*   Khi một điện thoại (Client) kết nối thành công, Avatar Neon của người đó sẽ xuất hiện trên "Sân Khấu".
*   **Animation:** Avatar "rơi tự do" từ cạnh trên của TV xuống, va chạm với sàn nhảy tạo ra hiệu ứng tia lửa neon (Particle effect).
*   Sân khấu tự động chia đều khoảng cách dựa trên số lượng người chơi (tối đa 4 người xếp thành hàng ngang).

---

## 3. In-Game HUD (Giao Diện Trận Đấu)

Khi trận đấu bắt đầu, UI sẽ rút gọn tối đa để nhường toàn bộ diện tích cho Game Canvas (Flame).

### 3.1 Bố cục Điểm số (Score HUD)
*   Avatar và điểm số của từng người được "đính" (snap) vào 4 góc màn hình tương ứng với màu sắc của tay cầm mà người đó đang giữ. 
*   (VD: Player Đỏ ở góc Trái Trên, Player Xanh ở góc Trái Dưới).

### 3.2 Visual Feedback (Phản hồi trực quan)
*   Mặc dù Host không nhận thao tác chạm trực tiếp, nhưng mỗi khi người chơi nhấn nút A/B trên điện thoại của họ, Avatar của họ trên góc TV sẽ nháy sáng nhẹ. Điều này giúp mọi người biết tay cầm của mình vẫn đang kết nối tốt và không bị lag.

---

## 4. Tự Động Kích Hoạt (Auto-Detect TV Mode)

Hệ thống sẽ dùng `MediaQuery` để tự động vào thẳng giao diện TV nếu thỏa mãn các điều kiện:
*   Màn hình thiết bị đang ở hướng ngang (Landscape).
*   Kích thước bề ngang màn hình `> 900dp`.
*   *(Tùy chọn)* Dùng plugin `device_info_plus` để kiểm tra cờ `isAndroidTV`.
