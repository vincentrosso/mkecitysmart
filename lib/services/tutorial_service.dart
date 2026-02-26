import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the dashboard tutorial has been shown.
class TutorialService {
  static const _seenKey = 'dashboard_tutorial_seen';

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
  }
}
