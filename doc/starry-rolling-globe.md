# Party Game Hub — Full Feature Roadmap

## Context
Party Game Hub là local multiplayer game trên Android, kết nối qua WiFi LAN.
Hiện có 4 mini-games, 2 người chơi, giao tiếp TCP JSON.
User muốn mở rộng toàn diện: thêm 4 game mới, cải thiện UX, nâng cấp network, hỗ trợ 3-4 người, CI/CD Play Store.

## Trạng Thái Thực Hiện

| Phase | Tính năng | Trạng thái |
|---|---|---|
| 1.1 | Haptic Feedback | ✅ Xong |
| 1.2 | Rematch Button | ✅ Xong |
| 1.3 | Best-of-N Series | ✅ Xong |
| 2.1 | Avatar + Color | ✅ Xong |
| 2.2 | QR Code Join | ✅ Xong |
| 2.3 | Animated Transitions | ✅ Xong |
| 3.1 | Client-Side Prediction (TugOfWar) | ✅ Xong |
| 3.2 | MessagePack binary encoding | ✅ Xong — custom decoder inline, ~60% nhỏ hơn JSON |
| 3.3 | Reconnect Logic | ✅ Xong |
| 4.1 | Reaction Tap | ✅ Xong |
| 4.2 | Minesweeper Race | ✅ Xong |
| 4.3 | Billiards Pool | ✅ Xong |
| 4.4 | Draw & Guess | ✅ Xong — Flutter overlay, 30 Hz stroke streaming |
| 5.1 | 3-4 Player Support (playerIndex) | ✅ Xong — `playerIndex` thêm vào Player model |
| 5.2 | Play Store CI/CD | ✅ Xong — AAB build + `r0adkll/upload-google-play` internal track |

> **Cần thiết lập Secrets trước khi deploy Play Store:**
> `KEYSTORE_FILE` (base64), `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`, `GOOGLE_PLAY_JSON_KEY`

---

## Phased Roadmap

### Phase 1 — Quick Wins (3 tính năng, ~1 ngày)

#### 1.1 Haptic Feedback
- **Files:** tug_of_war_game.dart, sumo_game.dart, penalty_game.dart, air_hockey_game.dart
- **Cách làm:** `HapticFeedback.lightImpact()` (flutter/services.dart, không cần package) tại:
  - TugOfWar: trong `_onLocalTap()` (cùng chỗ AppAudio.playTap)
  - Sumo: trong `_resolveCollision()` khi relVel < 0 (cùng chỗ AppAudio.playBump)
  - Penalty: trong `onTapDown` khi host sút
  - AirHockey: trong `_checkPaddleCollision` khi va chạm
- **No package needed** — Flutter built-in

#### 1.2 Rematch Button
- **Files:** game_hub_screen.dart, game_provider.dart, lobby_provider.dart
- **Cách làm:**
  - Thêm button "Chơi lại" trong `_ScoreboardScreen` (chỉ hiển thị với host)
  - Host nhấn → gọi `lobby.startGame(lastGameId)` (lưu gameId trong GameProvider)
  - Thêm field `_lastGameId` vào GameProvider
  - Reset `_totalScores` nếu không phải series mode

#### 1.3 Best-of-N Series
- **Files:** room_screen.dart, game_provider.dart, lobby_provider.dart, game_packet.dart
- **Cách làm:**
  - Thêm `seriesLength` (1/3/5) selector trong `_GameSelector` của RoomScreen
  - Thêm PacketType `seriesConfig` để broadcast config khi host bắt đầu
  - GameProvider: track `_wins` per player, kết thúc series khi ai đạt `ceil(N/2)` thắng
  - Scoreboard hiển thị "Trận 2/3" và win count

---

### Phase 2 — UX Polish (3 tính năng, ~2-3 ngày)

