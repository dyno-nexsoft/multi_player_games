import 'package:party_game_hub/gen/assets.gen.dart';

import '../mini_games/air_hockey/air_hockey_game.dart';
import '../mini_games/battleship/battleship_game.dart';
import '../mini_games/billiards/billiards_game.dart';
import '../mini_games/draw_guess/draw_guess_game.dart';
import '../mini_games/hot_potato/hot_potato_game.dart';
import '../mini_games/minesweeper/minesweeper_game.dart';
import '../mini_games/reaction_tap/reaction_tap_game.dart';
import '../mini_games/penalty_shootout/penalty_game.dart';
import '../mini_games/sumo_bumper/sumo_game.dart';
import '../mini_games/tug_of_war/tug_of_war_game.dart';
import '../presentation/game_provider.dart';
import 'base_mini_game.dart';
import 'mini_game_metadata.dart';

/// Đăng ký toàn bộ mini-game có sẵn trong ứng dụng.
abstract class MiniGameRegistry {
  static const List<MiniGameMetadata> availableGames = [
    MiniGameMetadata(
      id: 'tug_of_war',
      title: 'Kéo Co Tốc Độ',
      description: 'Nhấn nút liên tục để kéo sợi dây về phía bạn!',
      iconPath: 'assets/icons/tug_of_war.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'sumo_bumper',
      title: 'Húc Bóng Sinh Tồn',
      description: 'Húc bay đối thủ ra khỏi vòng tròn sinh tồn!',
      iconPath: 'assets/icons/sumo_bumper.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'penalty_shootout',
      title: 'Sút Phạt Đền',
      description: 'Sút bóng qua thủ môn để ghi bàn!',
      iconPath: 'assets/icons/penalty.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'air_hockey',
      title: 'Khúc Côn Cầu',
      description: 'Đánh puck qua màn hình đối thủ — mỗi máy là một nửa sân!',
      iconPath: 'assets/icons/air_hockey.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'reaction_tap',
      title: 'Phản Xạ Thần Tốc',
      description: 'Tap ngay khi màn hình sáng lên — ai nhanh hơn thắng!',
      iconPath: 'assets/icons/reaction_tap.svg',
      minPlayers: 2,
      maxPlayers: 4,
    ),
    MiniGameMetadata(
      id: 'minesweeper',
      title: 'Dò Mìn Tốc Độ',
      description: 'Reveal ô trống nhiều nhất trong 60s, tránh mìn!',
      iconPath: 'assets/icons/minesweeper.svg',
      minPlayers: 2,
      maxPlayers: 4,
    ),
    MiniGameMetadata(
      id: 'billiards',
      title: 'Bi-a 9 Ball',
      description: 'Bỏ túi ball theo thứ tự — ai gom điểm nhiều hơn thắng!',
      iconPath: 'assets/icons/billiards.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'draw_guess',
      title: 'Vẽ & Đoán',
      description: 'Vẽ hình, đối thủ đoán từ — xen kẽ vai trò qua 5 từ!',
      iconPath: 'assets/icons/draw_guess.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'battleship',
      title: 'Hải Chiến Không Gian',
      description: 'Đặt tàu bí mật, bắn hạ hạm đội đối thủ!',
      iconPath: 'assets/icons/battleship.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
    MiniGameMetadata(
      id: 'hot_potato',
      title: 'Bảo Mìn Hẹn Giờ',
      description: 'Vuốt để ném bom sang đối thủ trước khi nổ!',
      iconPath: 'assets/icons/hot_potato.svg',
      minPlayers: 2,
      maxPlayers: 2,
    ),
  ];

  static SvgGenImage iconFor(String gameId) => switch (gameId) {
    'tug_of_war' => Assets.icons.tugOfWar,
    'sumo_bumper' => Assets.icons.sumoBumper,
    'penalty_shootout' => Assets.icons.penalty,
    'air_hockey' => Assets.icons.airHockey,
    'reaction_tap' => Assets.icons.reactionTap,
    'minesweeper' => Assets.icons.minesweeper,
    'billiards' => Assets.icons.billiards,
    'draw_guess'  => Assets.icons.drawGuess,
    'battleship'  => Assets.icons.battleship,
    'hot_potato'  => Assets.icons.hotPotato,
    _ => throw ArgumentError('Unknown game id: $gameId'),
  };

  static BaseMiniGame createGame(String gameId, GameProvider provider) {
    switch (gameId) {
      case 'tug_of_war':
        return TugOfWarGame(provider);
      case 'sumo_bumper':
        return SumoGame(provider);
      case 'penalty_shootout':
        return PenaltyGame(provider);
      case 'air_hockey':
        return AirHockeyGame(provider);
      case 'reaction_tap':
        return ReactionTapGame(provider);
      case 'minesweeper':
        return MinesweeperGame(provider);
      case 'billiards':
        return BilliardsGame(provider);
      case 'draw_guess':
        return DrawGuessGame(provider);
      case 'battleship':
        return BattleshipGame(provider);
      case 'hot_potato':
        return HotPotatoGame(provider);
      default:
        throw Exception('Game ID "$gameId" không tồn tại trong Registry');
    }
  }
}
