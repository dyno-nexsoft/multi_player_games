# Đề Xuất Phát Triển: Game Mới & Tính Năng Tương Tác

Tài liệu này lưu trữ các thiết kế ý tưởng (Concept Design) cho những mini-games và tính năng hệ thống mới, tập trung khai thác điểm mạnh lớn nhất của game: **Tính năng ẩn thông tin nhờ kiến trúc P2P chéo màn hình**.

---

## 1. Mini-Games Mới (Hidden Information Focus)

### 1.1 Hải Chiến Không Gian (Neon Battleship)
Trò chơi đòi hỏi khả năng phán đoán, khai thác triệt để việc mỗi người có một màn hình riêng.

*   **Độ phức tạp:** Trung bình (🟡)
*   **Độ trễ (Latency):** Cực thấp (🟢)
*   **Gameplay Flow:**
    1.  **Preparation Phase:** Mỗi người chơi tự do kéo thả 3 con tàu (tàu 2 ô, 3 ô, 4 ô) vào lưới grid 8x8 trên màn hình của mình. Đối phương không thể nhìn thấy bước này.
    2.  **Attack Phase:** Luân phiên mỗi người chọn 1 ô trên lưới radar để "bắn".
    3.  **Resolution:** Host nhận tọa độ bắn, so sánh với vị trí tàu của đối phương và phản hồi kết quả (Hit/Miss/Sunk) về cho cả hai.
*   **Network Messages:** `place_ships`, `attack_coord`, `attack_result`.

### 1.2 Trốn Tìm Mê Cung (Maze Hide & Seek)
Trải nghiệm truy đuổi nghẹt thở với "Fog of War" trên P2P.

*   **Độ phức tạp:** Cao (🔴)
*   **Độ trễ:** Trung bình (🟡)
*   **Gameplay Flow:**
    1.  **Role Assignment:** Random một người là Hunter (đỏ), một người là Runner (xanh).
    2.  **Visibility:** Màn hình tối đen, chỉ thấy được một vùng sáng xung quanh nhân vật của mình.
    3.  **Objective:** Runner phải nhặt đủ 10 ngôi sao rải rác. Hunter phải chạm vào Runner.
    4.  **Skills:** Hunter có nút "Radar", khi bấm sẽ nháy sáng vị trí của Runner trên map trong 0.5s nhưng phải chờ cooldown 10s. Runner có nút "Dash" để chạy nhanh trong 1s.
*   **Network Messages:** Vị trí realtime được gửi về Host, Host chỉ gửi lại tọa độ đối phương nếu nằm trong tầm nhìn (Visibility Radius) hoặc khi dùng Radar.

### 1.3 Rà Mìn Cảm Tử (Boomerang Hot Potato)
Trò chơi thử thách phản xạ và phối hợp cross-screen vật lý ảo.

*   **Độ phức tạp:** Trung bình (🟡)
*   **Độ trễ:** Trung bình (🟡)
*   **Gameplay Flow:**
    1.  Khởi đầu với một quả bom hẹn giờ ngẫu nhiên (ví dụ 15 giây).
    2.  Bom xuất hiện ở màn hình Player 1. Player 1 phải vuốt (swipe) thật nhanh để "ném" nó bay vượt màn hình sang Player 2.
    3.  Trước khi ném, quả bom đôi khi bị "khóa", yêu cầu người cầm bom phải bấm 3 nốt nhạc theo đúng thứ tự màu để mở khóa rồi mới được ném.
    4.  Hết thời gian, bom nổ ở màn hình ai thì người đó thua.
*   **Network Messages:** Tương tự `cross_air_hockey`, sử dụng ownership transfer khi vật thể bay qua ranh giới màn hình.

---

## 2. Tính Năng Hệ Thống (Meta Features)

### 2.1 Bắn Cảm Xúc (Quick Emotes/Taunts)
Để tăng tính tương tác giữa hai người ngồi đối diện nhau.
*   **Thiết kế:** Một khay emote ẩn bên mép màn hình. Vuốt ra để chọn.
*   **Hiệu ứng:** Khi Player 1 chọn icon "Gà", một con gà khổng lồ có hiệu ứng Glow sẽ bay thẳng từ phía dưới màn hình của Player 2 lên giữa màn hình, kèm theo âm thanh.
*   **Triển khai:** Thêm một packet `EmoteAction` xử lý độc lập khỏi GamePhysics. Dùng overlay của Flame hoặc Flutter Overlay để render đè lên mọi game.

### 2.2 Đồng Bộ Rung (Haptic Sync)
Tạo ra cầu nối vật lý giữa 2 thiết bị.
*   **Concept:** Trong các trò như Kéo Co (khi dây đứt) hoặc Khúc Côn Cầu (khi bóng đập vào mép sân giữa 2 thiết bị), cả hai thiết bị sẽ phát lệnh rung `HapticFeedback.heavyImpact()` tại cùng một thời điểm.
*   **Triển khai:** Dùng NTP (Network Time Protocol) nội bộ giữa Host và Client để đồng bộ hóa đồng hồ, hoặc dùng timestamp truyền trong packet để đảm bảo thời điểm rung lệch nhau không quá 10ms.

### 2.3 Chế Độ Giải Đấu Xoay Vòng (Roulette Cup)
Tính năng giữ chân người chơi (Retention) cực tốt.
*   **Flow:** Host tạo phòng, không chọn lẻ game mà chọn "Roulette Cup (Best of 5)".
*   **Vòng quay:** Game hiện một vòng quay ngẫu nhiên chọn ra mini-game tiếp theo.
*   **Tích điểm:** Có màn hình Leaderboard tổng sau mỗi ván, sử dụng thiết kế cúp pha lê.