#### 2.1 Avatar + Color
- **Files:** player.dart, lobby_screen.dart, room_screen.dart, discover_screen.dart
- **Cách làm:**
  - Thêm `color: int` (hex) vào `Player` freezed model → chạy build_runner
  - Thêm `ColorPicker` widget đơn giản (6-8 màu preset) trong LobbyScreen
  - Truyền color khi gửi PacketType.join
  - `_PlayerList` trong RoomScreen dùng `CircleAvatar(backgroundColor: Color(player.color))`

#### 2.2 QR Code Join
- **New packages:** `qr_flutter: ^4.x`, `mobile_scanner: ^5.x`
- **Files:** lobby_screen.dart, room_screen.dart, connection_repository.dart
- **Cách làm:**
  - Host: sau khi `startServer()`, hiển thị QR widget = JSON `{"ip": "...", "port": 4567}`
  - Client: thay nút "Tìm phòng" có thêm "Quét QR" → mở camera scanner
  - ConnectionRepository: thêm `connectToAddress(String ip, int port)` method (bypass mDNS)
  - QR encode/decode bằng `jsonEncode`/`jsonDecode`

#### 2.3 Animated Transitions
- **Files:** room_screen.dart, game_hub_screen.dart, router.dart
- **Cách làm:**
  - Wrap icon + title trong `_GameCard` bằng `Hero(tag: 'game_${game.id}')`
  - `GameHubScreen` matching `Hero(tag: 'game_${gameId}')` wrapping game title
  - go_router custom transition: `CustomTransitionPage` với `FadeTransition`
  - `_ActionButton` trong lobby: thêm `AnimatedScale` on press

---

### Phase 3 — Network & Reliability (~4-5 ngày)

#### 3.1 Client-Side Prediction (TugOfWar)
- **File:** tug_of_war_game.dart
- **Cách làm:**
  - Client: khi tap, lập tức apply `_ropePosition -= _tapPower` locally (hiển thị ngay)
  - Khi nhận 'state' packet từ host, blend về giá trị host bằng lerp: `_ropePosition = lerpDouble(_ropePosition, serverPos, 0.3)`
  - Cảm giác responsive trong khi vẫn host-authoritative

#### 3.2 MessagePack
- **New package:** `messagepack: ^0.3.x`
- **Files:** game_packet.dart, connection_repository.dart, network_service.dart
- **Cách làm:**
  - `GamePacket.toWire()` → `Uint8List` thay vì String (dùng messagepack packer)
  - Thêm 4-byte length prefix trước mỗi packet (framing)
  - `_listenSocket` đọc binary với length-prefix thay vì newline-delimited
  - `GamePacket.tryParse(Uint8List)` thay vì `tryParse(String)`
  - Giảm ~60% kích thước packet, quan trọng nhất cho AirHockey (paddle 20Hz)

#### 3.3 Reconnect Logic
- **Files:** connection_repository.dart, lobby_provider.dart, lobby_screen.dart
- **Cách làm:**
  - ConnectionRepository: thêm `onDisconnect` callback, gọi khi `onDone` trigger trên client socket
  - LobbyProvider: xử lý `onDisconnect` → thử `connectToService` lại tối đa 3 lần với exponential backoff (1s, 2s, 4s)
  - Thêm enum state `LobbyState.reconnecting`
  - UI: hiển thị "Đang kết nối lại..." overlay khi state == reconnecting

---

### Phase 4 — New Mini-Games (~8-10 ngày)

#### 4.1 Reaction Tap *(~1 ngày)*
- **Architecture:** Turn-based via host. Đơn giản nhất, không cần Flame — pure Flutter StatefulWidget.
- **Gameplay:** 5 vòng. Host chờ random delay (2-5s), gửi 'flash' packet. Cả 2 tap màn hình. Host đo thời gian từ lúc gửi 'flash' đến lúc nhận 'tap'. Ai nhanh hơn thắng vòng đó.
- **Files cần tạo:**
  - `lib/features/game/mini_games/reaction_tap/reaction_tap_game.dart` — BaseMiniGame, no Flame needed (dùng FlameGame vẫn OK cho interface)
