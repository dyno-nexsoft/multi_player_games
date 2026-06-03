import 'dart:developer' as dev;

/// Ghi log cục bộ sử dụng dart:developer, không dùng print().
abstract class AppLogger {
  static void info(String message, {String tag = 'AppLog'}) {
    dev.log(message, name: tag);
  }

  static void warning(String message, {String tag = 'AppLog'}) {
    dev.log('[WARN] $message', name: tag);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String tag = 'AppLog'}) {
    dev.log('[ERROR] $message', name: tag, error: error, stackTrace: stackTrace);
  }
}
