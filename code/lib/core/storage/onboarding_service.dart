import 'package:shared_preferences/shared_preferences.dart';

/// Theo dõi trạng thái onboarding lần đầu.
class OnboardingService {
  OnboardingService._();
  static const _kFirstTime = 'onboarding_first_time';

  static Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kFirstTime) ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kFirstTime, false);
    } catch (_) {}
  }

  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kFirstTime);
    } catch (_) {}
  }
}
