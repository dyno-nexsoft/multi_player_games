# Phân Tích Mini-Games: 1 Màn Hình vs P2P Chéo Thiết Bị

Điểm mạnh cốt lõi của mô hình P2P là **thông tin ẩn** — mỗi người chỉ thấy màn hình mình, tạo ra yếu tố bất ngờ và chiến thuật mà game chung 1 màn hình không có.

---

## Bảng So Sánh

| Game | Lợi thế P2P so với 1 màn hình | Độ trễ nhạy | Độ phức tạp | Điểm |
|---|---|---|---|---|
| **Kéo Co** | Không nhìn được ngón tay đối thủ | 🟢 Thấp | 🟢 Thấp | 9/10 |
| **Sút Phạt Đền** | Keeper không thấy hướng sút trước | 🟡 TB | 🟡 TB | 9.5/10 |
| **Khúc Côn Cầu** | Sân liền mạch ảo qua 2 màn hình | 🔴 Cao | 🔴 Cao | 8.5/10 |
| **Xe Tăng** | Fog of War thực sự, không lộ vị trí | 🟡 TB | 🔴 Cao | 9/10 |
| **Bóng Bàn** | Đơn giản, nhịp nhanh, dễ implement | 🟡 TB | 🟢 Thấp | 8/10 |
| **Sumo/Spinner** | Đấu trường rộng hơn 1 màn hình | 🔴 Cao | 🟡 TB | 8.5/10 |
| **Cờ Caro** | Không có lợi thế P2P đáng kể | 🟢 Cực thấp | 🟢 Cực thấp | 5/10 |

---

## Lộ Trình Phát Triển Đề Xuất

**Phase 1** (Nền tảng) — *Đã xong*
- Kết nối mDNS + TCP Socket
- Tug of War, Sumo Bumper, Penalty Shootout

**Phase 2** (Trải nghiệm chéo màn hình)
- Air Hockey (Physics Ownership Transfer)
- Archer Duel (Cross-screen projectile)

**Phase 3** (Game chiến thuật)
- Tank Fight với Fog of War
- Bóng Bàn chéo màn hình (đơn giản, bonus nhanh)
