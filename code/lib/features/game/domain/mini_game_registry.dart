import 'package:party_game_hub/gen/assets.gen.dart';

import '../mini_games/air_hockey/air_hockey_game.dart';
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
  ];

  static SvgGenImage iconFor(String gameId) => switch (gameId) {
    'tug_of_war' => Assets.icons.tugOfWar,
    'sumo_bumper' => Assets.icons.sumoBumper,
    'penalty_shootout' => Assets.icons.penalty,
    'air_hockey' => Assets.icons.airHockey,
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
      default:
        throw Exception('Game ID "$gameId" không tồn tại trong Registry');
    }
  }
}
