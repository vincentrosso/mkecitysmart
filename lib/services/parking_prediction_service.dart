import 'dart:math';

import 'package:flutter/material.dart';

import '../models/parking_report.dart';
import 'parking_crowdsource_service.dart';
import 'parking_risk_service.dart';
import 'zone_aggregation_service.dart';

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
  final _crowdsourceService = ParkingCrowdsourceService.instance;
  final _zoneService = ZoneAggregationService.instance;

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

    // Incorporate real-time crowdsource data
    try {
      final nearbyReports = await _crowdsourceService.getNearbyReports(
        latitude: latitude,
        longitude: longitude,
        geohashPrecision: 6, // ~1.2km radius for prediction
      );
      if (nearbyReports.isNotEmpty) {
        final availability = ParkingCrowdsourceService.aggregateAvailability(
          nearbyReports,
        );
        // Crowdsource availability shifts the safety score by up to ±15%
        // Score > 0.5 means users report spots available → boost safety
        // Score < 0.5 means users report spots taken → reduce safety
        final crowdsourceDelta = (availability.availabilityScore - 0.5) * 0.3;
        safetyScore += crowdsourceDelta;
        // Enforcement penalty from crowdsource
        if (availability.hasEnforcement) {
          safetyScore -= 0.1;
        }
        debugPrint(
          'ParkingPredictionService: Crowdsource delta=$crowdsourceDelta '
          '(${nearbyReports.length} reports, enforcement=${availability.hasEnforcement})',
        );
      }
    } catch (e) {
      // Crowdsource is optional — degrade gracefully
      debugPrint('ParkingPredictionService: Crowdsource unavailable: $e');
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

  // ---------------------------------------------------------------------------
  // Recommended Open Spot (combines all data sources)
  // ---------------------------------------------------------------------------

  /// Find the best open parking spot nearby by combining:
  /// 1. Real-time crowdsource reports (leavingSpot / spotAvailable) — exact GPS
  /// 2. Zone-level availability (CrowdsourceZone.estimatedOpenSpots) — ~150m areas
  /// 3. Zone historical patterns (hourlyAvgOpenSpots) — time-of-day prediction
  /// 4. Citation risk zones — safety scoring
  ///
  /// Results are ranked by: data freshness → availability → safety → distance.
  ///
  /// When [destinationLatitude] and [destinationLongitude] are provided, spots
  /// are searched near the destination instead of the user's current location.
  /// [maxDistanceFromUserKm] caps how far from the user the result can be
  /// (prevents suggesting spots 30 min away from where the user currently is).
  Future<List<RecommendedSpot>> findBestOpenSpots({
    required double latitude,
    required double longitude,
    double radiusKm = 1.5,
    int maxResults = 5,
    double? destinationLatitude,
    double? destinationLongitude,
    double maxDistanceFromUserKm = 8.0, // ~10 min drive
  }) async {
    // If a destination is provided, search near the destination
    final searchLat = destinationLatitude ?? latitude;
    final searchLng = destinationLongitude ?? longitude;
    final hasDestination = destinationLatitude != null &&
        destinationLongitude != null;

    debugPrint(
      'ParkingPredictionService: Finding best open spots near $searchLat, $searchLng'
      '${hasDestination ? ' (destination-aware, user at $latitude, $longitude)' : ''}',
    );

    final now = DateTime.now();
    final candidates = <RecommendedSpot>[];

    // ── Layer 1: Real-time crowdsource reports (highest priority) ─────────
    try {
      final nearbyReports = await _crowdsourceService.getNearbyReports(
        latitude: searchLat,
        longitude: searchLng,
        geohashPrecision: 5, // ~4.9km to cast a wider net
      );

      for (final report in nearbyReports) {
        if (!report.reportType.isPositiveSignal) continue;
        if (!report.isStillRelevant) continue;

        final distFromSearch = _haversineDistance(
          searchLat,
          searchLng,
          report.latitude,
          report.longitude,
        );
        if (distFromSearch > radiusKm) continue;

        // When destination-aware, also cap distance from user's location
        if (hasDestination) {
          final distFromUser = _haversineDistance(
            latitude,
            longitude,
            report.latitude,
            report.longitude,
          );
          if (distFromUser > maxDistanceFromUserKm) continue;
        }

        final dist = distFromSearch;

        final ageMinutes = now.difference(report.timestamp).inMinutes;
        // Freshness score: 1.0 at 0 min, decays toward 0 at TTL
        final ttl = report.reportType.ttlMinutes;
        final freshness = ((ttl - ageMinutes) / ttl).clamp(0.0, 1.0);

        String reason;
        if (report.reportType == ReportType.leavingSpot) {
          if (ageMinutes <= 1) {
            reason = 'Someone is leaving this spot now';
          } else {
            reason = 'Spot opened $ageMinutes min ago';
          }
        } else {
          reason = 'Open spot reported $ageMinutes min ago';
        }

        candidates.add(
          RecommendedSpot(
            latitude: report.latitude,
            longitude: report.longitude,
            distanceKm: dist,
            walkingMinutes: (dist / 0.08).round(),
            reason: reason,
            source: SpotSource.crowdsourceReport,
            confidence: (0.7 + 0.3 * freshness).clamp(0.0, 1.0),
            safetyScore: null, // filled in below
            freshness: freshness,
            reportType: report.reportType,
            reportAge: Duration(minutes: ageMinutes),
          ),
        );
      }
    } catch (e) {
      debugPrint('ParkingPredictionService: Crowdsource layer failed: $e');
    }

    // ── Layer 2: Zone-level availability ──────────────────────────────────
    try {
      final zones = await _zoneService.getNearbyZones(
        latitude: searchLat,
        longitude: searchLng,
      );

      for (final zone in zones) {
        if (zone.enforcementActive ||
            zone.sweepingActive ||
            zone.parkingBlocked) {
          continue;
        }

        final dist = _haversineDistance(
          searchLat,
          searchLng,
          zone.latitude,
          zone.longitude,
        );
        if (dist > radiusKm) continue;

        // When destination-aware, also cap distance from user's location
        if (hasDestination) {
          final distFromUser = _haversineDistance(
            latitude,
            longitude,
            zone.latitude,
            zone.longitude,
          );
          if (distFromUser > maxDistanceFromUserKm) continue;
        }

        // Check live open spots
        if (zone.estimatedOpenSpots > 0) {
          final spotsText = zone.estimatedOpenSpots == 1
              ? '1 spot'
              : '${zone.estimatedOpenSpots} spots';
          final nameText = zone.name != null ? ' near ${zone.name}' : '';

          candidates.add(
            RecommendedSpot(
              latitude: zone.latitude,
              longitude: zone.longitude,
              distanceKm: dist,
              walkingMinutes: (dist / 0.08).round(),
              reason: '~$spotsText reported open$nameText',
              source: SpotSource.zoneAvailability,
              confidence: zone.confidenceScore.clamp(0.0, 1.0),
              safetyScore: null,
              freshness: 0.5,
              estimatedOpenSpots: zone.estimatedOpenSpots,
            ),
          );
          continue;
        }

        // Check historical hourly pattern as fallback
        final hourAvg = zone.hourlyAvgOpenSpots[now.hour];
        if (hourAvg != null && hourAvg >= 1.0) {
          final nameText = zone.name != null ? ' near ${zone.name}' : '';

          candidates.add(
            RecommendedSpot(
              latitude: zone.latitude,
              longitude: zone.longitude,
              distanceKm: dist,
              walkingMinutes: (dist / 0.08).round(),
              reason:
                  'Usually ~${hourAvg.round()} spots open at this hour$nameText',
              source: SpotSource.historicalPattern,
              confidence: (zone.confidenceScore * 0.6).clamp(0.0, 1.0),
              safetyScore: null,
              freshness: 0.2,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ParkingPredictionService: Zone layer failed: $e');
    }

    // ── Layer 3: Safest risk zones as fallback ────────────────────────────
    if (candidates.length < maxResults) {
      try {
        final safeSpots = await findSafestSpotsNearby(
          latitude: searchLat,
          longitude: searchLng,
          radiusKm: radiusKm,
          maxResults: maxResults,
        );

        for (final spot in safeSpots) {
          // When destination-aware, cap distance from user
          if (hasDestination) {
            final distFromUser = _haversineDistance(
              latitude,
              longitude,
              spot.latitude,
              spot.longitude,
            );
            if (distFromUser > maxDistanceFromUserKm) continue;
          }

          // Skip if we already have a candidate very close to this location
          final isDuplicate = candidates.any(
            (c) =>
                _haversineDistance(
                  c.latitude,
                  c.longitude,
                  spot.latitude,
                  spot.longitude,
                ) <
                0.05,
          );
          if (isDuplicate) continue;

          candidates.add(
            RecommendedSpot(
              latitude: spot.latitude,
              longitude: spot.longitude,
              distanceKm: spot.distanceKm,
              walkingMinutes: spot.walkingMinutes,
              reason:
                  '${(spot.safetyScore * 100).round()}% safe zone — low citation risk',
              source: SpotSource.riskZone,
              confidence: 0.3,
              safetyScore: spot.safetyScore,
              freshness: 0.1,
            ),
          );
        }
      } catch (e) {
        debugPrint('ParkingPredictionService: Risk zone layer failed: $e');
      }
    }

    // ── Enrich candidates with safety scores where missing ───────────────
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i].safetyScore == null) {
        try {
          final pred = await predict(
            when: now,
            latitude: candidates[i].latitude,
            longitude: candidates[i].longitude,
          );
          candidates[i] = candidates[i].withSafetyScore(pred.safetyScore);
        } catch (_) {
          candidates[i] = candidates[i].withSafetyScore(0.5);
        }
      }
    }

    // ── Rank: source priority → freshness → safety → distance ────────────
    candidates.sort((a, b) {
      // Primary: source priority (crowdsource > zone > historical > risk)
      final srcCompare = a.source.index.compareTo(b.source.index);
      if (srcCompare != 0) return srcCompare;
      // Secondary: fresher is better
      final freshCompare = b.freshness.compareTo(a.freshness);
      if (freshCompare != 0) return freshCompare;
      // Tertiary: safer is better
      final safeCompare = (b.safetyScore ?? 0.5).compareTo(
        a.safetyScore ?? 0.5,
      );
      if (safeCompare != 0) return safeCompare;
      // Quaternary: closer is better
      return a.distanceKm.compareTo(b.distanceKm);
    });

    // De-duplicate close spots (within 50m)
    final deduped = <RecommendedSpot>[];
    for (final c in candidates) {
      final tooClose = deduped.any(
        (d) =>
            _haversineDistance(
              c.latitude,
              c.longitude,
              d.latitude,
              d.longitude,
            ) <
            0.05,
      );
      if (!tooClose) deduped.add(c);
      if (deduped.length >= maxResults) break;
    }

    debugPrint(
      'ParkingPredictionService: Found ${deduped.length} recommended spots '
      '(${candidates.length} candidates before dedup)',
    );

    return deduped;
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

// ---------------------------------------------------------------------------
// Recommended Spot (composite result from all data sources)
// ---------------------------------------------------------------------------

/// How this spot was discovered — ordered by priority (best first).
enum SpotSource {
  /// Exact GPS from a leavingSpot/spotAvailable crowdsource report.
  crowdsourceReport,

  /// Zone with estimatedOpenSpots > 0 from live aggregation.
  zoneAvailability,

  /// Zone with good historical hourlyAvgOpenSpots at this hour.
  historicalPattern,

  /// Low-citation risk zone (fallback when no crowdsource data).
  riskZone,
}

extension SpotSourceExt on SpotSource {
  String get label {
    switch (this) {
      case SpotSource.crowdsourceReport:
        return 'Live Report';
      case SpotSource.zoneAvailability:
        return 'Zone Data';
      case SpotSource.historicalPattern:
        return 'Historical';
      case SpotSource.riskZone:
        return 'Safe Zone';
    }
  }

  /// Icon for display.
  IconData get icon {
    switch (this) {
      case SpotSource.crowdsourceReport:
        return Icons.person_pin_circle;
      case SpotSource.zoneAvailability:
        return Icons.location_on;
      case SpotSource.historicalPattern:
        return Icons.schedule;
      case SpotSource.riskZone:
        return Icons.verified_user;
    }
  }
}

/// A recommended parking spot combining all prediction signals.
class RecommendedSpot {
  RecommendedSpot({
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.walkingMinutes,
    required this.reason,
    required this.source,
    required this.confidence,
    required this.freshness,
    this.safetyScore,
    this.reportType,
    this.reportAge,
    this.estimatedOpenSpots,
  });

  final double latitude;
  final double longitude;
  final double distanceKm;
  final int walkingMinutes;

  /// Human-readable explanation (e.g. "Spot opened 3 min ago").
  final String reason;

  /// How this spot was discovered.
  final SpotSource source;

  /// Confidence in this recommendation (0.0–1.0).
  final double confidence;

  /// Safety score from citation risk (0.0–1.0, higher = safer). May be null
  /// until enriched.
  final double? safetyScore;

  /// Freshness of the signal (1.0 = just now, 0.0 = stale).
  final double freshness;

  /// Original report type if source is crowdsourceReport.
  final ReportType? reportType;

  /// Age of the report if source is crowdsourceReport.
  final Duration? reportAge;

  /// Number of estimated open spots if source is zoneAvailability.
  final int? estimatedOpenSpots;

  /// Create a copy with the safety score filled in.
  RecommendedSpot withSafetyScore(double score) => RecommendedSpot(
    latitude: latitude,
    longitude: longitude,
    distanceKm: distanceKm,
    walkingMinutes: walkingMinutes,
    reason: reason,
    source: source,
    confidence: confidence,
    safetyScore: score,
    freshness: freshness,
    reportType: reportType,
    reportAge: reportAge,
    estimatedOpenSpots: estimatedOpenSpots,
  );

  /// Distance label for display.
  String get distanceLabel {
    if (distanceKm < 0.1) return 'Here';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()}m away';
    return '${distanceKm.toStringAsFixed(1)}km away';
  }

  /// Color value based on source type.
  int get colorValue {
    switch (source) {
      case SpotSource.crowdsourceReport:
        return 0xFF66BB6A; // Green — live data
      case SpotSource.zoneAvailability:
        return 0xFF42A5F5; // Blue — zone data
      case SpotSource.historicalPattern:
        return 0xFFFFA726; // Orange — historical
      case SpotSource.riskZone:
        return 0xFF78909C; // Gray-blue — risk-based fallback
    }
  }

  /// Badge text for the source.
  String get sourceBadge => source.label;
}
