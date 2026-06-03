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
  String get lobbyTitle => '🎮 Party Game Hub';

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
}
