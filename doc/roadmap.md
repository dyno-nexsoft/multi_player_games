# Party Game Hub — Full Feature Roadmap

## Tổng quan

| Phase       | Nội dung                                    | Độ khó         | Thời gian  |
| ----------- | ------------------------------------------- | -------------- | ---------- |
| **Phase 1** | Quick Wins: Haptic, Rematch, Best-of-N      | Thấp           | ~1 ngày    |
| **Phase 2** | UX Polish: Avatar/màu, QR join, Animation   | Trung bình     | ~2-3 ngày  |
| **Phase 3** | Network: Prediction, MessagePack, Reconnect | Cao            | ~4-5 ngày  |
| **Phase 4** | 4 Mini-games mới                            | Trung bình–Cao | ~8-10 ngày |
| **Phase 5** | 3-4 players + Play Store CI/CD              | Rất cao        | ~5-6 ngày  |

---

## Phase 1 — Quick Wins

### 1.1 Haptic Feedback

`HapticFeedback.lightImpact()` (Flutter built-in, không cần package) tại:

- TugOfWar → `_onLocalTap()`
- Sumo → `_resolveCollision()` khi va chạm
- Penalty → `onTapDown` khi sút
- AirHockey → `_checkPaddleCollision()`

### 1.2 Rematch Button

- Button "Chơi lại" trong `_ScoreboardScreen` (host only)
- `GameProvider._lastGameId` lưu game vừa chơi
- Host nhấn → `lobby.startGame(lastGameId)`, reset scores

### 1.3 Best-of-N Series

- Selector 1/3/5 trong `_GameSelector` của RoomScreen
- PacketType mới: `seriesConfig` broadcast khi host start
- `GameProvider` track `_wins` per player, kết thúc khi ai đạt `ceil(N/2)`
- Scoreboard hiển thị "Trận 2/3" + win count

---

## Phase 2 — UX Polish

### 2.1 Avatar + Color

- Thêm `color: int` vào `Player` freezed model
- Color picker 8 màu preset trong LobbyScreen
- `CircleAvatar(backgroundColor: Color(player.color))` trong PlayerList

### 2.2 QR Code Join

**Packages mới:** `qr_flutter ^4.x`, `mobile_scanner ^5.x`

- Host: hiển thị QR = `{"ip": "...", "port": 4567}` sau `startServer()`
- Client: nút "Quét QR" → camera scanner → `connectToAddress(ip, port)`
- `ConnectionRepository.connectToAddress()` bypass mDNS

### 2.3 Animated Transitions

- `Hero` trên game icon/title trong `_GameCard` → `GameHubScreen`
- `CustomTransitionPage` với `FadeTransition` trong go_router
- `AnimatedScale` trên lobby action buttons

---

## Phase 3 — Network & Reliability

### 3.1 Client-Side Prediction (TugOfWar)

- Client apply tap locally ngay lập tức (`_ropePosition -= _tapPower`)
- Blend về server value khi nhận 'state': `lerpDouble(local, server, 0.3)`

### 3.2 MessagePack

**Package mới:** `messagepack ^0.3.x`

- `GamePacket.toWire()` → `Uint8List` (binary, không phải JSON string)
- 4-byte length prefix framing thay vì newline-delimited
- Giảm ~60% packet size → quan trọng với AirHockey paddle sync 20Hz

### 3.3 Reconnect Logic

- `ConnectionRepository.onDisconnect` callback khi host ngắt kết nối
- `LobbyProvider` retry 3 lần với backoff (1s, 2s, 4s)
- `LobbyState.reconnecting` mới
- UI overlay "Đang kết nối lại..."

---

## Phase 4 — New Mini-Games

### 4.1 Reaction Tap _(~1 ngày)_

Pure Flutter (không cần Flame). 5 vòng.

- Host random delay → gửi `flash` → cả 2 tap → host đo thời gian
- Ai tap nhanh hơn thắng vòng. Nhanh nhất overall thắng match.
- Files: `reaction_tap/reaction_tap_game.dart`

### 4.2 Minesweeper Race _(~1.5 ngày)_

8×8 board, 10 mìn. Host authoritative. 60 giây.

- Cả 2 tap ô cùng board → host validate → broadcast `reveal`
- Chạm mìn = -3 điểm. Reveal nhiều ô hơn thắng.
- Files: `minesweeper/minesweeper_game.dart`, `minesweeper/components/mine_grid.dart`

### 4.3 Billiards Pool _(~3 ngày)_

Turn-based. Flame physics. 8-ball hoặc 9-ball.

- Drag cue → host tính physics → gửi toàn bộ ball positions sau shot
- Files: `billiards/billiards_game.dart`, `billiards/components/`, `billiards/physics/`

### 4.4 Draw & Guess _(~3 ngày)_

Flutter widget (không phải Flame). Luân phiên vẽ/đoán.

- Người vẽ dùng `GestureDetector + CustomPainter` → stream stroke points 30Hz
- Người đoán gõ text → host validate → broadcast kết quả
- 5 từ từ l10n word list. Đoán đúng = +10, vẽ được đoán = +5
- Files: `draw_guess/draw_guess_game.dart`, `draw_guess/widgets/drawing_canvas.dart`

---

## Phase 5 — Advanced

### 5.1 3-4 Player Support _(~4 ngày)_

- `Player` thêm `playerIndex: int`
- ConnectionRepository đã là List `_clients` — chỉ cần bỏ giới hạn logic
- Games hỗ trợ 3-4: Reaction Tap, Sumo, Minesweeper
- Games giữ 2 người: Tug of War, Billiards
- `MiniGameMetadata.minPlayers/maxPlayers` đã có → dùng để filter trong RoomScreen

### 5.2 Play Store CI/CD _(~half day)_

- Build AAB: `flutter build appbundle --release`
- `r0adkll/upload-google-play@v1` action
- GitHub Secrets: `KEYSTORE_FILE`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`, `GOOGLE_PLAY_JSON_KEY`
- Upload lên **internal track**, promote thủ công lên production

---

## New Packages

| Package               | Dùng cho                    | Phase |
| --------------------- | --------------------------- | ----- |
| `qr_flutter ^4.1.0`   | Hiển thị QR code            | 2     |
| `mobile_scanner ^5.x` | Scan QR camera              | 2     |
| `messagepack ^0.3.x`  | Binary packet serialization | 3     |

---

## Key Files Affected

| File                         | Changes                                       |
| ---------------------------- | --------------------------------------------- |
| `player.dart`                | + color, playerIndex fields                   |
| `game_packet.dart`           | + PacketType constants, MessagePack           |
| `connection_repository.dart` | + connectToAddress, reconnect, binary framing |
| `lobby_provider.dart`        | + reconnecting state, series config           |
| `game_provider.dart`         | + lastGameId, series wins tracking            |
| `mini_game_registry.dart`    | + 4 new games                                 |
| `room_screen.dart`           | + series selector, avatar display             |
| `game_hub_screen.dart`       | + rematch button, Draw&Guess embed            |
| `release_apk.yml`            | + AAB build, Play Store deploy job            |

---

## Thứ tự thực hiện khuyến nghị

```
Phase 1 → Phase 2 → Phase 3.1 (Prediction) → Phase 4.1 (ReactionTap)
                  → Phase 3.2 (MessagePack) → Phase 4.4 (Draw&Guess)
                  → Phase 3.3 (Reconnect)
                  → Phase 4.2 (Minesweeper) → Phase 4.3 (Billiards)
                  → Phase 5.1 (3-4 players)
                  → Phase 5.2 (CI/CD) ← có thể làm bất cứ lúc nào
```
