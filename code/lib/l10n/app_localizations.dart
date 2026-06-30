import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'Party Game Hub'**
  String get appName;

  /// No description provided for @host.
  ///
  /// In vi, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @client.
  ///
  /// In vi, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @lobbyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Party Game Hub'**
  String get lobbyTitle;

  /// No description provided for @yourNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get yourNameLabel;

  /// No description provided for @roomNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên phòng (Host)'**
  String get roomNameLabel;

  /// No description provided for @createRoomBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Phòng (Host)'**
  String get createRoomBtn;

  /// No description provided for @findRoomBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tìm Phòng (Join)'**
  String get findRoomBtn;

  /// No description provided for @scanQrBtn.
  ///
  /// In vi, this message translates to:
  /// **'Quét QR để vào phòng'**
  String get scanQrBtn;

  /// No description provided for @profileSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông Tin Cá Nhân'**
  String get profileSectionTitle;

  /// No description provided for @hostSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Phòng (Host)'**
  String get hostSectionTitle;

  /// No description provided for @tvModeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chế Độ Màn Hình Lớn (TV Mode)'**
  String get tvModeLabel;

  /// No description provided for @joinSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vào Phòng (Join)'**
  String get joinSectionTitle;

  /// No description provided for @findLanBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tìm\nLAN'**
  String get findLanBtn;

  /// No description provided for @scanQrLabel.
  ///
  /// In vi, this message translates to:
  /// **'Quét\nQR'**
  String get scanQrLabel;

  /// No description provided for @enterEmojiBtn.
  ///
  /// In vi, this message translates to:
  /// **'Nhập\nEmoji'**
  String get enterEmojiBtn;

  /// No description provided for @discoverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm Phòng'**
  String get discoverTitle;

  /// No description provided for @searchingRooms.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm kiếm phòng...'**
  String get searchingRooms;

  /// No description provided for @joinBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get joinBtn;

  /// No description provided for @unknownRoom.
  ///
  /// In vi, this message translates to:
  /// **'Phòng không xác định'**
  String get unknownRoom;

  /// No description provided for @roomTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phòng Chờ'**
  String get roomTitle;

  /// No description provided for @selectMiniGame.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Mini-Game'**
  String get selectMiniGame;

  /// No description provided for @startBtn.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get startBtn;

  /// No description provided for @scoreboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'🏆 Bảng Xếp Hạng'**
  String get scoreboardTitle;

  /// No description provided for @backToLobbyBtn.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại Phòng Chờ'**
  String get backToLobbyBtn;

  /// No description provided for @rematchBtn.
  ///
  /// In vi, this message translates to:
  /// **'Chơi Lại'**
  String get rematchBtn;

  /// No description provided for @nextRoundBtn.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp Tiếp'**
  String get nextRoundBtn;

  /// No description provided for @seriesRound.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp {current}/{total}'**
  String seriesRound(int current, int total);

  /// No description provided for @seriesWins.
  ///
  /// In vi, this message translates to:
  /// **'{wins} thắng'**
  String seriesWins(int wins);

  /// No description provided for @pointsText.
  ///
  /// In vi, this message translates to:
  /// **'{score} điểm'**
  String pointsText(int score);

  /// No description provided for @gameTugOfWarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kéo Co Tốc Độ'**
  String get gameTugOfWarTitle;

  /// No description provided for @gameTugOfWarDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn nút liên tục để kéo sợi dây về phía bạn!'**
  String get gameTugOfWarDesc;

  /// No description provided for @tugOfWarTapLabel.
  ///
  /// In vi, this message translates to:
  /// **'TAP ĐI! ▼'**
  String get tugOfWarTapLabel;

  /// No description provided for @winText.
  ///
  /// In vi, this message translates to:
  /// **'🏆 THẮNG!'**
  String get winText;

  /// No description provided for @loseText.
  ///
  /// In vi, this message translates to:
  /// **'😢 THUA!'**
  String get loseText;

  /// No description provided for @gameSumoBumperTitle.
  ///
  /// In vi, this message translates to:
  /// **'Húc Bóng Sinh Tồn'**
  String get gameSumoBumperTitle;

  /// No description provided for @gameSumoBumperDesc.
  ///
  /// In vi, this message translates to:
  /// **'Húc bay đối thủ ra khỏi vòng tròn sinh tồn!'**
  String get gameSumoBumperDesc;

  /// No description provided for @gamePenaltyShootoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sút Phạt Đền'**
  String get gamePenaltyShootoutTitle;

  /// No description provided for @gamePenaltyShootoutDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sút bóng qua thủ môn để ghi bàn!'**
  String get gamePenaltyShootoutDesc;

  /// No description provided for @penaltyTapToShoot.
  ///
  /// In vi, this message translates to:
  /// **'Tap để sút!'**
  String get penaltyTapToShoot;

  /// No description provided for @gameAirHockeyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khúc Côn Cầu'**
  String get gameAirHockeyTitle;

  /// No description provided for @gameAirHockeyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đánh puck qua màn hình đối thủ — mỗi máy là một nửa sân!'**
  String get gameAirHockeyDesc;

  /// No description provided for @gameDrawGuessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vẽ & Đoán'**
  String get gameDrawGuessTitle;

  /// No description provided for @gameDrawGuessDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vẽ hình, đối thủ đoán từ — xen kẽ vai trò qua 5 từ!'**
  String get gameDrawGuessDesc;

  /// No description provided for @gameReactionTapTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phản Xạ Thần Tốc'**
  String get gameReactionTapTitle;

  /// No description provided for @gameReactionTapDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tap ngay khi màn hình sáng lên — ai nhanh hơn thắng!'**
  String get gameReactionTapDesc;

  /// No description provided for @gameMinesweeperTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dò Mìn Tốc Độ'**
  String get gameMinesweeperTitle;

  /// No description provided for @gameMinesweeperDesc.
  ///
  /// In vi, this message translates to:
  /// **'Reveal ô trống nhiều nhất trong 60s, tránh mìn!'**
  String get gameMinesweeperDesc;

  /// No description provided for @gameBilliardsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bi-a 9 Ball'**
  String get gameBilliardsTitle;

  /// No description provided for @gameBilliardsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ túi ball theo thứ tự — ai gom điểm nhiều hơn thắng!'**
  String get gameBilliardsDesc;

  /// No description provided for @gameBattleshipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hải Chiến Không Gian'**
  String get gameBattleshipTitle;

  /// No description provided for @gameBattleshipDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đặt tàu bí mật, bắn hạ hạm đội đối thủ!'**
  String get gameBattleshipDesc;

  /// No description provided for @gameHotPotatoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảo Mìn Hẹn Giờ'**
  String get gameHotPotatoTitle;

  /// No description provided for @gameHotPotatoDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vuốt để ném bom sang đối thủ trước khi nổ!'**
  String get gameHotPotatoDesc;

  /// No description provided for @closeBtn.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get closeBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancelBtn;

  /// No description provided for @confirmBtn.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý'**
  String get confirmBtn;

  /// No description provided for @reconnectingText.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối lại...'**
  String get reconnectingText;

  /// No description provided for @exitRoomTitleHost.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán phòng?'**
  String get exitRoomTitleHost;

  /// No description provided for @exitRoomTitleClient.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi phòng?'**
  String get exitRoomTitleClient;

  /// No description provided for @exitRoomDescHost.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả người chơi sẽ bị ngắt kết nối. Bạn có chắc chắn không?'**
  String get exitRoomDescHost;

  /// No description provided for @exitRoomDescClient.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn rời khỏi phòng này?'**
  String get exitRoomDescClient;

  /// No description provided for @clientWaitingConsoleMode.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị của bạn sẽ là Tay Cầm\nChờ Host bắt đầu game...'**
  String get clientWaitingConsoleMode;

  /// No description provided for @invalidQrCode.
  ///
  /// In vi, this message translates to:
  /// **'QR không hợp lệ'**
  String get invalidQrCode;

  /// No description provided for @scanQrTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét QR để vào phòng'**
  String get scanQrTitle;

  /// No description provided for @qrDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'QR vào phòng'**
  String get qrDialogTitle;

  /// No description provided for @emojiJoinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Mật Khẩu Emoji'**
  String get emojiJoinTitle;

  /// No description provided for @emojiJoinDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhập 4 Emoji\ncủa phòng'**
  String get emojiJoinDesc;

  /// No description provided for @emojiJoinSub.
  ///
  /// In vi, this message translates to:
  /// **'Host đọc to 4 emoji trên màn hình của họ'**
  String get emojiJoinSub;

  /// No description provided for @emojiSearching.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm phòng...'**
  String get emojiSearching;

  /// No description provided for @emojiNotFound.
  ///
  /// In vi, this message translates to:
  /// **'❌ Không tìm thấy phòng. Kiểm tra lại emoji và cùng WiFi.'**
  String get emojiNotFound;

  /// No description provided for @tapToJoinDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tap để vào phòng'**
  String get tapToJoinDesc;

  /// No description provided for @skipBtn.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get skipBtn;

  /// No description provided for @nextBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp →'**
  String get nextBtn;

  /// No description provided for @letsGo.
  ///
  /// In vi, this message translates to:
  /// **'Let\'s Go 🚀'**
  String get letsGo;

  /// No description provided for @onboardingDesc1.
  ///
  /// In vi, this message translates to:
  /// **'Bộ sưu tập mini-game nhiều người chơi\nngay trên điện thoại của bạn.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingFeature1.
  ///
  /// In vi, this message translates to:
  /// **'🎮 10+ mini-games'**
  String get onboardingFeature1;

  /// No description provided for @onboardingFeature2.
  ///
  /// In vi, this message translates to:
  /// **'⚡ Kết nối WiFi P2P'**
  String get onboardingFeature2;

  /// No description provided for @onboardingFeature3.
  ///
  /// In vi, this message translates to:
  /// **'🏆 Bảng xếp hạng'**
  String get onboardingFeature3;

  /// No description provided for @onboardingFeature4.
  ///
  /// In vi, this message translates to:
  /// **'🎲 Roulette Cup'**
  String get onboardingFeature4;

  /// No description provided for @onboardingTitle2.
  ///
  /// In vi, this message translates to:
  /// **'Cùng một mạng WiFi'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In vi, this message translates to:
  /// **'📡 Hãy chắc chắn tất cả người chơi đang kết nối cùng một mạng WiFi hoặc điểm truy cập (hotspot) LAN.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingSub2.
  ///
  /// In vi, this message translates to:
  /// **'Game dùng kết nối nội bộ (P2P)\nkhông cần internet.'**
  String get onboardingSub2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng chơi!'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In vi, this message translates to:
  /// **'Một người tạo phòng (Host), người còn lại tìm phòng và tham gia.\nChúc vui vẻ! 🎮'**
  String get onboardingDesc3;

  /// No description provided for @spinningText.
  ///
  /// In vi, this message translates to:
  /// **'Đang quay...'**
  String get spinningText;

  /// No description provided for @spinBtn.
  ///
  /// In vi, this message translates to:
  /// **'Quay!'**
  String get spinBtn;

  /// No description provided for @playBtn.
  ///
  /// In vi, this message translates to:
  /// **'Chơi!'**
  String get playBtn;

  /// No description provided for @continueBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp Tục'**
  String get continueBtn;

  /// No description provided for @leaveRoomBtn.
  ///
  /// In vi, this message translates to:
  /// **'Rời Phòng'**
  String get leaveRoomBtn;

  /// No description provided for @endGameTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc trò chơi?'**
  String get endGameTitle;

  /// No description provided for @endGameDesc.
  ///
  /// In vi, this message translates to:
  /// **'Trò chơi sẽ bị hủy và tất cả người chơi sẽ quay về sảnh chờ. Bạn có chắc chắn không?'**
  String get endGameDesc;

  /// No description provided for @endGameBtn.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get endGameBtn;

  /// No description provided for @pauseTitle.
  ///
  /// In vi, this message translates to:
  /// **'⏸ Tạm Dừng'**
  String get pauseTitle;

  /// No description provided for @victorySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc!'**
  String get victorySubtitle;

  /// No description provided for @defeatSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cố lên lần sau!'**
  String get defeatSubtitle;

  /// No description provided for @youSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (bạn)'**
  String get youSuffix;

  /// No description provided for @gameRoundLabel.
  ///
  /// In vi, this message translates to:
  /// **'Vòng {current}/{total}'**
  String gameRoundLabel(int current, int total);

  /// No description provided for @todGameTitle.
  ///
  /// In vi, this message translates to:
  /// **'🃏 Thật Hay Thách'**
  String get todGameTitle;

  /// No description provided for @todWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chọn người...'**
  String get todWaiting;

  /// No description provided for @todChosen.
  ///
  /// In vi, this message translates to:
  /// **'🎯  {name}  được chọn!'**
  String todChosen(String name);

  /// No description provided for @todWaitingForPlayer.
  ///
  /// In vi, this message translates to:
  /// **'Chờ {name} trả lời...'**
  String todWaitingForPlayer(String name);

  /// No description provided for @todTruthLabel.
  ///
  /// In vi, this message translates to:
  /// **'❓ SỰ THẬT'**
  String get todTruthLabel;

  /// No description provided for @todDareLabel.
  ///
  /// In vi, this message translates to:
  /// **'⭐ THÁCH'**
  String get todDareLabel;

  /// No description provided for @todAcceptBtn.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận'**
  String get todAcceptBtn;

  /// No description provided for @todSkipBtn.
  ///
  /// In vi, this message translates to:
  /// **'Uống & Bỏ'**
  String get todSkipBtn;

  /// No description provided for @todAccepted.
  ///
  /// In vi, this message translates to:
  /// **'🎉 Hoàn thành! +10 điểm'**
  String get todAccepted;

  /// No description provided for @todSkipped.
  ///
  /// In vi, this message translates to:
  /// **'🍺 Bỏ qua — phải uống!'**
  String get todSkipped;

  /// No description provided for @spinGameTitle.
  ///
  /// In vi, this message translates to:
  /// **'🎡 Vòng Quay Số Phận'**
  String get spinGameTitle;

  /// No description provided for @spinWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ...'**
  String get spinWaiting;

  /// No description provided for @spinYouAreIt.
  ///
  /// In vi, this message translates to:
  /// **'👆 Đó là BẠN! Hãy thực hiện nhiệm vụ nhé 😄'**
  String get spinYouAreIt;

  /// No description provided for @spinNextRoundAuto.
  ///
  /// In vi, this message translates to:
  /// **'Vòng tiếp theo tự động...'**
  String get spinNextRoundAuto;

  /// No description provided for @nhieGameTitle.
  ///
  /// In vi, this message translates to:
  /// **'✋ Tôi Chưa Bao Giờ'**
  String get nhieGameTitle;

  /// No description provided for @nhiePreparing.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị câu tiếp theo...'**
  String get nhiePreparing;

  /// No description provided for @nhieStatementHeader.
  ///
  /// In vi, this message translates to:
  /// **'TÔI CHƯA BAO GIỜ...'**
  String get nhieStatementHeader;

  /// No description provided for @nhieQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã từng làm điều này chưa?'**
  String get nhieQuestion;

  /// No description provided for @nhieDoneBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã làm!\n(uống 1 ngụm)'**
  String get nhieDoneBtn;

  /// No description provided for @nhieSafeBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tôi chưa bao giờ\n(an toàn)'**
  String get nhieSafeBtn;

  /// No description provided for @nhieVotedDone.
  ///
  /// In vi, this message translates to:
  /// **'✋ Bạn đã bỏ phiếu \"Tôi đã làm\" — Đang chờ kết quả...'**
  String get nhieVotedDone;

  /// No description provided for @nhieVotedSafe.
  ///
  /// In vi, this message translates to:
  /// **'🙅 Bạn đã bỏ phiếu \"Chưa bao giờ\" — An toàn!'**
  String get nhieVotedSafe;

  /// No description provided for @nhieSipCount.
  ///
  /// In vi, this message translates to:
  /// **'phải uống {count} ngụm! 🍺'**
  String nhieSipCount(int count);

  /// No description provided for @nhieYouInGroup.
  ///
  /// In vi, this message translates to:
  /// **'👆 Bạn nằm trong nhóm này!'**
  String get nhieYouInGroup;

  /// No description provided for @nhieNextRound.
  ///
  /// In vi, this message translates to:
  /// **'Vòng tiếp theo...'**
  String get nhieNextRound;

  /// No description provided for @nhieNobodyConfessed.
  ///
  /// In vi, this message translates to:
  /// **'Không ai thú nhận!\nMọi người vẫn an toàn 👏'**
  String get nhieNobodyConfessed;

  /// No description provided for @nhieResultTitle.
  ///
  /// In vi, this message translates to:
  /// **'KẾT QUẢ'**
  String get nhieResultTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
