import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/night_parking_permission.dart';
import 'notification_service.dart';

/// Service for managing Milwaukee Night Parking Permissions (2 AM - 6 AM).
///
/// Milwaukee enforces night parking restrictions on most residential streets.
/// This service helps users:
/// - Check if their address requires a permit
/// - Track their permit status
/// - Receive reminders about enforcement and renewals
///
/// Night parking citations are the #1 violation type in Milwaukee (~158K+ tickets),
/// making this feature critical for preventing tickets.
class NightParkingService {
  NightParkingService._();
  static final NightParkingService instance = NightParkingService._();

  static const String _prefsKey = 'night_parking_permission';
  static const String _reminderPrefsKey = 'night_parking_reminder_enabled';

  NightParkingPermission? _permission;
  bool _reminderEnabled = true;
  bool _initialized = false;

  /// Current user's night parking permission (if any)
  NightParkingPermission? get permission => _permission;

  /// Whether the user has night parking reminders enabled
  bool get reminderEnabled => _reminderEnabled;

  /// Whether the user has an active, valid permit
  bool get hasValidPermission => _permission?.isValid ?? false;

  /// Whether the user's permit is expiring soon (within 30 days)
  bool get isExpiringSoon => _permission?.isExpiringSoon() ?? false;

  /// City application URL for night parking permission
  static const String applicationUrl =
      'https://city.milwaukee.gov/NightParking';

  // ──────────────────────────────────────────────────────────────────────
  //  Initialization & Persistence
  // ──────────────────────────────────────────────────────────────────────

  /// Initialize the service, loading any persisted permission data
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load reminder preference
      _reminderEnabled = prefs.getBool(_reminderPrefsKey) ?? true;

      // Load permission data
      final permissionJson = prefs.getString(_prefsKey);
      if (permissionJson != null) {
        try {
          final data = jsonDecode(permissionJson) as Map<String, dynamic>;
          _permission = NightParkingPermission.fromJson(data);
        } catch (e) {
          log('Failed to parse night parking permission: $e');
        }
      }

