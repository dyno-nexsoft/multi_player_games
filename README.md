# Multi-Player Peer-to-Peer Game Project

Chào mừng bạn đến với dự án phát triển game di động multiplayer thời gian thực hỗ trợ kết nối Peer-to-Peer (P2P) cục bộ giữa các thiết bị Android và iOS.

Dự án được xây dựng dựa trên sự kết hợp giữa **Flutter**, **Flame (Game Engine)**, và **Provider (State Management)**.

## 🚀 Tài liệu Kiến Trúc Hệ Thống

Để có cái nhìn toàn diện và chi tiết nhất về thiết kế kiến trúc, lựa chọn công nghệ, luồng dữ liệu, cách thức đồng bộ hóa mạng cũng như kế hoạch triển khai, vui lòng xem tài liệu sau:

*   **[Tài liệu Kiến Trúc & Thiết Kế Hệ Thống](file:///e:/Projects/multi_players_game/doc/architecture.md)**
*   **[Tài liệu Thiết Kế Nền Tảng Party Game Hub](file:///e:/Projects/multi_players_game/doc/party_game_hub.md)**
*   **[Đặc Tả Thiết Kế Các Mini-Games P2P](file:///e:/Projects/multi_players_game/doc/mini_games_spec.md)**
*   **[Phân Tích Thích Ứng "2 Player Games" Sang P2P](file:///e:/Projects/multi_players_game/doc/two_player_games_analysis.md)**
*   **[Quy Chuẩn Cấu Trúc Thư Mục & Mã Nguồn](file:///e:/Projects/multi_players_game/doc/project_structure.md)**
*   **[Đặc Tả Giao Thức Mạng](file:///e:/Projects/multi_players_game/doc/network_protocol_spec.md)**
*   **[Hướng Dẫn Thiết Kế Giao Diện UI/UX](file:///e:/Projects/multi_players_game/doc/ui_ux_design.md)**
*   **[Chiến Lược Kiểm Thử & Đảm Bảo Chất Lượng](file:///e:/Projects/multi_players_game/doc/testing_qa_strategy.md)**

## 🛠️ Công Nghệ Chủ Chốt

1.  **Flutter (Material 3):** Xây dựng giao diện ứng dụng, phòng chờ (Lobby), cài đặt và giao diện hiển thị (HUD Overlay) đẹp mắt.
2.  **Flame Engine:** Xử lý logic game chính, vòng lặp game (Game Loop), va chạm vật lý và render hình ảnh 2D mượt mà.
3.  **Provider:** Quản lý trạng thái ứng dụng toàn cục và Dependency Injection (DI).
4.  **nsd (Network Service Discovery):** Khám phá và đăng ký dịch vụ trong mạng Wi-Fi local sử dụng giao thức mDNS/Bonjour chéo nền tảng (Android <-> iOS).
5.  **TCP/UDP Sockets (dart:io):** Truyền nhận dữ liệu thời gian thực giữa thiết bị Host (Local Server) và Client.

## 📁 Cấu Trúc Thư Mục Dự Án

*   `code/`: Mã nguồn dự án Flutter (sắp triển khai).
*   `doc/`: Chứa các tài liệu thiết kế và kiến trúc dự án.
    *   [architecture.md](file:///e:/Projects/multi_players_game/doc/architecture.md): Tài liệu thiết kế chính.
    *   [party_game_hub.md](file:///e:/Projects/multi_players_game/doc/party_game_hub.md): Tài liệu thiết kế Party Game Hub (Mini-games).
    *   [mini_games_spec.md](file:///e:/Projects/multi_players_game/doc/mini_games_spec.md): Đặc tả thiết kế các mini-game P2P.
    *   [two_player_games_analysis.md](file:///e:/Projects/multi_players_game/doc/two_player_games_analysis.md): Phân tích chuyển đổi các mini-game từ "2 Player Games".
    *   [project_structure.md](file:///e:/Projects/multi_players_game/doc/project_structure.md): Quy chuẩn cấu trúc thư mục & mã nguồn.
    *   [network_protocol_spec.md](file:///e:/Projects/multi_players_game/doc/network_protocol_spec.md): Đặc tả cấu trúc JSON cho các gói tin Socket.
    *   [ui_ux_design.md](file:///e:/Projects/multi_players_game/doc/ui_ux_design.md): Quy chuẩn màu sắc, font chữ và hiệu ứng.
    *   [testing_qa_strategy.md](file:///e:/Projects/multi_players_game/doc/testing_qa_strategy.md): Kịch bản kiểm thử giả lập và thiết bị thật.
