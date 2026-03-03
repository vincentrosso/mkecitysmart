import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the dashboard tutorial has been shown.
///
/// Uses a version number so existing users see updated walkthroughs
/// when new features are added.
class TutorialService {
  static const _seenKey = 'dashboard_tutorial_seen';
  static const _versionKey = 'dashboard_tutorial_version';

  /// Bump this when the walkthrough changes so users see it again.
  static const int _currentVersion = 2;

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_seenKey) ?? false;
    final version = prefs.getInt(_versionKey) ?? 0;
    return seen && version >= _currentVersion;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    await prefs.setInt(_versionKey, _currentVersion);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenKey);
    await prefs.remove(_versionKey);
  }
}