      _initialized = true;
      log('NightParkingService initialized: permission=${_permission?.status}');
    } catch (e) {
      log('NightParkingService init failed: $e');
      _initialized = true;
    }
  }

  /// Save the current permission to persistent storage
  Future<void> _savePermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (_permission != null) {
      await prefs.setString(_prefsKey, jsonEncode(_permission!.toJson()));
    } else {
      await prefs.remove(_prefsKey);
    }
  }

  /// Save reminder preference
  Future<void> setReminderEnabled(bool enabled) async {
    _reminderEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderPrefsKey, enabled);

    // Update notification schedule based on new preference
    if (enabled) {
      await scheduleNightParkingReminders();
    } else {
      await cancelNightParkingReminders();
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Zone Detection
  // ──────────────────────────────────────────────────────────────────────

  /// Check if a location requires night parking permission.
  ///
  /// Milwaukee's night parking rules:
  /// - Most residential streets: permission REQUIRED (2 AM - 6 AM)
  /// - Metered zones: typically EXEMPT during metered hours
  /// - Some downtown areas: may have different rules
  ///
  /// For MVP, we assume most residential areas require permission.
  /// Future: integrate with city GIS data for precise zone lookup.
  Future<NightParkingZoneResult> checkZone({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    // Known exempt zones (approximate bounding boxes)
    // These are simplified - real implementation would use city GIS data
    final exemptZones = _getExemptZones();

    for (final zone in exemptZones) {
      if (_isPointInBoundingBox(latitude, longitude, zone)) {
        return NightParkingZoneResult.exempt(
          zoneName: zone['name'] as String,
          reason: zone['reason'] as String,
        );
      }
    }

    // Check for metered parking indicators in the address
    if (address != null) {
      final lowerAddress = address.toLowerCase();
      if (lowerAddress.contains('water st') ||
          lowerAddress.contains('wisconsin ave') ||
          lowerAddress.contains('broadway')) {
        // These are common metered areas - but still check
        // Night parking may still apply after meters expire
      }
    }

    // Default: residential zone requiring permission
    return NightParkingZoneResult.requiresPermission(
      zoneName: _estimateZoneName(latitude, longitude, address),
      zoneId: _estimateZoneId(latitude, longitude),
    );
  }

  /// Get a list of known exempt zones with bounding boxes
  List<Map<String, dynamic>> _getExemptZones() {
    return [
      // Downtown metered core (approximate)
      {
        'name': 'Downtown Metered District',
        'reason': 'Metered parking zone - check meter hours',
        'minLat': 43.0350,
        'maxLat': 43.0450,
        'minLng': -87.9150,
        'maxLng': -87.9050,
      },
      // Third Ward
      {
        'name': 'Historic Third Ward',
        'reason': 'Special parking district',
        'minLat': 43.0280,
        'maxLat': 43.0350,
        'minLng': -87.9100,
        'maxLng': -87.9000,
      },
      // Add more exempt zones as needed
    ];
  }

  bool _isPointInBoundingBox(
    double lat,
    double lng,
    Map<String, dynamic> zone,
  ) {
    final minLat = zone['minLat'] as double;
    final maxLat = zone['maxLat'] as double;
    final minLng = zone['minLng'] as double;
    final maxLng = zone['maxLng'] as double;

    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  String _estimateZoneName(double lat, double lng, String? address) {
    // Simple zone estimation based on location
    // North side
    if (lat > 43.07) return 'North Milwaukee';
    // South side
    if (lat < 43.02) return 'South Milwaukee';
    // East side (near lake)
    if (lng > -87.90) return 'East Side';
    // West side
    if (lng < -87.95) return 'West Milwaukee';

    // Try to extract neighborhood from address
    if (address != null) {
      if (address.toLowerCase().contains('bay view')) return 'Bay View';
      if (address.toLowerCase().contains('riverwest')) return 'Riverwest';
      if (address.toLowerCase().contains('walker')) return "Walker's Point";
    }

    return 'Milwaukee Residential';
  }

  String _estimateZoneId(double lat, double lng) {
    // Generate a zone ID based on grid position
    // This is a placeholder - real implementation would use city data
    final latGrid = ((lat - 43.0) * 100).round();
    final lngGrid = ((lng + 88.0) * 100).round();
    return 'MKE-$latGrid-$lngGrid';
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Permission Management
  // ──────────────────────────────────────────────────────────────────────

  /// Set the user's night parking permission
  Future<void> setPermission(NightParkingPermission permission) async {
    _permission = permission;
    await _savePermission();

    // Schedule appropriate reminders
    if (_reminderEnabled) {
      await scheduleNightParkingReminders();
    }
  }

  /// Update the permission status (e.g., after checking application status)
  Future<void> updatePermissionStatus(NightParkingStatus status) async {
    if (_permission == null) return;

    _permission = _permission!.copyWith(status: status);
    await _savePermission();
  }

  /// Clear the user's permission data
  Future<void> clearPermission() async {
    _permission = null;
    await _savePermission();
    await cancelNightParkingReminders();
  }

  /// Create a new permission from user input
  Future<void> createPermission({
    required String address,
    required String licensePlate,
    String? vehicleDescription,
    String? zoneId,
    NightParkingStatus initialStatus = NightParkingStatus.pending,
    DateTime? expirationDate,
  }) async {
    final permission = NightParkingPermission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: initialStatus,
      address: address,
      zoneId: zoneId,
      licensePlate: licensePlate,
      vehicleDescription: vehicleDescription,
      issueDate: initialStatus == NightParkingStatus.active
          ? DateTime.now()
          : null,
      expirationDate: expirationDate,
      reminderEnabled: true,
    );

    await setPermission(permission);
  }

  /// Simulate activating a permission (for testing or after confirmation)
  Future<void> activatePermission({DateTime? expirationDate}) async {
    if (_permission == null) return;

    final expiry =
        expirationDate ??
        DateTime.now().add(const Duration(days: 365)); // Annual permit

    _permission = _permission!.copyWith(
      status: NightParkingStatus.active,
      issueDate: DateTime.now(),
      expirationDate: expiry,
    );

    await _savePermission();
    await scheduleNightParkingReminders();
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Enforcement Window Detection
  // ──────────────────────────────────────────────────────────────────────

  /// Check if we're currently in the night parking enforcement window
  bool isEnforcementActive() {
    final now = DateTime.now();
    return now.hour >= 2 && now.hour < 6;
  }

  /// Get time until enforcement starts (null if already active)
  Duration? timeUntilEnforcement() {
    final now = DateTime.now();
    if (isEnforcementActive()) return null;

    // Calculate time until 2 AM
    var enforcement = DateTime(now.year, now.month, now.day, 2, 0);
    if (now.hour >= 6) {
      // After 6 AM, next enforcement is tomorrow at 2 AM
      enforcement = enforcement.add(const Duration(days: 1));
    }

    return enforcement.difference(now);
  }

  /// Get time until enforcement ends (null if not active)
  Duration? timeUntilEnforcementEnds() {
    final now = DateTime.now();
    if (!isEnforcementActive()) return null;

    final enforcementEnd = DateTime(now.year, now.month, now.day, 6, 0);
    return enforcementEnd.difference(now);
  }

  /// Get a human-readable status message
  String getStatusMessage() {
    if (isEnforcementActive()) {
      if (hasValidPermission) {
        return '✅ Night parking active (2-6 AM). Your permit is valid.';
      } else {
        return '🚨 Night parking enforcement active! Move your vehicle or risk a ticket.';
      }
    }

    final timeUntil = timeUntilEnforcement();
    if (timeUntil != null && timeUntil.inHours < 4) {
      if (hasValidPermission) {
        return '🌙 Enforcement starts in ${_formatDuration(timeUntil)}. Your permit is valid.';
      } else {
        return '⚠️ Enforcement starts in ${_formatDuration(timeUntil)}. Do you have permission?';
      }
    }

    if (hasValidPermission) {
      final daysLeft = _permission!.daysUntilExpiration;
      if (daysLeft != null && daysLeft <= 30) {
        return '📋 Your night parking permit expires in $daysLeft days.';
      }
      return '✅ Night parking permit active.';
    }

    return 'Night parking requires permission (2-6 AM).';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Notifications & Reminders
  // ──────────────────────────────────────────────────────────────────────

  /// Notification IDs for night parking reminders
  static const int _eveningReminderId = 800001;
  static const int _expirationReminderId = 800002;
  static const int _weeklyReminderId = 800003;

  /// Schedule all night parking reminders based on user's status
  Future<void> scheduleNightParkingReminders() async {
    if (!_reminderEnabled) return;

    final notificationService = NotificationService.instance;

    // Cancel existing reminders first
    await cancelNightParkingReminders();

    if (hasValidPermission) {
      // User has valid permit - only remind about expiration
      await _scheduleExpirationReminder(notificationService);
    } else {
      // User doesn't have permit - remind about enforcement
      await _scheduleEveningReminder(notificationService);
      await _scheduleWeeklyPermitReminder(notificationService);
    }
  }

  /// Schedule daily evening reminder (9 PM) for users without permits
  Future<void> _scheduleEveningReminder(
    NotificationService notificationService,
  ) async {
    // Schedule for 9 PM tonight (or tomorrow if past 9 PM)
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, 21, 0);
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await notificationService.scheduleLocal(
      title: '🌙 Night Parking Reminder',
      body: 'Enforcement starts at 2 AM. Do you have night parking permission?',
      when: reminderTime,
      id: _eveningReminderId,
    );
  }

  /// Schedule expiration reminder for users with permits
  Future<void> _scheduleExpirationReminder(
    NotificationService notificationService,
  ) async {
    if (_permission?.expirationDate == null) return;

    final expiry = _permission!.expirationDate!;
    final now = DateTime.now();

    // Remind 30 days before expiration
    final thirtyDayReminder = expiry.subtract(const Duration(days: 30));
    if (thirtyDayReminder.isAfter(now)) {
      await notificationService.scheduleLocal(
        title: '📋 Permit Expiring Soon',
        body:
            'Your night parking permit expires in 30 days. Renew to avoid tickets.',
        when: thirtyDayReminder,
        id: _expirationReminderId,
      );
    }

    // Also remind 7 days before
    final sevenDayReminder = expiry.subtract(const Duration(days: 7));
    if (sevenDayReminder.isAfter(now)) {
      await notificationService.scheduleLocal(
        title: '⚠️ Permit Expiring in 7 Days',
        body:
            'Your night parking permit expires soon! Renew now to stay protected.',
        when: sevenDayReminder,
        id: _expirationReminderId + 1,
      );
    }
  }

  /// Schedule weekly reminder to apply for permit
  Future<void> _scheduleWeeklyPermitReminder(
    NotificationService notificationService,
  ) async {
    // Remind on Sunday at 6 PM
    final now = DateTime.now();
    var nextSunday = now;
    while (nextSunday.weekday != DateTime.sunday) {
      nextSunday = nextSunday.add(const Duration(days: 1));
    }
    nextSunday = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      18,
      0,
    );

    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    await notificationService.scheduleLocal(
      title: '🚗 Get Night Parking Permission',
      body:
          'Night parking is the #1 ticket type in Milwaukee. Apply for permission to park overnight.',
      when: nextSunday,
      id: _weeklyReminderId,
    );
  }

  /// Cancel all night parking reminders
  Future<void> cancelNightParkingReminders() async {
    final notificationService = NotificationService.instance;
    await notificationService.cancelScheduled(_eveningReminderId);
    await notificationService.cancelScheduled(_expirationReminderId);
    await notificationService.cancelScheduled(_expirationReminderId + 1);
    await notificationService.cancelScheduled(_weeklyReminderId);
  }

  /// Show an immediate notification about night parking
  Future<void> showImmediateWarning() async {
    await NotificationService.instance.showLocal(
      title: '🚨 Night Parking Enforcement Active',
      body:
          'It\'s between 2-6 AM. Vehicles without permission may be ticketed.',
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  //  Statistics & Insights
  // ──────────────────────────────────────────────────────────────────────

  /// Get statistics about night parking citations (from citation data)
  Map<String, dynamic> getCitationStats() {
    // These are from the citation_hotspots.json data
    return {
      'nightParkingTotal': 158474,
      'nightParkingWrongSide': 58456,
      'nightParkingWinterRestricted': 20597,
      'totalNightRelated': 158474 + 58456 + 20597, // ~237K
      'percentOfAllCitations': 33.0, // Approximately 1/3
      'averageTicketCost': 30.0, // Milwaukee night parking fine
    };
  }

  /// Get the city's night parking information URL
  String get infoUrl => 'https://city.milwaukee.gov/parking/NightParking';

  /// Get the online application URL
  String get applyUrl => applicationUrl;
}
