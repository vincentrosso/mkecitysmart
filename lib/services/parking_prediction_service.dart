import 'dart:math';

import 'package:flutter/foundation.dart';

import 'parking_risk_service.dart';

/// Parking prediction service powered by real Milwaukee citation data.
///
/// Uses ParkingRiskService to get actual risk zones and citation patterns
/// from 466K+ Milwaukee parking citations to make accurate predictions.
///
/// Inputs:
/// - day/time (DateTime)
/// - location (lat/lng)
/// - optional event load (0-1)
///
/// Output:
/// - A predicted safety score (0-1) where higher = safer parking
/// - Safest nearby spots based on real citation data
class ParkingPredictionService {
  static final ParkingPredictionService _instance =
      ParkingPredictionService._internal();
  factory ParkingPredictionService() => _instance;
  ParkingPredictionService._internal();

  static ParkingPredictionService get instance => _instance;

  final _riskService = ParkingRiskService.instance;

  /// Cache for location risk
  LocationRisk? _cachedLocationRisk;

  /// Predict parking safety score (0-1) for a location using real citation data.
  /// Higher score = safer parking (lower citation risk).
  Future<ParkingPrediction> predict({
    required DateTime when,
    required double latitude,
    required double longitude,
    double eventLoad = 0.0,
  }) async {
    debugPrint(
      'ParkingPredictionService: Predicting for $latitude, $longitude at ${when.hour}:00',
    );

    // Get real risk data from backend
    final locationRisk = await _riskService.getRiskForLocation(
      latitude,
      longitude,
    );
    _cachedLocationRisk = locationRisk;

    if (locationRisk == null) {
      debugPrint('ParkingPredictionService: No risk data, using fallback');
      return ParkingPrediction(
        latitude: latitude,
        longitude: longitude,
        safetyScore: 0.5,
        riskLevel: RiskLevel.low,
        message: 'No citation data available for this area',
        topViolations: [],
        peakHours: [],
        isPeakHour: false,
      );
    }

    // Convert risk score (0-100) to safety score (0-1)
    // Risk 0 = Safety 1.0, Risk 100 = Safety 0.0
    double safetyScore = 1.0 - (locationRisk.riskScore / 100.0);

    // Apply hourly multiplier if current hour is a peak hour
    final isPeakHour = locationRisk.peakHours.contains(when.hour);
    if (isPeakHour && locationRisk.hourlyMultiplier != null) {
      // Peak hours reduce safety score
      safetyScore = safetyScore / locationRisk.hourlyMultiplier!;
    }

    // Apply event penalty
    if (eventLoad > 0) {
      safetyScore = safetyScore * (1 - eventLoad * 0.3);
    }

    safetyScore = safetyScore.clamp(0.0, 1.0);

    debugPrint(
      'ParkingPredictionService: Safety score=$safetyScore, risk=${locationRisk.riskLevel.name}',
    );

    return ParkingPrediction(
      latitude: latitude,
      longitude: longitude,
      safetyScore: safetyScore,
      riskLevel: locationRisk.riskLevel,
      message: locationRisk.message,
      topViolations: locationRisk.topViolations,
      peakHours: locationRisk.peakHours,
      isPeakHour: isPeakHour,
      totalCitations: locationRisk.totalCitations,
    );
  }

