import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sighting_report.dart';
import '../models/payment_receipt.dart';
import '../models/ticket.dart';
import '../models/user_profile.dart';
import '../models/maintenance_report.dart';

class UserRepository {
  UserRepository._(this._prefs, this._activeUserId);

  final SharedPreferences _prefs;
  String? _activeUserId;

  static const _profileKey = 'user_profile_v1';
  static const _sightingsKey = 'sighting_reports_v1';
  static const _ticketsKey = 'tickets_v1';
  static const _receiptsKey = 'receipts_v1';
  static const _maintenanceKey = 'maintenance_reports_v1';
  static const _activeUserStorageKey = 'active_user_id_v1';

  static Future<UserRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final storedActiveUser = prefs.getString(_activeUserStorageKey);
    return UserRepository._(prefs, storedActiveUser);
  }

  String? get activeUserId => _activeUserId;

  Future<void> setActiveUser(String? userId) async {
    _activeUserId = userId;
    if (userId == null) {
      await _prefs.remove(_activeUserStorageKey);
    } else {
      await _prefs.setString(_activeUserStorageKey, userId);
    }
  }

  String _scopedKey(String base) {
    final suffix = _activeUserId ?? 'guest';
    return '${base}_$suffix';
  }

  Future<UserProfile?> loadProfile() async {
    final key = _activeUserId == null ? null : '${_profileKey}_$_activeUserId';
    if (key == null) return null;
    final stored = _prefs.getString(key);
    if (stored == null) return null;
    try {
      final json = jsonDecode(stored) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final key = _activeUserId == null ? null : '${_profileKey}_$_activeUserId';
    if (key == null) return;
    await _prefs.setString(key, jsonEncode(profile.toJson()));
  }

  Future<void> clearProfile() async {
    final key = _activeUserId == null ? null : '${_profileKey}_$_activeUserId';
    if (key == null) return;
    await _prefs.remove(key);
  }

  Future<List<SightingReport>> loadSightings() async {
    final stored = _prefs.getString(_scopedKey(_sightingsKey));
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map((item) => SightingReport.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSightings(List<SightingReport> reports) async {
    final serialized = reports.map((report) => report.toJson()).toList();
    await _prefs.setString(_scopedKey(_sightingsKey), jsonEncode(serialized));
  }

  Future<List<Ticket>> loadTickets() async {
    final stored = _prefs.getString(_scopedKey(_ticketsKey));
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTickets(List<Ticket> tickets) async {
    final serialized = tickets.map((ticket) => ticket.toJson()).toList();
    await _prefs.setString(_scopedKey(_ticketsKey), jsonEncode(serialized));
  }

  Future<List<PaymentReceipt>> loadReceipts() async {
    final stored = _prefs.getString(_scopedKey(_receiptsKey));
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map((item) => PaymentReceipt.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReceipts(List<PaymentReceipt> receipts) async {
    final serialized = receipts.map((r) => r.toJson()).toList();
    await _prefs.setString(_scopedKey(_receiptsKey), jsonEncode(serialized));
  }

  Future<List<MaintenanceReport>> loadMaintenanceReports() async {
    final stored = _prefs.getString(_scopedKey(_maintenanceKey));
    if (stored == null) return [];
    try {
      final jsonList = jsonDecode(stored) as List<dynamic>;
      return jsonList
          .map(
            (item) => MaintenanceReport.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMaintenanceReports(List<MaintenanceReport> reports) async {
    final serialized = reports.map((r) => r.toJson()).toList();
    await _prefs.setString(_scopedKey(_maintenanceKey), jsonEncode(serialized));
  }
}
