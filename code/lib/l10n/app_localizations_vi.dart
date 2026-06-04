// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Party Game Hub';

  @override
  String get host => 'Host';

  @override
  String get client => 'Client';

  @override
  String get lobbyTitle => '🎮 Party Game Hub';

  @override
  String get yourNameLabel => 'Tên của bạn';

  @override
  String get roomNameLabel => 'Tên phòng (Host)';

  @override
  String get createRoomBtn => 'Tạo Phòng (Host)';

  @override
  String get findRoomBtn => 'Tìm Phòng (Join)';

  @override
  String get scanQrBtn => 'Quét QR để vào phòng';

  @override
  String get profileSectionTitle => 'Thông Tin Cá Nhân';

  @override
  String get hostSectionTitle => 'Tạo Phòng (Host)';

  @override
  String get tvModeLabel => 'Chế Độ Màn Hình Lớn (TV Mode)';

  @override
  String get joinSectionTitle => 'Vào Phòng (Join)';

  @override
  String get findLanBtn => 'Tìm\nLAN';

  @override
  String get scanQrLabel => 'Quét\nQR';

  @override
  String get enterEmojiBtn => 'Nhập\nEmoji';

  @override
  String get discoverTitle => 'Tìm Phòng';

  @override
  String get searchingRooms => 'Đang tìm kiếm phòng...';

  @override
  String get joinBtn => 'Tham gia';

  @override
  String get unknownRoom => 'Phòng không xác định';

  @override
  String get roomTitle => 'Phòng Chờ';

  @override
  String get selectMiniGame => 'Chọn Mini-Game';

  @override
  String get startBtn => 'Bắt đầu';

  @override
  String get scoreboardTitle => '🏆 Bảng Xếp Hạng';

  @override
  String get backToLobbyBtn => 'Quay lại Phòng Chờ';

  @override
  String get rematchBtn => 'Chơi Lại';

  @override
  String get nextRoundBtn => 'Hiệp Tiếp';

  @override
  String seriesRound(int current, int total) {
    return 'Hiệp $current/$total';
  }

  @override
  String seriesWins(int wins) {
    return '$wins thắng';
  }

  @override
  String pointsText(int score) {
    return '$score điểm';
  }

  @override
  String get gameTugOfWarTitle => 'Kéo Co Tốc Độ';

  @override
  String get gameTugOfWarDesc =>
      'Nhấn nút liên tục để kéo sợi dây về phía bạn!';

  @override
  String get tugOfWarTapLabel => 'TAP ĐI! ▼';

  @override
  String get winText => '🏆 THẮNG!';

  @override
  String get loseText => '😢 THUA!';

  @override
  String get gameSumoBumperTitle => 'Húc Bóng Sinh Tồn';

  @override
  String get gameSumoBumperDesc =>
      'Húc bay đối thủ ra khỏi vòng tròn sinh tồn!';

  @override
  String get gamePenaltyShootoutTitle => 'Sút Phạt Đền';

  @override
  String get gamePenaltyShootoutDesc => 'Sút bóng qua thủ môn để ghi bàn!';

  @override
  String get penaltyTapToShoot => 'Tap để sút!';

  @override
  String get gameAirHockeyTitle => 'Khúc Côn Cầu';

  @override
  String get gameAirHockeyDesc =>
      'Đánh puck qua màn hình đối thủ — mỗi máy là một nửa sân!';

  @override
  String get gameDrawGuessTitle => 'Vẽ & Đoán';

  @override
  String get gameDrawGuessDesc =>
      'Vẽ hình, đối thủ đoán từ — xen kẽ vai trò qua 5 từ!';

  @override
  String get gameReactionTapTitle => 'Phản Xạ Thần Tốc';

  @override
  String get gameReactionTapDesc =>
      'Tap ngay khi màn hình sáng lên — ai nhanh hơn thắng!';

  @override
  String get gameMinesweeperTitle => 'Dò Mìn Tốc Độ';

  @override
  String get gameMinesweeperDesc =>
      'Reveal ô trống nhiều nhất trong 60s, tránh mìn!';

  @override
  String get gameBilliardsTitle => 'Bi-a 9 Ball';

  @override
  String get gameBilliardsDesc =>
      'Bỏ túi ball theo thứ tự — ai gom điểm nhiều hơn thắng!';

  @override
  String get gameBattleshipTitle => 'Hải Chiến Không Gian';

  @override
  String get gameBattleshipDesc => 'Đặt tàu bí mật, bắn hạ hạm đội đối thủ!';

  @override
  String get gameHotPotatoTitle => 'Bảo Mìn Hẹn Giờ';

  @override
  String get gameHotPotatoDesc => 'Vuốt để ném bom sang đối thủ trước khi nổ!';

  @override
  String get closeBtn => 'Đóng';

  @override
  String get cancelBtn => 'Hủy';

  @override
  String get confirmBtn => 'Đồng ý';

  @override
  String get reconnectingText => 'Đang kết nối lại...';

  @override
  String get exitRoomTitleHost => 'Giải tán phòng?';

  @override
  String get exitRoomTitleClient => 'Rời khỏi phòng?';

  @override
  String get exitRoomDescHost =>
      'Tất cả người chơi sẽ bị ngắt kết nối. Bạn có chắc chắn không?';

  @override
  String get exitRoomDescClient => 'Bạn có chắc chắn muốn rời khỏi phòng này?';

  @override
  String get clientWaitingConsoleMode =>
      'Thiết bị của bạn sẽ là Tay Cầm\nChờ Host bắt đầu game...';

  @override
  String get invalidQrCode => 'QR không hợp lệ';

  @override
  String get scanQrTitle => 'Quét QR để vào phòng';

  @override
  String get qrDialogTitle => 'QR vào phòng';

  @override
  String get emojiJoinTitle => 'Nhập Mật Khẩu Emoji';

  @override
  String get emojiJoinDesc => 'Nhập 4 Emoji\ncủa phòng';

  @override
  String get emojiJoinSub => 'Host đọc to 4 emoji trên màn hình của họ';

  @override
  String get emojiSearching => 'Đang tìm phòng...';

  @override
  String get emojiNotFound =>
      '❌ Không tìm thấy phòng. Kiểm tra lại emoji và cùng WiFi.';

  @override
  String get tapToJoinDesc => 'Tap để vào phòng';

  @override
  String get skipBtn => 'Bỏ qua';

  @override
  String get nextBtn => 'Tiếp →';

  @override
  String get letsGo => 'Let\'s Go 🚀';

  @override
  String get onboardingDesc1 =>
      'Bộ sưu tập mini-game nhiều người chơi\nngay trên điện thoại của bạn.';

  @override
  String get onboardingFeature1 => '🎮 10+ mini-games';

  @override
  String get onboardingFeature2 => '⚡ Kết nối WiFi P2P';

  @override
  String get onboardingFeature3 => '🏆 Bảng xếp hạng';

  @override
  String get onboardingFeature4 => '🎲 Roulette Cup';

  @override
  String get onboardingTitle2 => 'Cùng một mạng WiFi';

  @override
  String get onboardingDesc2 =>
      '📡 Hãy chắc chắn tất cả người chơi đang kết nối cùng một mạng WiFi hoặc điểm truy cập (hotspot) LAN.';

  @override
  String get onboardingSub2 =>
      'Game dùng kết nối nội bộ (P2P)\nkhông cần internet.';

  @override
  String get onboardingTitle3 => 'Sẵn sàng chơi!';

  @override
  String get onboardingDesc3 =>
      'Một người tạo phòng (Host), người còn lại tìm phòng và tham gia.\nChúc vui vẻ! 🎮';

  @override
  String get spinningText => 'Đang quay...';

  @override
  String get spinBtn => 'Quay!';

  @override
  String get playBtn => 'Chơi!';

  @override
  String get continueBtn => 'Tiếp Tục';

  @override
  String get leaveRoomBtn => 'Rời Phòng';

  @override
  String get endGameTitle => 'Kết thúc trò chơi?';

  @override
  String get endGameDesc =>
      'Trò chơi sẽ bị hủy và tất cả người chơi sẽ quay về sảnh chờ. Bạn có chắc chắn không?';

  @override
  String get endGameBtn => 'Kết thúc';

  @override
  String get pauseTitle => '⏸ Tạm Dừng';

  @override
  String get victorySubtitle => 'Xuất sắc!';

  @override
  String get defeatSubtitle => 'Cố lên lần sau!';

  @override
  String get youSuffix => ' (bạn)';
}
