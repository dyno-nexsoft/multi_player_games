# Đặc Tả Mini-Games

Mỗi mini-game kế thừa `BaseMiniGame`. Nguyên tắc chung:
- **Host = authority**: tính physics, phát hiện thắng/thua
- **Client**: gửi input, nhận world_state để render
- Tọa độ dùng **giá trị chuẩn hóa** (0.0–1.0) để độc lập kích thước màn hình

---

## 1. Kéo Co Tốc Độ (`tug_of_war`) ✅ Đã có

**Gameplay:** Hai người tap liên tục để kéo sợi dây về phía mình. Dây lệch đủ xa → thắng.

**Network:**
```
Client → Host: { "action": "tap" }             (mỗi lần tap)
Host → All:   { "action": "rope_state",         (~10Hz)
                "rope_position": 0.15 }         // -1.0 đến 1.0
```

**Kết thúc:** `rope_position >= 0.9` hoặc `<= -0.9`

---

## 2. Húc Bóng Sinh Tồn (`sumo_bumper`) ✅ Đã có

**Gameplay:** Hai bóng trong đấu trường tròn trơn trượt. Húc đối thủ ra ngoài vòng để thắng. Đấu trường thu hẹp theo thời gian.

**Network:**
```
Client → Host: { "action": "input",             (joystick)
                 "angle": 2.14, "force": 0.8 }
Host → All:   { "action": "sync",               (~30Hz)
                "p1": [x, y], "p2": [x, y] }
```

**Kết thúc:** Một bóng ra khỏi `_arenaRadius`

---

## 3. Sút Phạt Đền (`penalty_shootout`) ✅ Đã có

**Gameplay:** Host là Shooter (vuốt để sút), Client là Keeper (trượt để cản). 3 lượt sút.

**Network:**
```
Host → Client: { "action": "shoot", "dx": -0.4 }  (bóng bay sang)
Client → Host: { "action": "slide", "x": 0.3 }    (tay thủ môn)
```

**Kết thúc:** Hết 3 lượt, tính theo số bàn thắng

---

## 4. Khúc Côn Cầu Chéo Màn Hình (`cross_air_hockey`) 🔲 Chưa có

**Điểm đặc biệt P2P:** Sân đấu chia đôi — mỗi nửa trên một màn hình. Khi puck vượt ranh giới → chuyển giao quyền tính physics (Physics Ownership Transfer).

**Network:**
```
// Khi puck sang màn hình đối thủ
Owner → Other: { "action": "puck_transfer",
                 "x": 0.42, "vx": 0.15, "vy": 0.85 }

// Paddle di chuyển (realtime)
Each → Each:  { "action": "paddle_move", "x": 0.6 }
```

**Tọa độ chéo màn hình:** Khi puck sang máy B: `x_in = 1.0 - x_out`, `vy` đảo dấu

---

## 5. Đấu Xe Tăng (`tank_fight`) 🔲 Chưa có

**Điểm đặc biệt P2P:** **Fog of War** — mỗi người chỉ nhìn thấy vùng xung quanh xe mình, không thể đọc vị trí đối thủ từ màn hình bên cạnh.

**Network:**
```
Client → Host: { "action": "move", "dx": 1, "dy": 0 }
               { "action": "shoot", "angle": 1.57 }
Host → All:   { "action": "sync",
                "tanks": [...], "bullets": [...],
                "visibility_mask": [...] }
```

---

## 6. Bắn Cung Chéo Màn Hình (`archer_duel`) 🔲 Chưa có

**Gameplay:** Hai cung thủ ở hai màn hình, bắn tên bay vượt màn hình sang đối phương theo quỹ đạo parabol.

**Network:**
```
Shooter → Other: { "action": "arrow_launch",
                   "vx": 0.4, "vy": -1.2, "type": "normal" }
// Thiết bị nhận tự mô phỏng quỹ đạo, tính va chạm, gửi kết quả về
Other → Shooter: { "action": "player_hit", "damage": 30 }
```

---

## Bảng Đánh Giá & Ưu Tiên

| Game | Độ trễ nhạy | Độ phức tạp | Vui lúc gặp mặt | Ưu tiên |
|---|---|---|---|---|
| Kéo Co | 🟢 Thấp | 🟢 Thấp | ⭐⭐⭐⭐ | ✅ Xong |
| Sút Phạt Đền | 🟡 TB | 🟡 TB | ⭐⭐⭐⭐⭐ | ✅ Xong |
| Húc Bóng | 🔴 Cao | 🟡 TB | ⭐⭐⭐⭐ | ✅ Xong |
| Khúc Côn Cầu | 🔴 Cao | 🔴 Cao | ⭐⭐⭐⭐⭐ | 🔲 Phase 2 |
| Xe Tăng | 🟡 TB | 🔴 Cao | ⭐⭐⭐⭐ | 🔲 Phase 3 |
| Bắn Cung | 🟡 TB | 🟡 TB | ⭐⭐⭐⭐ | 🔲 Phase 2 |
