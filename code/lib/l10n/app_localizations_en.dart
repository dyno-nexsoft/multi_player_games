// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Party Game Hub';

  @override
  String get host => 'Host';

  @override
  String get client => 'Client';

  @override
  String get lobbyTitle => 'Party Game Hub';

  @override
  String get yourNameLabel => 'Your Name';

  @override
  String get roomNameLabel => 'Room Name (Host)';

  @override
  String get createRoomBtn => 'Create Room (Host)';

  @override
  String get findRoomBtn => 'Find Room (Join)';

  @override
  String get scanQrBtn => 'Scan QR to Join';

  @override
  String get profileSectionTitle => 'Profile Info';

  @override
  String get hostSectionTitle => 'Host Room';

  @override
  String get tvModeLabel => 'Big Screen Mode (TV Mode)';

  @override
  String get joinSectionTitle => 'Join Room';

  @override
  String get findLanBtn => 'Find\nLAN';

  @override
  String get scanQrLabel => 'Scan\nQR';

  @override
  String get enterEmojiBtn => 'Enter\nEmoji';

  @override
  String get discoverTitle => 'Find Room';

  @override
  String get searchingRooms => 'Searching for rooms...';

  @override
  String get joinBtn => 'Join';

  @override
  String get unknownRoom => 'Unknown Room';

  @override
  String get roomTitle => 'Lobby Room';

  @override
  String get selectMiniGame => 'Select Mini-Game';

  @override
  String get startBtn => 'Start';

  @override
  String get scoreboardTitle => '🏆 Leaderboard';

  @override
  String get backToLobbyBtn => 'Back to Lobby Room';

  @override
  String get rematchBtn => 'Play Again';

  @override
  String get nextRoundBtn => 'Next Round';

  @override
  String seriesRound(int current, int total) {
    return 'Round $current/$total';
  }

  @override
  String seriesWins(int wins) {
    return '$wins wins';
  }

  @override
  String pointsText(int score) {
    return '$score pts';
  }

  @override
  String get gameTugOfWarTitle => 'Speed Tug-of-War';

  @override
  String get gameTugOfWarDesc =>
      'Tap repeatedly to pull the rope to your side!';

  @override
  String get tugOfWarTapLabel => 'TAP NOW! ▼';

  @override
  String get winText => '🏆 WIN!';

  @override
  String get loseText => '😢 LOSE!';

  @override
  String get gameSumoBumperTitle => 'Sumo Bumper';

  @override
  String get gameSumoBumperDesc => 'Bump opponents out of the survival circle!';

  @override
  String get gamePenaltyShootoutTitle => 'Penalty Shootout';

  @override
  String get gamePenaltyShootoutDesc =>
      'Shoot the ball past the goalkeeper to score!';

  @override
  String get penaltyTapToShoot => 'Tap to shoot!';

  @override
  String get gameAirHockeyTitle => 'Air Hockey';

  @override
  String get gameAirHockeyDesc =>
      'Hit the puck into opponent\'s screen — each phone is half of the rink!';

  @override
  String get gameDrawGuessTitle => 'Draw & Guess';

  @override
  String get gameDrawGuessDesc =>
      'Draw a word, opponent guesses — alternate roles across 5 words!';

  @override
  String get gameReactionTapTitle => 'Reaction Tap';

  @override
  String get gameReactionTapDesc =>
      'Tap the moment the screen flashes — fastest wins the round!';

  @override
  String get gameMinesweeperTitle => 'Minesweeper Race';

  @override
  String get gameMinesweeperDesc =>
      'Reveal the most safe cells in 60s — avoid the mines!';

  @override
  String get gameBilliardsTitle => '9-Ball Billiards';

  @override
  String get gameBilliardsDesc =>
      'Pocket balls in order — score more than your opponent to win!';

  @override
  String get gameBattleshipTitle => 'Space Naval Battle';

  @override
  String get gameBattleshipDesc =>
      'Place ships secretly, then hunt down the enemy fleet!';

  @override
  String get gameHotPotatoTitle => 'Hot Potato Bomb';

  @override
  String get gameHotPotatoDesc =>
      'Swipe to throw the ticking bomb before it explodes!';

  @override
  String get closeBtn => 'Close';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get confirmBtn => 'Confirm';

  @override
  String get reconnectingText => 'Reconnecting...';

  @override
  String get exitRoomTitleHost => 'Disband Room?';

  @override
  String get exitRoomTitleClient => 'Leave Room?';

  @override
  String get exitRoomDescHost =>
      'All players will be disconnected. Are you sure?';

  @override
  String get exitRoomDescClient => 'Are you sure you want to leave this room?';

  @override
  String get clientWaitingConsoleMode =>
      'Your device will act as the Gamepad\nWaiting for Host to start...';

  @override
  String get invalidQrCode => 'Invalid QR code';

  @override
  String get scanQrTitle => 'Scan QR to Join';

  @override
  String get qrDialogTitle => 'Room QR Code';

  @override
  String get emojiJoinTitle => 'Enter Emoji Password';

  @override
  String get emojiJoinDesc => 'Enter Room\'s\n4 Emojis';

  @override
  String get emojiJoinSub => 'The Host will show the 4 emojis on their screen';

  @override
  String get emojiSearching => 'Searching for room...';

  @override
  String get emojiNotFound =>
      '❌ Room not found. Check emojis and ensure same WiFi.';

  @override
  String get tapToJoinDesc => 'Tap to join';

  @override
  String get skipBtn => 'Skip';

  @override
  String get nextBtn => 'Next →';

  @override
  String get letsGo => 'Let\'s Go 🚀';

  @override
  String get onboardingDesc1 =>
      'A local multiplayer mini-game collection\nright on your phone.';

  @override
  String get onboardingFeature1 => '🎮 10+ mini-games';

  @override
  String get onboardingFeature2 => '⚡ P2P WiFi connection';

  @override
  String get onboardingFeature3 => '🏆 Leaderboards';

  @override
  String get onboardingFeature4 => '🎲 Roulette Cup';

  @override
  String get onboardingTitle2 => 'Same WiFi Network';

  @override
  String get onboardingDesc2 =>
      '📡 Make sure all players are connected to the same WiFi network or LAN hotspot.';

  @override
  String get onboardingSub2 =>
      'Games use local P2P connections — no internet required.';

  @override
  String get onboardingTitle3 => 'Ready to play!';

  @override
  String get onboardingDesc3 =>
      'One player hosts, others search and join. Have fun! 🎮';

  @override
  String get spinningText => 'Spinning...';

  @override
  String get spinBtn => 'Spin!';

  @override
  String get playBtn => 'Play!';

  @override
  String get continueBtn => 'Continue';

  @override
  String get leaveRoomBtn => 'Leave Room';

  @override
  String get endGameTitle => 'End Game?';

  @override
  String get endGameDesc =>
      'The game will be cancelled and all players will return to the lobby. Are you sure?';

  @override
  String get endGameBtn => 'End Game';

  @override
  String get pauseTitle => '⏸ Paused';

  @override
  String get victorySubtitle => 'Excellent!';

  @override
  String get defeatSubtitle => 'Better luck next time!';

  @override
  String get youSuffix => ' (you)';
}
