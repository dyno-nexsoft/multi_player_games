import 'dart:math';

/// Hệ thống mật khẩu phòng bằng Emoji — 4 emoji ngẫu nhiên từ bộ 16 biểu tượng.
/// Dễ đọc to cho nhau hơn là gõ số IP.
abstract class EmojiCode {
  static const List<String> dictionary = [
    '🍎',
    '🍕',
    '👻',
    '👽',
    '🚀',
    '💩',
    '🤡',
    '🔥',
    '❄️',
    '🦄',
    '🐉',
    '💎',
    '⚡',
    '🎮',
    '🏆',
    '🎯',
  ];

  static const int codeLength = 4;
  static const String _separator = ' [';
  static const String _closer = ']';

  /// Sinh 4 emoji ngẫu nhiên không trùng lặp.
  static String generate() {
    final pool = List.of(dictionary)..shuffle(Random());
    return pool.take(codeLength).join('');
  }

  /// Nhúng emoji code vào tên phòng: "My Room" → "My Room [🍕🚀👽🔥]"
  static String embed(String roomName, String code) =>
      '$roomName$_separator$code$_closer';

  /// Tách tên hiển thị (bỏ phần code): "My Room [🍕🚀👽🔥]" → "My Room"
  static String displayName(String serviceName) {
    final idx = serviceName.lastIndexOf(_separator);
    return idx >= 0 ? serviceName.substring(0, idx) : serviceName;
  }

  /// Tách emoji code khỏi tên service; trả null nếu không có.
  static String? extractCode(String serviceName) {
    final start = serviceName.lastIndexOf(_separator);
    final end = serviceName.lastIndexOf(_closer);
    if (start < 0 || end <= start + _separator.length) return null;
    return serviceName.substring(start + _separator.length, end);
  }

  /// Kiểm tra 4-emoji code có hợp lệ không (đúng số lượng, từ dictionary).
  static bool isValid(String code) {
    final parts = parse(code);
    return parts.length == codeLength && parts.every(dictionary.contains);
  }

  /// Tách chuỗi emoji thành danh sách riêng lẻ bằng cách khớp từng ký tự trong dictionary.
  static List<String> parse(String code) {
    final result = <String>[];
    var remaining = code;
    while (remaining.isNotEmpty && result.length < codeLength) {
      bool found = false;
      for (final emoji in dictionary) {
        if (remaining.startsWith(emoji)) {
          result.add(emoji);
          remaining = remaining.substring(emoji.length);
          found = true;
          break;
        }
      }
      if (!found) break;
    }
    return result;
  }
}
