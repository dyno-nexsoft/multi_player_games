import 'package:flutter/material.dart';

/// Quản lý trạng thái ngôn ngữ hiện tại của ứng dụng.
/// Mặc định ban đầu là Tiếng Việt ('vi').
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;

  /// Đặt ngôn ngữ cụ thể cho ứng dụng.
  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  /// Chuyển đổi qua lại giữa Tiếng Việt ('vi') và Tiếng Anh ('en').
  void toggleLocale() {
    if (_locale.languageCode == 'vi') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('vi');
    }
    notifyListeners();
  }
}
