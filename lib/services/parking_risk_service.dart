import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Risk level enum for type-safe handling
enum RiskLevel {
  low,
  medium,
  high;

  static RiskLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

/// Risk zone data for heatmap display
class RiskZone {
  final String geohash;
  final double lat;
  final double lng;
  final int riskScore;
  final RiskLevel riskLevel;
  final int totalCitations;

  RiskZone({
    required this.geohash,
    required this.lat,
    required this.lng,
    required this.riskScore,
    required this.riskLevel,
    required this.totalCitations,
  });

  factory RiskZone.fromMap(Map<String, dynamic> map) {
    return RiskZone(
      geohash: map['geohash'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      riskScore: (map['riskScore'] as num?)?.toInt() ?? 0,
      riskLevel: RiskLevel.fromString(map['riskLevel']),
      totalCitations: (map['totalCitations'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Location risk result from the backend
class LocationRisk {
  final int riskScore;
  final RiskLevel riskLevel;
  final int riskPercentage;
  final String message;
  final int? currentHour;
  final double? hourlyMultiplier;
  final List<int> peakHours;
  final List<String> topViolations;
  final int totalCitations;

  LocationRisk({
    required this.riskScore,
    required this.riskLevel,
    required this.riskPercentage,
    required this.message,
    this.currentHour,
    this.hourlyMultiplier,
    required this.peakHours,
    required this.topViolations,
    required this.totalCitations,
  });

  factory LocationRisk.fromMap(Map<String, dynamic> map) {
    final hourlyRisk = map['hourlyRisk'] as Map<String, dynamic>?;
    return LocationRisk(
      riskScore: (map['riskScore'] as num?)?.toInt() ?? 0,
      riskLevel: RiskLevel.fromString(map['riskLevel']),
      riskPercentage: (map['riskPercentage'] as num?)?.toInt() ?? 0,
      message: map['message'] ?? '',
      currentHour: hourlyRisk?['currentHour'] as int?,
      hourlyMultiplier: (hourlyRisk?['hourlyMultiplier'] as num?)?.toDouble(),
      peakHours:
          (map['peakHours'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      topViolations:
          (map['topViolations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalCitations: (map['totalCitations'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get a color for the risk level (for UI display)
  int get colorValue {
    switch (riskLevel) {
      case RiskLevel.high:
        return 0xFFE53935; // Red
      case RiskLevel.medium:
        return 0xFFFFA726; // Orange
      case RiskLevel.low:
        return 0xFF66BB6A; // Green
    }
  }
}

/// Service for parking risk data
class ParkingRiskService {
  static final ParkingRiskService _instance = ParkingRiskService._internal();
  factory ParkingRiskService() => _instance;
  ParkingRiskService._internal();

  static ParkingRiskService get instance => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Cache for risk zones (refreshed periodically)
  List<RiskZone>? _cachedZones;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  /// Get risk score for a specific location
  Future<LocationRisk?> getRiskForLocation(
    double latitude,
    double longitude,
  ) async {
    debugPrint('ParkingRiskService: Getting risk for $latitude, $longitude');
    try {
      final callable = _functions.httpsCallable('getRiskForLocation');
      final result = await callable.call({
        'latitude': latitude,
        'longitude': longitude,
      });

      final data = result.data as Map<String, dynamic>?;
      debugPrint('ParkingRiskService: Response data: $data');
      if (data == null || data['success'] != true) {
        debugPrint(
          'ParkingRiskService: getRiskForLocation failed - success=${data?['success']}',
        );
        return null;
      }

      final risk = LocationRisk.fromMap(data);
      debugPrint(
        'ParkingRiskService: Risk level=${risk.riskLevel.name}, score=${risk.riskScore}',
      );
      return risk;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'ParkingRiskService: getRiskForLocation error: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('ParkingRiskService: getRiskForLocation exception: $e');
      return null;
    }
  }

  /// Get all risk zones for heatmap display
  Future<List<RiskZone>> getRiskZones({
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
    bool forceRefresh = false,
  }) async {
    debugPrint(
      'ParkingRiskService: getRiskZones called, forceRefresh=$forceRefresh',
    );
    // Return cached data if available and not expired
    if (!forceRefresh &&
        _cachedZones != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      debugPrint(
        'ParkingRiskService: Returning ${_cachedZones!.length} cached zones',
      );
      return _cachedZones!;
    }

    try {
      final callable = _functions.httpsCallable('getRiskZones');
      final params = <String, dynamic>{};

      if (minLat != null) params['minLat'] = minLat;
      if (maxLat != null) params['maxLat'] = maxLat;
      if (minLng != null) params['minLng'] = minLng;
      if (maxLng != null) params['maxLng'] = maxLng;

      debugPrint(
        'ParkingRiskService: Calling getRiskZones Cloud Function with params: $params',
      );
      final result = await callable.call(params);

      final data = result.data as Map<String, dynamic>?;
      debugPrint(
        'ParkingRiskService: getRiskZones response - success=${data?['success']}, count=${data?['count']}',
      );
      if (data == null || data['success'] != true) {
        debugPrint('ParkingRiskService: getRiskZones failed - data: $data');
        return _cachedZones ?? [];
      }

      final zones =
          (data['zones'] as List<dynamic>?)
              ?.map((z) => RiskZone.fromMap(z as Map<String, dynamic>))
              .toList() ??
          [];

      debugPrint('ParkingRiskService: Loaded ${zones.length} risk zones');

      // Update cache
      _cachedZones = zones;
      _cacheTime = DateTime.now();

      return zones;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'ParkingRiskService: getRiskZones error: ${e.code} - ${e.message}',
      );
      return _cachedZones ?? [];
    } catch (e) {
      debugPrint('ParkingRiskService: getRiskZones exception: $e');
      return _cachedZones ?? [];
    }
  }

  /// Clear cached data
  void clearCache() {
    _cachedZones = null;
    _cacheTime = null;
  }

  /// Get risk message suitable for push notification
  static String formatRiskNotification(LocationRisk risk) {
    final percentage = risk.riskPercentage;
    final level = risk.riskLevel.name.toUpperCase();

    String warning = '';
    if (risk.topViolations.isNotEmpty) {
      final top = risk.topViolations.first.replaceAll('_', ' ');
      warning = ' Watch for: $top.';
    }

    String peakWarning = '';
    if (risk.peakHours.isNotEmpty) {
      final peaks = risk.peakHours.take(3).map((h) => '$h:00').join(', ');
      peakWarning = ' Peak times: $peaks.';
    }

    return '$level RISK ($percentage%): ${risk.message}$warning$peakWarning';
  }
}
