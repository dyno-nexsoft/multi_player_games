import 'package:shared_preferences/shared_preferences.dart';

/// Thống kê tích lũy theo thiết bị (mỗi máy là một người chơi).
///
/// Lưu số trận đã chơi, số trận thắng và chuỗi thắng hiện tại vào
/// `shared_preferences` — phục vụ màn hình thành tích / retention.
class PlayerStats {
  final int gamesPlayed;
  final int wins;
  final int currentStreak;
  final int bestStreak;

  const PlayerStats({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  int get losses => gamesPlayed - wins;
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
}

class StatsService {
  StatsService._();

  static const _kGames = 'stats_games_played';
  static const _kWins = 'stats_wins';
  static const _kStreak = 'stats_current_streak';
  static const _kBestStreak = 'stats_best_streak';

  /// Đọc thống kê hiện tại. Không bao giờ throw — lỗi trả về stats rỗng.
  static Future<PlayerStats> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return PlayerStats(
        gamesPlayed: prefs.getInt(_kGames) ?? 0,
        wins: prefs.getInt(_kWins) ?? 0,
        currentStreak: prefs.getInt(_kStreak) ?? 0,
        bestStreak: prefs.getInt(_kBestStreak) ?? 0,
      );
    } catch (_) {
      return const PlayerStats();
    }
  }

  /// Ghi nhận kết quả một trận đã kết thúc. [won] = người chơi cục bộ thắng.
  /// Hòa: [won] = false (vẫn tính là một trận đã chơi nhưng không tăng streak).
  static Future<PlayerStats> recordResult({required bool won}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final games = (prefs.getInt(_kGames) ?? 0) + 1;
      final wins = (prefs.getInt(_kWins) ?? 0) + (won ? 1 : 0);
      final streak = won ? (prefs.getInt(_kStreak) ?? 0) + 1 : 0;
      final best = streak > (prefs.getInt(_kBestStreak) ?? 0)
          ? streak
          : (prefs.getInt(_kBestStreak) ?? 0);

      await prefs.setInt(_kGames, games);
      await prefs.setInt(_kWins, wins);
      await prefs.setInt(_kStreak, streak);
      await prefs.setInt(_kBestStreak, best);

      return PlayerStats(
        gamesPlayed: games,
        wins: wins,
        currentStreak: streak,
        bestStreak: best,
      );
    } catch (_) {
      return const PlayerStats();
    }
  }

  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGames);
      await prefs.remove(_kWins);
      await prefs.remove(_kStreak);
      await prefs.remove(_kBestStreak);
    } catch (_) {}
  }
}
