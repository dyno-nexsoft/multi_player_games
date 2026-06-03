import 'package:flutter_test/flutter_test.dart';
import 'package:party_game_hub/core/storage/stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts empty', () async {
    final stats = await StatsService.load();
    expect(stats.gamesPlayed, 0);
    expect(stats.wins, 0);
    expect(stats.currentStreak, 0);
  });

  test('records a win and increments streak', () async {
    await StatsService.recordResult(won: true);
    final stats = await StatsService.recordResult(won: true);
    expect(stats.gamesPlayed, 2);
    expect(stats.wins, 2);
    expect(stats.currentStreak, 2);
    expect(stats.bestStreak, 2);
    expect(stats.winRate, 1.0);
  });

  test('a loss resets current streak but keeps best', () async {
    await StatsService.recordResult(won: true);
    await StatsService.recordResult(won: true);
    final afterLoss = await StatsService.recordResult(won: false);
    expect(afterLoss.gamesPlayed, 3);
    expect(afterLoss.wins, 2);
    expect(afterLoss.currentStreak, 0);
    expect(afterLoss.bestStreak, 2);
    expect(afterLoss.losses, 1);
  });

  test('reset clears everything', () async {
    await StatsService.recordResult(won: true);
    await StatsService.reset();
    final stats = await StatsService.load();
    expect(stats.gamesPlayed, 0);
    expect(stats.wins, 0);
  });
}
