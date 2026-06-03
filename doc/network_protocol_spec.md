# Đặc Tả Giao Thức Mạng

Tất cả giao tiếp giữa Host và Client đều qua **TCP Socket**, mỗi gói tin là một chuỗi JSON kết thúc bằng `\n` (line-framing).

---

## Cấu Trúc Gói Tin Cơ Bản (`GamePacket`)

```json
{
  "type": "game_data",
  "game_id": "tug_of_war",
  "sender_id": "device_abc123",
  "timestamp": 1698374829301,
  "payload": { }
}
```

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| `type` | ✅ | Loại gói tin (xem bảng dưới) |
| `game_id` | Chỉ khi in-game | Mini-game đang chạy |
| `sender_id` | ✅ | ID thiết bị gửi |
| `timestamp` | ✅ | Unix epoch ms |
| `payload` | ✅ | Dữ liệu tùy theo `type` |

**Hằng số `type`** (định nghĩa trong `PacketType`):

| Constant | Hướng | Ý nghĩa |
|---|---|---|
| `join` | Client→Host | Client xin vào phòng |
| `lobby_sync` | Host→All | Cập nhật danh sách player |
| `start_game` | Host→All | Bắt đầu mini-game |
| `end_game` | Host→All | Kết thúc mini-game + điểm |
| `game_data` | Cả hai | Dữ liệu trong game (input / world_state) |
| `heartbeat` | Cả hai | Keep-alive (1s/lần) |
| `system_pause` | Cả hai | App bị pause (điện thoại) |

---

## Lobby Packets

### `join` — Client→Host
```json
{
  "type": "join",
  "sender_id": "client_xyz",
  "payload": { "name": "Tom" }
}
```

### `lobby_sync` — Host→All (broadcast)
```json
{
  "type": "lobby_sync",
  "payload": {
    "players": [
      { "id": "host_id", "name": "Jerry", "is_host": true, "score": 0 },
      { "id": "client_xyz", "name": "Tom", "is_host": false, "score": 0 }
    ]
  }
}
```

### `start_game` — Host→All
```json
{
  "type": "start_game",
  "payload": { "game_id": "tug_of_war" }
}
```

### `end_game` — Host→All
```json
{
  "type": "end_game",
  "payload": {
    "scores": { "host_id": 100, "client_xyz": 0 }
  }
}
```

---

## In-Game Packets (`game_data`)

Trường `game_id` phải khớp với mini-game đang chạy để `GameNetworkRouter` định tuyến đúng.

### Tug of War
```json
// Client→Host: mỗi lần tap
{ "type": "game_data", "game_id": "tug_of_war",
  "payload": { "action": "tap" } }

// Host→All: ~10Hz
{ "type": "game_data", "game_id": "tug_of_war",
  "payload": { "action": "rope_state", "rope_position": 0.15 } }
```

### Sumo Bumper
```json
// Client→Host: joystick input
{ "type": "game_data", "game_id": "sumo_bumper",
  "payload": { "action": "input", "angle": 2.14, "force": 0.8 } }

// Host→All: ~30Hz
{ "type": "game_data", "game_id": "sumo_bumper",
  "payload": { "action": "sync", "p1": [0.4, 0.5], "p2": [0.6, 0.5] } }
```

### Penalty Shootout
```json
// Host (Shooter)→Client
{ "type": "game_data", "game_id": "penalty_shootout",
  "payload": { "action": "shoot", "dx": -0.4 } }

// Client (Keeper) slide
{ "type": "game_data", "game_id": "penalty_shootout",
  "payload": { "action": "slide", "x": 0.3 } }
```

---

## Heartbeat & Disconnect Detection

- Mỗi bên gửi `heartbeat` 1 lần/giây
- Nếu 3 giây không nhận được → **pause game**, hiện "Đang kết nối lại..."
- Nếu 10 giây không kết nối lại → **hủy trận**, về RoomScreen
- Khi app bị pause (`AppLifecycleState.paused`) → gửi `system_pause` ngay lập tức
