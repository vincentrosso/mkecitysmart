import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class UserRepository {
  UserRepository._(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'user_profile_v1';

  static Future<UserRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRepository._(prefs);
  }

  Future<UserProfile?> loadProfile() async {
    final stored = _prefs.getString(_profileKey);
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
  }
}
