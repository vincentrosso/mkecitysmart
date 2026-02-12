import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/crowdsource_zone.dart';
import '../models/parking_report.dart';
import 'parking_crowdsource_service.dart';

/// Service that manages zone-level aggregation of crowdsource parking data.
///
/// When a user submits a report, this service:
/// 1. Determines which [CrowdsourceZone] the report falls in.
/// 2. Creates or updates that zone's aggregate counters in Firestore.
/// 3. Records hourly/daily pattern data for long-term intelligence.
///
/// Zone documents live in `crowdsourceZones/{region}_{geohash}` and are
/// region-partitioned from day one so the architecture scales to any city.
///
/// Default region: `wi/milwaukee` (Milwaukee County, WI).
class ZoneAggregationService {
  ZoneAggregationService._();
  static final ZoneAggregationService instance = ZoneAggregationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firestore collection for zone aggregates.
  static const String _collection = 'crowdsourceZones';

  /// Default region for Milwaukee County.
  static const String defaultRegion = 'wi/milwaukee';

  /// Geohash precision for zone documents (7 ≈ 150m × 150m).
  static const int zonePrecision = 7;

  /// Geohash precision for nearby-zone queries (5 ≈ 4.9km × 4.9km).
  static const int queryPrecision = 5;

  // ---------------------------------------------------------------------------
  // Zone document ID helpers
  // ---------------------------------------------------------------------------

  /// Build a Firestore doc ID from region + geohash.
  /// e.g. "wi/milwaukee" + "dp5dtpp" → "wi_milwaukee_dp5dtpp"
  static String zoneDocId(String region, String geohash) {
    return '${region.replaceAll('/', '_')}_$geohash';
  }

  /// Extract the region from a zone doc ID.
  /// e.g. "wi_milwaukee_dp5dtpp" → "wi/milwaukee"
  static String regionFromDocId(String docId) {
    // Last segment is the geohash; everything before is the region with _ → /
    final parts = docId.split('_');
    if (parts.length < 3) return defaultRegion;
    // The geohash is the last part; region parts are everything before it.
    final regionParts = parts.sublist(0, parts.length - 1);
    return regionParts.join('/');
  }

  // ---------------------------------------------------------------------------
  // Update zone on new report
  // ---------------------------------------------------------------------------

