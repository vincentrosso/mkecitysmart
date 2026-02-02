import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to load and query citation hotspot data
/// Data is pre-computed from 466K Milwaukee parking citations
class CitationHotspotService {
  CitationHotspotService._();
  static final CitationHotspotService instance = CitationHotspotService._();

  Map<String, dynamic>? _data;
  bool _initialized = false;

  // Computed risk multipliers
  late Map<int, double> _hourRiskMultipliers;
  late Map<int, double> _dayRiskMultipliers;
  late Map<String, double> _dayHourRiskMultipliers;

  /// Initialize and load hotspot data from assets
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/citation_hotspots.json',
      );
      _data = json.decode(jsonString) as Map<String, dynamic>;

      _computeRiskMultipliers();
      _initialized = true;
      debugPrint(
        '[CitationHotspot] Loaded ${_data!['totalCitations']} citation patterns',
      );
    } catch (e) {
      debugPrint('[CitationHotspot] Error loading data: $e');
      _useDefaultData();
    }
  }

  void _computeRiskMultipliers() {
    final total = _data!['totalCitations'] as int;

    // Hour multipliers (24 hours)
    final byHour = _data!['byHour'] as Map<String, dynamic>;
    final avgHour = total / 24;
    _hourRiskMultipliers = {};
    for (int h = 0; h < 24; h++) {
      final count = (byHour['$h'] as int?) ?? 0;
      _hourRiskMultipliers[h] = count / avgHour;
    }

    // Day of week multipliers (0=Sun, 6=Sat)
    final byDay = _data!['byDayOfWeek'] as Map<String, dynamic>;
    final avgDay = total / 7;
    _dayRiskMultipliers = {};
    for (int d = 0; d < 7; d++) {
      final count = (byDay['$d'] as int?) ?? 0;
      _dayRiskMultipliers[d] = count / avgDay;
    }

    // Combined day-hour multipliers
    final byDayHour = _data!['byDayAndHour'] as Map<String, dynamic>;
    final avgDayHour = total / (7 * 24);
    _dayHourRiskMultipliers = {};
    byDayHour.forEach((key, value) {
      _dayHourRiskMultipliers[key] = (value as int) / avgDayHour;
    });
  }

  void _useDefaultData() {
    _initialized = true;
    // Default risk multipliers based on typical patterns
    _hourRiskMultipliers = {
      0: 0.1,
      1: 0.3,
      2: 3.0,
      3: 3.5,
      4: 3.4,
      5: 3.5, // Night parking enforcement
      6: 0.4, 7: 0.4, 8: 0.2, 9: 0.5, 10: 0.6, 11: 0.9,
      12: 0.9, 13: 0.9, 14: 0.9, 15: 0.5, 16: 0.4, 17: 1.0,
      18: 0.6, 19: 0.6, 20: 0.6, 21: 0.5, 22: 0.4, 23: 0.3,
    };
    _dayRiskMultipliers = {
      0: 0.25, // Sunday - minimal
      1: 0.66, // Monday
      2: 1.45, // Tuesday - highest
      3: 1.50, // Wednesday - highest
      4: 1.35, // Thursday
      5: 0.98, // Friday
      6: 0.80, // Saturday
    };
    _dayHourRiskMultipliers = {};
  }

  /// Get risk multiplier for current time
  double getCurrentRiskMultiplier() {
    final now = DateTime.now();
    return getRiskMultiplier(now.weekday % 7, now.hour);
  }

  /// Get risk multiplier for specific day and hour
  /// dayOfWeek: 0=Sunday, 6=Saturday (matches JS convention)
  double getRiskMultiplier(int dayOfWeek, int hour) {
    if (!_initialized) return 1.0;

    // Try combined day-hour first (most accurate)
    final dayHourKey = '$dayOfWeek-$hour';
    if (_dayHourRiskMultipliers.containsKey(dayHourKey)) {
      return _dayHourRiskMultipliers[dayHourKey]!;
    }

    // Fall back to multiplying day and hour factors
    final dayMultiplier = _dayRiskMultipliers[dayOfWeek] ?? 1.0;
    final hourMultiplier = _hourRiskMultipliers[hour] ?? 1.0;

    return (dayMultiplier * hourMultiplier).clamp(0.1, 5.0);
  }

  /// Get risk level as a string
  String getRiskLevel(double multiplier) {
    if (multiplier >= 2.5) return 'Very High';
    if (multiplier >= 1.5) return 'High';
    if (multiplier >= 1.0) return 'Moderate';
    if (multiplier >= 0.5) return 'Low';
    return 'Very Low';
  }

  /// Get color for risk level
  int getRiskColor(double multiplier) {
    if (multiplier >= 2.5) return 0xFFE53935; // Red
    if (multiplier >= 1.5) return 0xFFFF9800; // Orange
    if (multiplier >= 1.0) return 0xFFFFC107; // Amber
    if (multiplier >= 0.5) return 0xFF8BC34A; // Light green
    return 0xFF4CAF50; // Green
  }

  /// Get top violation types
  List<String> getTopViolations({int limit = 5}) {
    if (_data == null) {
      return [
        'NIGHT PARKING',
        'METER PARKING VIOLATION',
        'NIGHT PARKING - WRONG SIDE',
        'PARKING PROHIBITED BY OFFICIAL SIGN',
        'FAILURE TO DISPLAY CURRENT REGISTRATION',
      ];
    }

    final violations = _data!['topViolations'] as Map<String, dynamic>;
    return violations.keys.take(limit).toList();
  }

  /// Get top enforcement streets
  List<String> getTopStreets({int limit = 10}) {
    if (_data == null) {
      return ['FARWELL', 'WELLS', '15TH', 'WISCONSIN', '9TH'];
    }

    final streets = _data!['topStreets'] as Map<String, dynamic>;
    return streets.keys.take(limit).toList();
  }

  /// Get peak enforcement hours
  List<Map<String, dynamic>> getPeakHours() {
    if (_data == null) {
      return [
        {'hour': 3, 'label': '3 AM', 'riskMultiplier': 3.5},
        {'hour': 5, 'label': '5 AM', 'riskMultiplier': 3.5},
        {'hour': 4, 'label': '4 AM', 'riskMultiplier': 3.4},
        {'hour': 2, 'label': '2 AM', 'riskMultiplier': 3.0},
      ];
    }

    final peaks = _data!['peakHours'] as List<dynamic>;
    return peaks
        .map(
          (p) => {
            'hour': p['hour'] as int,
            'label': _formatHour(p['hour'] as int),
            'riskMultiplier': double.parse(p['riskMultiplier'].toString()),
          },
        )
        .toList();
  }

  /// Get peak enforcement days
  List<Map<String, dynamic>> getPeakDays() {
    if (_data == null) {
      return [
        {'day': 'Wednesday', 'dayIndex': 3, 'riskMultiplier': 1.50},
        {'day': 'Tuesday', 'dayIndex': 2, 'riskMultiplier': 1.45},
        {'day': 'Thursday', 'dayIndex': 4, 'riskMultiplier': 1.35},
      ];
    }

    final peaks = _data!['peakDays'] as List<dynamic>;
    return peaks
        .map(
          (p) => {
            'day': p['day'] as String,
            'dayIndex': p['dayIndex'] as int,
            'riskMultiplier': double.parse(p['riskMultiplier'].toString()),
          },
        )
        .toList();
  }

  /// Get human-readable enforcement summary for current time
  String getEnforcementSummary() {
    final now = DateTime.now();
    final multiplier = getCurrentRiskMultiplier();
    final level = getRiskLevel(multiplier);

    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final dayName = days[now.weekday % 7];
    final hourStr = _formatHour(now.hour);

    if (multiplier >= 2.5) {
      return '🚨 $level enforcement period! $dayName at $hourStr is peak citation time.';
    } else if (multiplier >= 1.5) {
      return '⚠️ $level enforcement. Be extra careful parking right now.';
    } else if (multiplier >= 1.0) {
      return 'Moderate enforcement expected. Check signs carefully.';
    } else {
      return '✅ $level enforcement period. Still follow all rules!';
    }
  }

  /// Check if current time is a night parking enforcement window
  bool isNightParkingWindow() {
    final hour = DateTime.now().hour;
    return hour >= 2 && hour <= 6;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  /// Total citations in dataset
  int get totalCitations => _data?['totalCitations'] as int? ?? 0;

  /// Data generation date
  String? get dataDate => _data?['generated'] as String?;
}
