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
}
