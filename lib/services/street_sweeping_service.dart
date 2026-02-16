import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result from querying ArcGIS for street sweeping route
class SweepingRouteInfo {
  const SweepingRouteInfo({required this.broomCode});

  /// The BROOM route code (e.g., "S-13", "N-15", "C-8")
  final String broomCode;
}

/// User-entered schedule configuration for a location
class UserSweepingSchedule {
  const UserSweepingSchedule({
    required this.broomCode,
    required this.sweepDay,
    required this.weekPattern,
    this.seasonStart = 4,
    this.seasonEnd = 11,
  });

  final String broomCode;

  /// Day of week: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
  final int sweepDay;

  /// Which weeks: [1,3] = 1st and 3rd week of month; [2,4] = 2nd and 4th
  final List<int> weekPattern;

  /// Season start month (inclusive), default April
  final int seasonStart;

  /// Season end month (inclusive), default November
  final int seasonEnd;

  /// Create from JSON (stored in UserProfile)
  factory UserSweepingSchedule.fromJson(Map<String, dynamic> json) {
    return UserSweepingSchedule(
      broomCode: json['broomCode'] as String,
      sweepDay: json['sweepDay'] as int,
      weekPattern: (json['weekPattern'] as List<dynamic>).cast<int>(),
      seasonStart: json['seasonStart'] as int? ?? 4,
      seasonEnd: json['seasonEnd'] as int? ?? 11,
    );
  }

  Map<String, dynamic> toJson() => {
    'broomCode': broomCode,
    'sweepDay': sweepDay,
    'weekPattern': weekPattern,
    'seasonStart': seasonStart,
    'seasonEnd': seasonEnd,
  };

  /// Human-readable day name
  String get dayName {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return sweepDay >= 1 && sweepDay <= 5 ? days[sweepDay] : 'Unknown';
  }

  /// Human-readable week pattern
  String get weekPatternName {
    if (weekPattern.contains(1) && weekPattern.contains(3)) {
      return '1st & 3rd weeks';
    } else if (weekPattern.contains(2) && weekPattern.contains(4)) {
      return '2nd & 4th weeks';
    }
    return weekPattern.map((w) => '$w${_ordinalSuffix(w)}').join(' & ');
  }

  String _ordinalSuffix(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

/// Service for fetching street sweeping routes from Milwaukee ArcGIS
///
/// Route lookup uses the real Milwaukee DPW_Sanitation MapServer layer 19.
/// Schedule data must be entered by the user based on posted street signs,
/// as the city does not publish schedule information via API.
class StreetSweepingService {
  StreetSweepingService({
    this.baseUrl =
        'https://milwaukeemaps.milwaukee.gov/arcgis/rest/services/DPW/DPW_Sanitation/MapServer/19',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Fetch the BROOM route code for a given lat/lng point.
  /// Returns null if location is outside Milwaukee sweeping routes.
  Future<SweepingRouteInfo?> fetchRouteByPoint({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/query').replace(
      queryParameters: {
        'f': 'json',
        'geometry': '$lng,$lat',
        'geometryType': 'esriGeometryPoint',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields': 'BROOM',
        'returnGeometry': 'false',
        'outSR': '4326',
        'resultRecordCount': '1',
      },
    );

    try {
      final resp = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? const [];
      if (features.isEmpty) return null;

      final attrs = features.first['attributes'] as Map<String, dynamic>? ?? {};
      final broom = (attrs['BROOM'] as String?)?.trim() ?? '';
      if (broom.isEmpty) return null;

      return SweepingRouteInfo(broomCode: broom);
    } catch (_) {
      return null;
    }
  }

  /// Calculate the next sweep date based on user-entered schedule.
  /// Returns null if outside sweeping season and next season is too far.
  DateTime? computeNextSweepDate(
    UserSweepingSchedule schedule, {
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();

    // If outside sweeping season, return first sweep of next season
    if (now.month < schedule.seasonStart) {
      return _findFirstSweepOfSeason(schedule, now.year);
    }
    if (now.month > schedule.seasonEnd) {
      return _findFirstSweepOfSeason(schedule, now.year + 1);
    }

    // Within season: find next matching weekday in matching week pattern
    var candidate = now;
    for (var i = 0; i < 60; i++) {
      candidate = candidate.add(const Duration(days: 1));

      // Check we're still in season
      if (candidate.month > schedule.seasonEnd) {
        return _findFirstSweepOfSeason(schedule, candidate.year + 1);
      }

      // Check weekday matches (DateTime.weekday: 1=Mon...7=Sun)
      if (candidate.weekday != schedule.sweepDay) continue;

      // Check week-of-month matches pattern
      final weekOfMonth = ((candidate.day - 1) ~/ 7) + 1;
      if (schedule.weekPattern.contains(weekOfMonth)) {
        // Return 8 AM on sweep day
        return DateTime(candidate.year, candidate.month, candidate.day, 8, 0);
      }
    }

    return null;
  }

  DateTime? _findFirstSweepOfSeason(UserSweepingSchedule schedule, int year) {
    // Start from first day of season start month
    var candidate = DateTime(year, schedule.seasonStart, 1);
    for (var i = 0; i < 45; i++) {
      if (candidate.weekday == schedule.sweepDay) {
        final weekOfMonth = ((candidate.day - 1) ~/ 7) + 1;
        if (schedule.weekPattern.contains(weekOfMonth)) {
          return DateTime(candidate.year, candidate.month, candidate.day, 8, 0);
        }
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return null;
  }

  /// Get all upcoming sweep dates for a user-entered schedule.
  List<DateTime> getUpcomingSweepDates(
    UserSweepingSchedule schedule, {
    int maxDates = 10,
  }) {
    final dates = <DateTime>[];
    DateTime? current = computeNextSweepDate(schedule);

    while (current != null && dates.length < maxDates) {
      dates.add(current);
      // Find next after this one
      current = computeNextSweepDate(schedule, from: current);
    }

    return dates;
  }

  /// Check if sweeping season is currently active.
  bool isSeasonActive({DateTime? now}) {
    final date = now ?? DateTime.now();
    return date.month >= 4 && date.month <= 11;
  }
}