- **Network packets:** `flash` (host→client, kèm `round`), `tap` (client→host, kèm `client_time_ms`), `round_result` (host→client, kèm winner + times), `game_over`
- **Registry:** thêm `reaction_tap` vào MiniGameRegistry
- **Assets:** thêm `assets/icons/reaction_tap.svg`

#### 4.2 Minesweeper Race *(~1.5 ngày)*
- **Architecture:** Host-authoritative. Cả 2 thấy cùng board (8×8, 10 mìn). Ai reveal ô trống nhiều hơn thắng.
- **Gameplay:** Tap ô → reveal (số/mìn). Chạm mìn = mất 3 điểm. Reveal hết ô an toàn trong 60s = thắng.
- **Files cần tạo:**
  - `lib/features/game/mini_games/minesweeper/minesweeper_game.dart`
  - `lib/features/game/mini_games/minesweeper/components/mine_grid.dart`
- **State:** Host generate board, broadcast `board_init` packet kèm mine positions. Cả 2 tap → host validate → broadcast `reveal` packet.
- **Render:** GridView Flutter hoặc Flame TileComponent

#### 4.3 Billiards Pool *(~3 ngày)*
- **Architecture:** Turn-based, host authority. Flame physics.
- **Gameplay:** 8-ball pool đơn giản (hoặc 9-ball). Drag cue → release → host tính physics → sync.
- **Files cần tạo:**
  - `lib/features/game/mini_games/billiards/billiards_game.dart`
  - `lib/features/game/mini_games/billiards/components/ball_component.dart`
  - `lib/features/game/mini_games/billiards/components/cue_component.dart`
  - `lib/features/game/mini_games/billiards/physics/ball_physics.dart`
- **Flame features:** `PositionComponent`, `DragCallbacks`, custom collision via `CollisionCallbacks`
- **Sync:** Host gửi toàn bộ ball positions sau mỗi shot khi chúng dừng lại (không cần realtime)

#### 4.4 Draw & Guess *(~3 ngày)*
- **Architecture:** Turn-based. Người vẽ (host hoặc client lần lượt) dùng `GestureDetector + CustomPainter`. Người kia gửi text guess.
- **Gameplay:** 5 từ (lấy từ l10n word list). Vẽ 60s. Đoán đúng = +10 điểm người đoán + +5 người vẽ.
- **Files cần tạo:**
  - `lib/features/game/mini_games/draw_guess/draw_guess_game.dart`
  - `lib/features/game/mini_games/draw_guess/widgets/drawing_canvas.dart` (Flutter widget, không phải Flame)
  - `lib/features/game/mini_games/draw_guess/widgets/guess_input.dart`
- **Network:** Stream stroke data: `stroke_point` packet kèm `{x, y, pressure, is_new_stroke: bool}` — gửi mỗi `onPanUpdate` event (throttle 30Hz)
- **Words:** Thêm `drawGuessWords` list vào arb files (20-30 từ đơn giản VI/EN)
- **Quan trọng:** Game này là Flutter widget lồng trong `GameHubScreen` thay vì FlameGame thuần — cần `GameWidget` wrapper hoặc route trực tiếp

---

### Phase 5 — Advanced (~5-6 ngày)

#### 5.1 3-4 Player Support *(~4 ngày)*
- **Scope:** Lớn nhất. Ảnh hưởng lobby, network, tất cả games.
- **Files chính:** connection_repository.dart, lobby_provider.dart, all mini-games
- **Cách làm:**
  - ConnectionRepository: `_clients` đã là List → chỉ cần bỏ giới hạn 2 (không có hard limit hiện tại)
  - `Player.isHost` → thêm `playerIndex: int` để xác định vai trò trong game
  - Games cần 3-4 player mode:
    - Reaction Tap: 3-4 người tap, ai nhanh nhất thắng (dễ)
    - Sumo: 3 hoặc 4 bumpers trong arena (khó hơn, cần multi-ball physics)
    - Minesweeper: 3-4 người cùng reveal (dễ, score-based)
  - Tug of War và Billiards ở lại 2 người
  - UI: `minPlayers`/`maxPlayers` trong MiniGameMetadata đã có → dùng để filter

