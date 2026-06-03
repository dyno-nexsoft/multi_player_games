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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
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
  /// **'🎮 Party Game Hub'**
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
