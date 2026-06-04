import 'package:party_game_hub/gen/assets.gen.dart';

import '../mini_games/air_hockey/air_hockey_game.dart';
import '../mini_games/battleship/battleship_game.dart';
import '../mini_games/billiards/billiards_game.dart';
import '../mini_games/code_breaker/code_breaker_game.dart';
import '../mini_games/draw_guess/draw_guess_game.dart';
import '../mini_games/neon_dodge/neon_dodge_game.dart';
import '../mini_games/hot_potato/hot_potato_game.dart';
import '../mini_games/liars_dice/liars_dice_game.dart';
import '../mini_games/minesweeper/minesweeper_game.dart';
import '../mini_games/reaction_tap/reaction_tap_game.dart';
import '../mini_games/penalty_shootout/penalty_game.dart';
import '../mini_games/sumo_bumper/sumo_game.dart';
import '../mini_games/tug_of_war/tug_of_war_game.dart';
import '../mini_games/archer_duel/archer_duel_game.dart';
import '../mini_games/tank_fight/tank_game.dart';
import '../mini_games/maze_hide_seek/maze_game.dart';
import '../presentation/game_provider.dart';
import 'base_mini_game.dart';
import 'game_ids.dart';
import 'mini_game_metadata.dart';

/// Đăng ký toàn bộ mini-game có sẵn trong ứng dụng.
abstract class MiniGameRegistry {
  static const List<MiniGameMetadata> availableGames = [
    MiniGameMetadata(
      id: GameIds.tugOfWar,
      title: 'Kéo Co Tốc Độ',
      description: 'Nhấn nút liên tục để kéo sợi dây về phía bạn!',
      iconPath: 'assets/icons/tug_of_war.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.sumoBumper,
      title: 'Đẩy Nhau (Sumo Bumper)',
      description: 'Điều khiển con quay đẩy đối thủ văng khỏi sàn đấu!',
      iconPath: 'assets/icons/sumo_bumper.svg',
      minPlayers: 2,
      maxPlayers: 4,
      supportsConsoleMode: true,
      controllerConfig: {
        'joystick_enabled': true,
        'labels': {'A': 'Húc'},
        'highlight': 'A',
      },
    ),
    MiniGameMetadata(
      id: GameIds.penaltyShootout,
      title: 'Sút Phạt Đền',
      description: 'Sút bóng qua thủ môn để ghi bàn!',
      iconPath: 'assets/icons/penalty.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.airHockey,
      title: 'Khúc Côn Cầu',
      description: 'Đánh puck qua màn hình đối thủ — mỗi máy là một nửa sân!',
      iconPath: 'assets/icons/air_hockey.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.reactionTap,
      title: 'Phản Xạ Thần Tốc',
      description: 'Tap ngay khi màn hình sáng lên — ai nhanh hơn thắng!',
      iconPath: 'assets/icons/reaction_tap.svg',
      minPlayers: 2,
      maxPlayers: 4,
    ),
    MiniGameMetadata(
      id: GameIds.minesweeper,
      title: 'Dò Mìn Tốc Độ',
      description: 'Reveal ô trống nhiều nhất trong 60s, tránh mìn!',
      iconPath: 'assets/icons/minesweeper.svg',
      minPlayers: 2,
      maxPlayers: 4,
    ),
    MiniGameMetadata(
      id: GameIds.billiards,
      title: 'Bi-a 9 Ball',
      description: 'Bỏ túi ball theo thứ tự — ai gom điểm nhiều hơn thắng!',
      iconPath: 'assets/icons/billiards.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.drawGuess,
      title: 'Vẽ & Đoán',
      description: 'Vẽ hình, đối thủ đoán từ — xen kẽ vai trò qua 5 từ!',
      iconPath: 'assets/icons/draw_guess.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.battleship,
      title: 'Hải Chiến Không Gian',
      description: 'Đặt tàu bí mật, bắn hạ hạm đội đối thủ!',
      iconPath: 'assets/icons/battleship.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.hotPotato,
      title: 'Bảo Mìn Hẹn Giờ',
      description: 'Vuốt để ném bom sang đối thủ trước khi nổ!',
      iconPath: 'assets/icons/hot_potato.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.codeBreaker,
      title: 'Phá Mã',
      description: 'Đoán mã 4 số bí mật của đối thủ trước khi bị phá!',
      iconPath: 'assets/icons/code_breaker.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.liarsDice,
      title: 'Xúc Xắc Tố',
      description: 'Ra giá xúc xắc, bắt bài nói dối của đối thủ!',
      iconPath: 'assets/icons/liars_dice.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    // ── Console Mode games ──────────────────────────────────────────────────
    MiniGameMetadata(
      id: GameIds.neonDodge,
      title: 'Neon Dodge',
      description: 'Né chướng ngại vật rơi — Host là màn hình, bạn là tay cầm!',
      iconPath: 'assets/icons/neon_dodge.svg',
      minPlayers: 2,
      maxPlayers: 6,
      supportsConsoleMode: true,
      controllerConfig: {
        'joystick_enabled': false,
        'gyro_hint': true,
        'labels': {'A': 'Phanh', 'B': 'Tốc độ'},
        'highlight': 'B',
      },
    ),
    MiniGameMetadata(
      id: GameIds.archerDuel,
      title: 'Bắn Cung Xuyên Không',
      description: 'Căn lực và góc để bắn cung xuyên qua màn hình đối thủ!',
      iconPath: 'assets/icons/archer_duel.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.tankFight,
      title: 'Đấu Xe Tăng',
      description: 'Sương mù chiến tranh che khuất tầm nhìn, bắn đạn nổ tung!',
      iconPath: 'assets/icons/tank_fight.svg',
      minPlayers: 2,
      maxPlayers: 4,
      supportsConsoleMode: true,
      controllerConfig: {
        'joystick_enabled': true,
        'labels': {'A': 'Bắn', 'B': 'Lá chắn'},
        'highlight': 'A',
      },
    ),
    MiniGameMetadata(
      id: GameIds.mazeHideSeek,
      title: 'Trốn Tìm Mê Cung',
      description:
          'Cảnh sát truy bắt kẻ trộm trong mê cung tối tăm với Radar và Dash!',
      iconPath: 'assets/icons/maze_hide_seek.svg',
      minPlayers: 2,
      maxPlayers: 4,
      supportsConsoleMode: true,
      controllerConfig: {
        'joystick_enabled': true,
        'labels': {'A': 'Chém', 'B': 'Lướt'},
        'highlight': 'A',
      },
    ),
  ];

  static SvgGenImage iconFor(String gameId) => switch (gameId) {
    GameIds.tugOfWar => Assets.icons.tugOfWar,
    GameIds.sumoBumper => Assets.icons.sumoBumper,
    GameIds.penaltyShootout => Assets.icons.penalty,
    GameIds.airHockey => Assets.icons.airHockey,
    GameIds.reactionTap => Assets.icons.reactionTap,
    GameIds.minesweeper => Assets.icons.minesweeper,
    GameIds.billiards => Assets.icons.billiards,
    GameIds.drawGuess => Assets.icons.drawGuess,
    GameIds.battleship => Assets.icons.battleship,
    GameIds.hotPotato => Assets.icons.hotPotato,
    GameIds.codeBreaker => Assets.icons.codeBreaker,
    GameIds.liarsDice => Assets.icons.liarsDice,
    GameIds.neonDodge => Assets.icons.neonDodge,
    GameIds.archerDuel => Assets.icons.archerDuel,
    GameIds.tankFight => Assets.icons.tankFight,
    GameIds.mazeHideSeek => Assets.icons.mazeHideSeek,
    _ => throw ArgumentError('Unknown game id: $gameId'),
  };

  static BaseMiniGame createGame(String gameId, GameProvider provider) {
    switch (gameId) {
      case GameIds.tugOfWar:
        return TugOfWarGame(provider);
      case GameIds.sumoBumper:
        return SumoGame(provider);
      case GameIds.penaltyShootout:
        return PenaltyGame(provider);
      case GameIds.airHockey:
        return AirHockeyGame(provider);
      case GameIds.reactionTap:
        return ReactionTapGame(provider);
      case GameIds.minesweeper:
        return MinesweeperGame(provider);
      case GameIds.billiards:
        return BilliardsGame(provider);
      case GameIds.drawGuess:
        return DrawGuessGame(provider);
      case GameIds.battleship:
        return BattleshipGame(provider);
      case GameIds.hotPotato:
        return HotPotatoGame(provider);
      case GameIds.codeBreaker:
        return CodeBreakerGame(provider);
      case GameIds.liarsDice:
        return LiarsDiceGame(provider);
      case GameIds.neonDodge:
        return NeonDodgeGame(provider);
      case GameIds.archerDuel:
        return ArcherDuelGame(provider);
      case GameIds.tankFight:
        return TankGame(provider);
      case GameIds.mazeHideSeek:
        return MazeGame(provider);
      default:
        throw Exception('Game ID "$gameId" không tồn tại trong Registry');
    }
  }
}