#### 5.2 Play Store CI/CD *(~half day)*
- **File:** `.github/workflows/release_apk.yml`
- **Cách làm:**
  - Thêm job `deploy` sau `release`
  - Package: `r0adkll/upload-google-play@v1`
  - Build AAB thay vì APK: `flutter build appbundle --release`
  - Cần GitHub Secrets: `KEYSTORE_FILE`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`, `GOOGLE_PLAY_JSON_KEY`
  - Upload lên internal track trước, promote thủ công

---

## Dependency Map

```
Phase 1 (Quick Wins)
  └── Phase 2 (UX Polish)
        └── Phase 3 (Network)
              ├── 3.1 Prediction (standalone)
              ├── 3.2 MessagePack (trước khi có nhiều game mới)
              └── 3.3 Reconnect (standalone)
Phase 4 (Mini-games) — có thể song song với Phase 3
  ├── 4.1 Reaction Tap (không cần gì trước)
  ├── 4.2 Minesweeper (không cần gì trước)
  ├── 4.3 Billiards (không cần gì trước)
  └── 4.4 Draw & Guess (tốt hơn sau MessagePack vì nhiều packets)
Phase 5 (Advanced) — phải sau tất cả
  ├── 3-4 Players (sau tất cả Phase 4)
  └── CI/CD (bất cứ lúc nào)
```

---

## Files Mới Cần Tạo

```
lib/
  features/game/mini_games/
    reaction_tap/
      reaction_tap_game.dart
    minesweeper/
      minesweeper_game.dart
      components/mine_grid.dart
    billiards/
      billiards_game.dart
      components/ball_component.dart
      components/cue_component.dart
      physics/ball_physics.dart
    draw_guess/
      draw_guess_game.dart
      widgets/drawing_canvas.dart
      widgets/guess_input.dart
assets/
  icons/
    reaction_tap.svg
    minesweeper.svg
    billiards.svg
    draw_guess.svg
doc/
  roadmap.md  ← export plan này ra đây
```

---

## New Packages Cần Thêm

| Package | Version | Dùng cho |
|---|---|---|
| `qr_flutter` | ^4.1.0 | Hiển thị QR code |
| `mobile_scanner` | ^5.x | Scan QR code |
| `messagepack` | ^0.3.x | Binary serialization |

---

## Files Bị Ảnh Hưởng Nhiều Nhất

- `game_packet.dart` — MessagePack, PacketType mới
- `connection_repository.dart` — Reconnect, QR connect, MessagePack framing
- `lobby_provider.dart` — Reconnect state, 3-4 players
- `mini_game_registry.dart` — 4 game mới
- `player.dart` — color field, playerIndex
- `game_provider.dart` — Series logic, lastGameId
- `game_hub_screen.dart` — Rematch button, Draw&Guess widget embedding
- `room_screen.dart` — Series selector, Color/avatar display
- `release_apk.yml` — AAB + Play Store deploy

---

## Verification Per Phase

- **Phase 1:** Chạy app trên 2 thiết bị, kiểm tra rung khi tap, nút rematch hoạt động, best-of-3 đếm đúng wins
- **Phase 2:** Scan QR từ device 2 vào room của device 1; màu avatar hiển thị đúng trong lobby
- **Phase 3:** Dùng Wireshark/network monitor kiểm tra packet size giảm sau MessagePack; ngắt WiFi rồi kết nối lại trong game
- **Phase 4:** Test từng game trên 2 device; Draw&Guess kiểm tra stroke latency < 100ms
- **Phase 5:** Test 3 device cùng phòng; APK artifact build thành công trên GitHub Actions
