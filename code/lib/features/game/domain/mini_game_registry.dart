import 'package:party_game_hub/gen/assets.gen.dart';

import '../mini_games/draw_guess/draw_guess_game.dart';
import '../mini_games/hot_potato/hot_potato_game.dart';
import '../mini_games/liars_dice/liars_dice_game.dart';
import '../mini_games/minesweeper/minesweeper_game.dart';
import '../mini_games/neon_dodge/neon_dodge_game.dart';
import '../mini_games/reaction_tap/reaction_tap_game.dart';
import '../mini_games/sumo_bumper/sumo_game.dart';
import '../mini_games/tug_of_war/tug_of_war_game.dart';
import '../mini_games/tank_fight/tank_game.dart';
import '../mini_games/maze_hide_seek/maze_game.dart';
import '../mini_games/truth_or_dare/truth_or_dare_game.dart';
import '../mini_games/spin_picker/spin_picker_game.dart';
import '../mini_games/never_have_i_ever/never_have_i_ever_game.dart';
import '../presentation/game_provider.dart';
import 'base_mini_game.dart';
import 'game_ids.dart';
import 'mini_game_metadata.dart';

abstract class MiniGameRegistry {
  static const List<MiniGameMetadata> availableGames = [
    // ── Party / Drinking games (nhiều người, phù hợp nhậu) ──────────────────
    MiniGameMetadata(
      id: GameIds.truthOrDare,
      title: 'Thật Hay Thách',
      description: 'Vòng quay chọn ngẫu nhiên — trả lời thật hoặc thực hiện thách!',
      iconPath: 'assets/icons/truth_or_dare.svg',
      minPlayers: 3,
      maxPlayers: 8,
    ),
    MiniGameMetadata(
      id: GameIds.spinPicker,
      title: 'Vòng Quay Số Phận',
      description: 'Bánh xe ngẫu nhiên chỉ vào ai đó — họ phải uống hoặc thực hiện nhiệm vụ!',
      iconPath: 'assets/icons/spin_picker.svg',
      minPlayers: 3,
      maxPlayers: 8,
    ),
    MiniGameMetadata(
      id: GameIds.neverHaveIEver,
      title: 'Tôi Chưa Bao Giờ',
      description: 'Ai đã từng làm thì mất 1 ngón tay — phải uống! Giữ được nhiều ngón nhất thắng.',
      iconPath: 'assets/icons/never_have_i_ever.svg',
      minPlayers: 3,
      maxPlayers: 8,
    ),
    MiniGameMetadata(
      id: GameIds.hotPotato,
      title: 'Bom Hẹn Giờ',
      description: 'Vuốt để ném bom ngẫu nhiên sang bất kỳ ai — ai cầm khi nổ phải uống!',
      iconPath: 'assets/icons/hot_potato.svg',
      minPlayers: 3,
      maxPlayers: 6,
    ),
    MiniGameMetadata(
      id: GameIds.liarsDice,
      title: 'Xúc Xắc Tố',
      description: 'Ra giá xúc xắc, bắt bài nói dối của đối thủ — ai tố sai phải uống!',
      iconPath: 'assets/icons/liars_dice.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),

    // ── Quick reflex / arcade (nhiều người) ──────────────────────────────────
    MiniGameMetadata(
      id: GameIds.reactionTap,
      title: 'Phản Xạ Thần Tốc',
      description: 'Tap ngay khi màn hình sáng lên — ai chậm nhất vòng này uống!',
      iconPath: 'assets/icons/reaction_tap.svg',
      minPlayers: 2,
      maxPlayers: 6,
    ),
    MiniGameMetadata(
      id: GameIds.tugOfWar,
      title: 'Kéo Co Tốc Độ',
      description: 'Nhấn liên tục để kéo dây về phía mình — đội thua uống!',
      iconPath: 'assets/icons/tug_of_war.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: GameIds.minesweeper,
      title: 'Dò Mìn Tốc Độ',
      description: 'Lật ô trống nhiều nhất trong 60s — ai lật nhầm mìn uống!',
      iconPath: 'assets/icons/minesweeper.svg',
      minPlayers: 2,
      maxPlayers: 4,
    ),
    MiniGameMetadata(
      id: GameIds.drawGuess,
      title: 'Vẽ & Đoán',
      description: 'Vẽ hình, cả nhóm tranh nhau đoán từ — không ai đoán được thì người vẽ uống!',
      iconPath: 'assets/icons/draw_guess.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),

    // ── Multiplayer action (Console / gamepad mode) ───────────────────────────
    MiniGameMetadata(
      id: GameIds.sumoBumper,
      title: 'Đẩy Nhau (Sumo)',
      description: 'Điều khiển con quay đẩy đối thủ văng khỏi sàn!',
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
      id: GameIds.neonDodge,
      title: 'Neon Dodge',
      description: 'Né chướng ngại vật rơi — Host là màn hình lớn, bạn là tay cầm!',
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
      id: GameIds.tankFight,
      title: 'Đấu Xe Tăng',
      description: 'Sương mù chiến tranh che khuất tầm nhìn — bắn tan đối thủ!',
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
      description: 'Cảnh sát truy bắt kẻ trộm trong mê cung tối với Radar và Dash!',
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
    GameIds.truthOrDare => Assets.icons.truthOrDare,
    GameIds.spinPicker => Assets.icons.spinPicker,
    GameIds.neverHaveIEver => Assets.icons.neverHaveIEver,
    GameIds.hotPotato => Assets.icons.hotPotato,
    GameIds.liarsDice => Assets.icons.liarsDice,
    GameIds.reactionTap => Assets.icons.reactionTap,
    GameIds.tugOfWar => Assets.icons.tugOfWar,
    GameIds.minesweeper => Assets.icons.minesweeper,
    GameIds.drawGuess => Assets.icons.drawGuess,
    GameIds.sumoBumper => Assets.icons.sumoBumper,
    GameIds.neonDodge => Assets.icons.neonDodge,
    GameIds.tankFight => Assets.icons.tankFight,
    GameIds.mazeHideSeek => Assets.icons.mazeHideSeek,
    _ => throw ArgumentError('Unknown game id: $gameId'),
  };

  static BaseMiniGame createGame(String gameId, GameProvider provider) {
    switch (gameId) {
      case GameIds.truthOrDare:
        return TruthOrDareGame(provider);
      case GameIds.spinPicker:
        return SpinPickerGame(provider);
      case GameIds.neverHaveIEver:
        return NeverHaveIEverGame(provider);
      case GameIds.hotPotato:
        return HotPotatoGame(provider);
      case GameIds.liarsDice:
        return LiarsDiceGame(provider);
      case GameIds.reactionTap:
        return ReactionTapGame(provider);
      case GameIds.tugOfWar:
        return TugOfWarGame(provider);
      case GameIds.minesweeper:
        return MinesweeperGame(provider);
      case GameIds.drawGuess:
        return DrawGuessGame(provider);
      case GameIds.sumoBumper:
        return SumoGame(provider);
      case GameIds.neonDodge:
        return NeonDodgeGame(provider);
      case GameIds.tankFight:
        return TankGame(provider);
      case GameIds.mazeHideSeek:
        return MazeGame(provider);
      default:
        throw Exception('Game ID "$gameId" không tồn tại trong Registry');
    }
  }
}