  /// Called after a new [ParkingReport] is submitted. Updates (or creates) the
  /// corresponding zone document with live aggregate counters.
  ///
  /// Uses Firestore transactions for atomic counter updates.
  Future<void> updateZoneForReport(
    ParkingReport report, {
    String region = defaultRegion,
  }) async {
    final geohash = report.geohash.length >= zonePrecision
        ? report.geohash.substring(0, zonePrecision)
        : report.geohash;
    final docId = zoneDocId(region, geohash);
    final docRef = _firestore.collection(_collection).doc(docId);

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        final now = DateTime.now();

        if (!snapshot.exists) {
          // Create new zone document
          final zone = CrowdsourceZone(
            id: docId,
            region: region,
            geohash: geohash,
            latitude: report.latitude,
            longitude: report.longitude,
            totalReportsAllTime: 1,
            activeReports: 1,
            estimatedOpenSpots: report.reportType.isPositiveSignal ? 1 : 0,
            activeAvailableSignals: report.reportType.isPositiveSignal ? 1 : 0,
            activeTakenSignals: _isTakenSignal(report.reportType) ? 1 : 0,
            enforcementActive: _isEnforcementSignal(report.reportType),
            sweepingActive:
                report.reportType == ReportType.streetSweepingActive,
            parkingBlocked: report.reportType == ReportType.parkingBlocked,
            confidenceScore: 0.1, // Low confidence with just 1 report
            uniqueReporters: 1,
            lastUpdated: now,
            createdAt: now,
          );
          tx.set(docRef, zone.toFirestore());
        } else {
          // Incremental update
          final data = snapshot.data()!;
          final currentAvailable =
              (data['activeAvailableSignals'] as num?)?.toInt() ?? 0;
          final currentTaken =
              (data['activeTakenSignals'] as num?)?.toInt() ?? 0;

          final newAvailable =
              currentAvailable + (report.reportType.isPositiveSignal ? 1 : 0);
          final newTaken =
              currentTaken + (_isTakenSignal(report.reportType) ? 1 : 0);
          final estimatedOpen = max(0, newAvailable - newTaken);

          final totalAllTime =
              ((data['totalReportsAllTime'] as num?)?.toInt() ?? 0) + 1;
          final activeCount =
              ((data['activeReports'] as num?)?.toInt() ?? 0) + 1;
          final reporters = (data['uniqueReporters'] as num?)?.toInt() ?? 0;

          // Confidence grows with report volume (log curve, caps at 1.0)
          final confidence = min(
            1.0,
            0.1 + 0.15 * log(totalAllTime.toDouble()),
          );

          tx.update(docRef, {
            'totalReportsAllTime': totalAllTime,
            'activeReports': activeCount,
            'estimatedOpenSpots': estimatedOpen,
            'activeAvailableSignals': newAvailable,
            'activeTakenSignals': newTaken,
            'enforcementActive':
                (data['enforcementActive'] as bool? ?? false) ||
                _isEnforcementSignal(report.reportType),
            'sweepingActive':
                (data['sweepingActive'] as bool? ?? false) ||
                report.reportType == ReportType.streetSweepingActive,
            'parkingBlocked':
                (data['parkingBlocked'] as bool? ?? false) ||
                report.reportType == ReportType.parkingBlocked,
            'confidenceScore': confidence,
            'uniqueReporters': reporters + 1, // Approximate; exact needs Set
            'lastUpdated': Timestamp.fromDate(now),
          });
        }
      });

      debugPrint(
        '[ZoneAggregation] Updated zone $docId for '
        '${report.reportType.displayName}',
      );
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to update zone: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Recalculate zone from raw reports
  // ---------------------------------------------------------------------------

  /// Fully recalculate a zone's aggregate data from a list of active reports.
  ///
  /// Useful when reports expire and zone counters need to be refreshed.
  /// Call periodically or when stale data is detected.
  Future<void> recalculateZone({
    required String geohash,
    required List<ParkingReport> activeReports,
    String region = defaultRegion,
  }) async {
    final docId = zoneDocId(region, geohash);
    final docRef = _firestore.collection(_collection).doc(docId);
    final now = DateTime.now();

    int available = 0;
    int taken = 0;
    int enforcement = 0;
    bool sweeping = false;
    bool blocked = false;
    final reporters = <String>{};

    for (final r in activeReports) {
      if (!r.isStillRelevant) continue;
      reporters.add(r.userId);

      if (r.reportType.isPositiveSignal) {
        available++;
      } else if (_isTakenSignal(r.reportType)) {
        taken++;
      }
      if (_isEnforcementSignal(r.reportType)) enforcement++;
      if (r.reportType == ReportType.streetSweepingActive) sweeping = true;
      if (r.reportType == ReportType.parkingBlocked) blocked = true;
    }

    final estimatedOpen = max(0, available - taken);
    final relevantCount = activeReports.where((r) => r.isStillRelevant).length;

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        final totalAllTime = snapshot.exists
            ? ((snapshot.data()?['totalReportsAllTime'] as num?)?.toInt() ?? 0)
            : relevantCount;
        final createdAt = snapshot.exists
            ? (snapshot.data()?['createdAt'] as Timestamp?)?.toDate() ?? now
            : now;

        final confidence = relevantCount > 0
            ? min(1.0, 0.1 + 0.15 * log(max(1, totalAllTime).toDouble()))
            : 0.0;

        // Get centre coords from first report, or keep existing
        double lat = 0;
        double lng = 0;
        if (activeReports.isNotEmpty) {
          lat = activeReports.first.latitude;
          lng = activeReports.first.longitude;
        } else if (snapshot.exists) {
          lat = (snapshot.data()?['latitude'] as num?)?.toDouble() ?? 0;
          lng = (snapshot.data()?['longitude'] as num?)?.toDouble() ?? 0;
        }

        final zone = CrowdsourceZone(
          id: docId,
          region: region,
          geohash: geohash,
          latitude: lat,
          longitude: lng,
          totalReportsAllTime: totalAllTime,
          activeReports: relevantCount,
          estimatedOpenSpots: estimatedOpen,
          activeAvailableSignals: available,
          activeTakenSignals: taken,
          enforcementActive: enforcement > 0,
          sweepingActive: sweeping,
          parkingBlocked: blocked,
          hourlyAvgOpenSpots: snapshot.exists
              ? CrowdsourceZone.parseIntDoubleMap(
                  snapshot.data()?['hourlyAvgOpenSpots'],
                )
              : const {},
          dailyAvgOpenSpots: snapshot.exists
              ? CrowdsourceZone.parseIntDoubleMap(
                  snapshot.data()?['dailyAvgOpenSpots'],
                )
              : const {},
          enforcementPeakHours: snapshot.exists
              ? (snapshot.data()?['enforcementPeakHours'] as List<dynamic>?)
                        ?.map((e) => (e as num).toInt())
                        .toList() ??
                    const []
              : const [],
          confidenceScore: confidence,
          uniqueReporters: reporters.length,
          lastUpdated: now,
          createdAt: createdAt,
        );

        tx.set(docRef, zone.toFirestore());
      });

      debugPrint(
        '[ZoneAggregation] Recalculated zone $docId: '
        '$available avail, $taken taken, est=$estimatedOpen open',
      );
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to recalculate zone: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Record hourly pattern snapshot
  // ---------------------------------------------------------------------------

  /// Snapshot the current estimated open spots into the hourly average map.
  ///
  /// Should be called once per hour (e.g. by a periodic timer or Cloud
  /// Function) to build up the hourlyAvgOpenSpots historical data.
  Future<void> recordHourlySnapshot({
    required String geohash,
    required int estimatedOpenSpots,
    String region = defaultRegion,
  }) async {
    final docId = zoneDocId(region, geohash);
    final docRef = _firestore.collection(_collection).doc(docId);
    final hour = DateTime.now().hour;

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return;

        final existing = CrowdsourceZone.parseIntDoubleMap(
          snapshot.data()?['hourlyAvgOpenSpots'],
        );

        // Rolling average: new_avg = old_avg * 0.8 + new_value * 0.2
        final oldAvg = existing[hour] ?? estimatedOpenSpots.toDouble();
        final newAvg = oldAvg * 0.8 + estimatedOpenSpots * 0.2;
        existing[hour] = double.parse(newAvg.toStringAsFixed(1));

        tx.update(docRef, {
          'hourlyAvgOpenSpots': existing.map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        });
      });
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to record hourly snapshot: $e');
    }
  }

  /// Snapshot daily average (call once per day).
  Future<void> recordDailySnapshot({
    required String geohash,
    required int estimatedOpenSpots,
    String region = defaultRegion,
  }) async {
    final docId = zoneDocId(region, geohash);
    final docRef = _firestore.collection(_collection).doc(docId);
    final dayOfWeek = DateTime.now().weekday; // 1=Mon, 7=Sun

    try {
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);
        if (!snapshot.exists) return;

        final existing = CrowdsourceZone.parseIntDoubleMap(
          snapshot.data()?['dailyAvgOpenSpots'],
        );

        final oldAvg = existing[dayOfWeek] ?? estimatedOpenSpots.toDouble();
        final newAvg = oldAvg * 0.8 + estimatedOpenSpots * 0.2;
        existing[dayOfWeek] = double.parse(newAvg.toStringAsFixed(1));

        tx.update(docRef, {
          'dailyAvgOpenSpots': existing.map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        });
      });
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to record daily snapshot: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Query zones
  // ---------------------------------------------------------------------------

  /// Get a single zone by its geohash.
  Future<CrowdsourceZone?> getZone(
    String geohash, {
    String region = defaultRegion,
  }) async {
    final docId = zoneDocId(region, geohash);
    try {
      final doc = await _firestore.collection(_collection).doc(docId).get();
      if (!doc.exists) return null;
      return CrowdsourceZone.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to get zone: $e');
      return null;
    }
  }

  /// Query all zones within a geohash prefix area.
  ///
  /// With [queryPrecision]=5 this covers ~4.9km × 4.9km around the user.
  Future<List<CrowdsourceZone>> getNearbyZones({
    required double latitude,
    required double longitude,
    String region = defaultRegion,
    int? precision,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[ZoneAggregation] No authenticated user, skipping query');
      return [];
    }

    final p = precision ?? queryPrecision;
    final prefix = ParkingCrowdsourceService.encodeGeohash(
      latitude,
      longitude,
      p,
    );
    final docPrefix = zoneDocId(region, prefix);
    final upperBound = _docIdUpperBound(docPrefix);

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: docPrefix)
          .where(FieldPath.documentId, isLessThan: upperBound)
          .orderBy(FieldPath.documentId)
          .limit(200)
          .get();

      return snapshot.docs
          .map((doc) => CrowdsourceZone.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If permission-denied, force a token refresh and retry once.
      if ('$e'.contains('permission-denied')) {
        debugPrint(
          '[ZoneAggregation] Permission denied — refreshing auth token and retrying',
        );
        try {
          await user.getIdToken(true);
          final snapshot = await _firestore
              .collection(_collection)
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: docPrefix)
              .where(FieldPath.documentId, isLessThan: upperBound)
              .orderBy(FieldPath.documentId)
              .limit(200)
              .get();
          return snapshot.docs
              .map((doc) => CrowdsourceZone.fromFirestore(doc))
              .toList();
        } catch (retryErr) {
          debugPrint(
            '[ZoneAggregation] Retry after token refresh also failed: $retryErr',
          );
          return [];
        }
      }
      debugPrint('[ZoneAggregation] Failed to query nearby zones: $e');
      return [];
    }
  }

  /// Stream of nearby zones for real-time UI updates.
  Stream<List<CrowdsourceZone>> nearbyZonesStream({
    required double latitude,
    required double longitude,
    String region = defaultRegion,
    int? precision,
  }) {
    final p = precision ?? queryPrecision;
    final prefix = ParkingCrowdsourceService.encodeGeohash(
      latitude,
      longitude,
      p,
    );
    final docPrefix = zoneDocId(region, prefix);
    final upperBound = _docIdUpperBound(docPrefix);

    return _firestore
        .collection(_collection)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: docPrefix)
        .where(FieldPath.documentId, isLessThan: upperBound)
        .orderBy(FieldPath.documentId)
        .limit(200)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CrowdsourceZone.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all zones for an entire region (e.g. all of Milwaukee County).
  Future<List<CrowdsourceZone>> getRegionZones({
    String region = defaultRegion,
  }) async {
    final regionUnderscore = region.replaceAll('/', '_');

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('region', isEqualTo: region)
          .orderBy('estimatedOpenSpots', descending: true)
          .limit(500)
          .get();

      // Fallback: if the region field query fails (no index yet), use doc ID prefix
      if (snapshot.docs.isEmpty) {
        final prefixSnapshot = await _firestore
            .collection(_collection)
            .where(
              FieldPath.documentId,
              isGreaterThanOrEqualTo: regionUnderscore,
            )
            .where(
              FieldPath.documentId,
              isLessThan: _docIdUpperBound(regionUnderscore),
            )
            .orderBy(FieldPath.documentId)
            .limit(500)
            .get();

        return prefixSnapshot.docs
            .map((doc) => CrowdsourceZone.fromFirestore(doc))
            .toList();
      }

      return snapshot.docs
          .map((doc) => CrowdsourceZone.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[ZoneAggregation] Failed to get region zones: $e');
      return [];
    }
  }

  /// Summarise availability across a whole region.
  RegionAvailabilitySummary summariseRegion(List<CrowdsourceZone> zones) {
    if (zones.isEmpty) {
      return RegionAvailabilitySummary(
        region: defaultRegion,
        totalZones: 0,
        zonesWithOpenSpots: 0,
        totalEstimatedOpenSpots: 0,
        totalActiveReports: 0,
        zonesWithEnforcement: 0,
        averageConfidence: 0,
        totalUniqueReporters: 0,
        blindSpotZones: 0,
      );
    }

    int openSpotZones = 0;
    int totalOpen = 0;
    int totalReports = 0;
    int enforcementZones = 0;
    double confSum = 0;
    int totalReporters = 0;
    int blindSpots = 0;

    for (final z in zones) {
      if (z.estimatedOpenSpots > 0) openSpotZones++;
      totalOpen += z.estimatedOpenSpots;
      totalReports += z.activeReports;
      if (z.enforcementActive) enforcementZones++;
      confSum += z.confidenceScore;
      totalReporters += z.uniqueReporters;
      if (z.activeReports == 0) blindSpots++;
    }

    return RegionAvailabilitySummary(
      region: zones.first.region,
      totalZones: zones.length,
      zonesWithOpenSpots: openSpotZones,
      totalEstimatedOpenSpots: totalOpen,
      totalActiveReports: totalReports,
      zonesWithEnforcement: enforcementZones,
      averageConfidence: confSum / zones.length,
      totalUniqueReporters: totalReporters,
      blindSpotZones: blindSpots,
    );
  }

  /// Estimate open spots near a location by summing nearby zone aggregates.
  ///
  /// This is the method that powers "~X spots open near you".
  Future<int> estimateNearbySpotsOpen({
    required double latitude,
    required double longitude,
    String region = defaultRegion,
  }) async {
    final zones = await getNearbyZones(
      latitude: latitude,
      longitude: longitude,
      region: region,
    );
    if (zones.isEmpty) return 0;
    return zones.fold<int>(0, (total, z) => total + z.estimatedOpenSpots);
  }

  /// Real-time stream of estimated open spots near a location.
  Stream<int> nearbySpotCountStream({
    required double latitude,
    required double longitude,
    String region = defaultRegion,
  }) {
    return nearbyZonesStream(
      latitude: latitude,
      longitude: longitude,
      region: region,
    ).map((zones) {
      return zones.fold<int>(0, (total, z) => total + z.estimatedOpenSpots);
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Upper bound for a Firestore doc-ID prefix range query.
  static String _docIdUpperBound(String prefix) {
    if (prefix.isEmpty) return '';
    final lastChar = prefix.codeUnitAt(prefix.length - 1);
    return prefix.substring(0, prefix.length - 1) +
        String.fromCharCode(lastChar + 1);
  }

  bool _isTakenSignal(ReportType type) {
    return type == ReportType.parkedHere ||
        type == ReportType.spotTaken ||
        type == ReportType.streetSweepingActive ||
        type == ReportType.parkingBlocked;
  }

  bool _isEnforcementSignal(ReportType type) {
    return type == ReportType.enforcementSpotted ||
        type == ReportType.towTruckSpotted;
  }

  /// Clean up resources.
  void dispose() {
    // Nothing to dispose currently; reserved for future stream management.
  }
}