  /// Find the safest parking spots nearby using real citation risk zones.
  /// Returns spots sorted by safety (safest first).
  Future<List<SafeParkingSpot>> findSafestSpotsNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 1.0,
    int maxResults = 5,
  }) async {
    debugPrint(
      'ParkingPredictionService: Finding safest spots near $latitude, $longitude',
    );

    // Get all risk zones
    final zones = await _riskService.getRiskZones();

    if (zones.isEmpty) {
      debugPrint('ParkingPredictionService: No risk zones available');
      return [];
    }

    // Filter zones within radius and calculate distances
    final spotsWithDistance = <_SpotWithDistance>[];

    for (final zone in zones) {
      final distance = _haversineDistance(
        latitude,
        longitude,
        zone.lat,
        zone.lng,
      );

      if (distance <= radiusKm) {
        spotsWithDistance.add(
          _SpotWithDistance(zone: zone, distanceKm: distance),
        );
      }
    }

    if (spotsWithDistance.isEmpty) {
      debugPrint('ParkingPredictionService: No zones within ${radiusKm}km');
      // Return zones sorted by risk anyway for user reference
      final sortedByRisk = List<RiskZone>.from(zones)
        ..sort((a, b) => a.riskScore.compareTo(b.riskScore));

      return sortedByRisk.take(maxResults).map((zone) {
        final distance = _haversineDistance(
          latitude,
          longitude,
          zone.lat,
          zone.lng,
        );
        return SafeParkingSpot(
          latitude: zone.lat,
          longitude: zone.lng,
          safetyScore: 1.0 - (zone.riskScore / 100.0),
          riskLevel: zone.riskLevel,
          distanceKm: distance,
          walkingMinutes: (distance / 0.08).round(), // ~5km/h walking speed
          totalCitations: zone.totalCitations,
        );
      }).toList();
    }

    // Sort by safety (lowest risk first), then by distance
    spotsWithDistance.sort((a, b) {
      // Primary: lower risk score = safer
      final riskCompare = a.zone.riskScore.compareTo(b.zone.riskScore);
      if (riskCompare != 0) return riskCompare;
      // Secondary: closer is better
      return a.distanceKm.compareTo(b.distanceKm);
    });

    debugPrint(
      'ParkingPredictionService: Found ${spotsWithDistance.length} spots within radius',
    );

    return spotsWithDistance.take(maxResults).map((spot) {
      return SafeParkingSpot(
        latitude: spot.zone.lat,
        longitude: spot.zone.lng,
        safetyScore: 1.0 - (spot.zone.riskScore / 100.0),
        riskLevel: spot.zone.riskLevel,
        distanceKm: spot.distanceKm,
        walkingMinutes: (spot.distanceKm / 0.08).round(), // ~5km/h walking
        totalCitations: spot.zone.totalCitations,
      );
    }).toList();
  }

  /// Get violation warnings for the current location.
  List<String> getViolationWarnings() {
    final risk = _cachedLocationRisk;
    if (risk == null || risk.topViolations.isEmpty) return [];

    return risk.topViolations.map((v) {
      // Convert snake_case to readable format
      final readable = v.replaceAll('_', ' ');
      return _getViolationWarning(readable);
    }).toList();
  }

  String _getViolationWarning(String violation) {
    final lower = violation.toLowerCase();
    if (lower.contains('night')) {
      return '⚠️ Night parking restrictions common here';
    }
    if (lower.contains('meter') || lower.contains('overtime')) {
      return '⚠️ Meter enforcement active - set a timer!';
    }
    if (lower.contains('no parking') || lower.contains('prohibited')) {
      return '⚠️ Check for No Parking signs carefully';
    }
    if (lower.contains('snow') || lower.contains('winter')) {
      return '⚠️ Snow emergency rules may apply';
    }
    if (lower.contains('street clean') || lower.contains('sweeping')) {
      return '⚠️ Street cleaning schedule - check posted signs';
    }
    if (lower.contains('fire') || lower.contains('hydrant')) {
      return '⚠️ Stay 15ft from fire hydrants';
    }
    if (lower.contains('handicap') || lower.contains('disabled')) {
      return '⚠️ Accessible parking enforcement strict here';
    }
    if (lower.contains('registration') || lower.contains('expired')) {
      return '⚠️ Registration enforcement active';
    }
    if (lower.contains('24 hour') || lower.contains('24-hour')) {
      return '⚠️ 24-hour parking limit enforced';
    }
    return '⚠️ Watch for: $violation';
  }

  /// Haversine formula for distance between two points in km.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

/// Internal class for sorting spots by distance
class _SpotWithDistance {
  final RiskZone zone;
  final double distanceKm;
  _SpotWithDistance({required this.zone, required this.distanceKm});
}

/// Result from predict() with full context
class ParkingPrediction {
  const ParkingPrediction({
    required this.latitude,
    required this.longitude,
    required this.safetyScore,
    required this.riskLevel,
    required this.message,
    required this.topViolations,
    required this.peakHours,
    required this.isPeakHour,
    this.totalCitations,
  });

  final double latitude;
  final double longitude;
  final double safetyScore; // 0-1, higher = safer
  final RiskLevel riskLevel;
  final String message;
  final List<String> topViolations;
  final List<int> peakHours;
  final bool isPeakHour;
  final int? totalCitations;

  /// User-friendly safety label
  String get safetyLabel {
    if (safetyScore >= 0.7) return 'Safe to park';
    if (safetyScore >= 0.4) return 'Use caution';
    return 'High risk area';
  }

  /// Color value for UI
  int get colorValue {
    if (safetyScore >= 0.7) return 0xFF66BB6A; // Green
    if (safetyScore >= 0.4) return 0xFFFFA726; // Orange
    return 0xFFE53935; // Red
  }
}

/// A safe parking spot recommendation
class SafeParkingSpot {
  const SafeParkingSpot({
    required this.latitude,
    required this.longitude,
    required this.safetyScore,
    required this.riskLevel,
    required this.distanceKm,
    required this.walkingMinutes,
    this.totalCitations,
  });

  final double latitude;
  final double longitude;
  final double safetyScore; // 0-1, higher = safer
  final RiskLevel riskLevel;
  final double distanceKm;
  final int walkingMinutes;
  final int? totalCitations;

  /// User-friendly label
  String get label {
    if (safetyScore >= 0.8) return '✅ Very Safe';
    if (safetyScore >= 0.6) return '🟢 Safe';
    if (safetyScore >= 0.4) return '🟡 Moderate';
    return '🔴 Risky';
  }

  /// Distance label
  String get distanceLabel {
    if (distanceKm < 0.1) return 'Here';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()}m away';
    return '${distanceKm.toStringAsFixed(1)}km away';
  }
}

/// Legacy class for backward compatibility
class PredictedPoint {
  const PredictedPoint({
    required this.latitude,
    required this.longitude,
    required this.score,
  });

  final double latitude;
  final double longitude;
  final double score;
}
