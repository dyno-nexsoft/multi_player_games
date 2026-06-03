import 'package:flame_audio/flame_audio.dart';
import 'package:party_game_hub/gen/assets.gen.dart';

/// Wrapper tập trung cho toàn bộ âm thanh trong game.
///
/// Dùng [AppAudio.preload] một lần khi khởi động để tránh lag khi phát lần đầu.
/// Mọi lỗi đều bị nuốt — thiếu file audio không crash app.
///
/// Thay thế placeholder .wav bằng file .ogg từ kenney.nl và cập nhật tên file
/// trong [Assets.audio] (chạy `fvm dart run build_runner build` sau khi thêm file).
class AppAudio {
  AppAudio._();

  static bool _enabled = true;

  /// Tắt/bật toàn bộ âm thanh (hữu ích cho testing).
  static void setEnabled(bool value) => _enabled = value;

  /// Pre-load tất cả sound vào cache để phát không bị delay.
  static Future<void> preload() async {
    final files = [
      Assets.audio.countdownBeep,
      Assets.audio.countdownGo,
      Assets.audio.tap,
      Assets.audio.win,
      Assets.audio.lose,
      Assets.audio.bump,
      Assets.audio.kick,
      Assets.audio.goal,
      Assets.audio.puckHit,
    ];
    for (final path in files) {
      try {
        await FlameAudio.audioCache.load(_name(path));
      } catch (_) {}
    }
  }

  // ── Countdown ────────────────────────────────────────────────────────────

  static void playCountdownBeep() => _play(Assets.audio.countdownBeep);
  static void playCountdownGo() => _play(Assets.audio.countdownGo);

  // ── Lobby / UI ───────────────────────────────────────────────────────────

  static void playTap() => _play(Assets.audio.tap);

  // ── Game events ──────────────────────────────────────────────────────────

  static void playWin() => _play(Assets.audio.win);
  static void playLose() => _play(Assets.audio.lose);

  // ── Game-specific ────────────────────────────────────────────────────────

  static void playBump() => _play(Assets.audio.bump);
  static void playKick() => _play(Assets.audio.kick);
  static void playGoal() => _play(Assets.audio.goal);
  static void playPuckHit() => _play(Assets.audio.puckHit);

  // ── Internal ─────────────────────────────────────────────────────────────

  static void _play(String assetPath) {
    if (!_enabled) return;
    try {
      FlameAudio.play(_name(assetPath));
    } catch (_) {}
  }

  /// FlameAudio expects just the filename, not the full asset path.
  static String _name(String assetPath) => assetPath.split('/').last;
}
