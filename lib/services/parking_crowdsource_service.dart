import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/parking_report.dart';
import 'zone_aggregation_service.dart';

/// Service for crowdsourced parking availability reports.
///
/// Users submit real-time reports (leaving spot, enforcement spotted, etc.)
/// that are stored in Firestore and queried by nearby users via geohash
/// prefix matching. Reports auto-expire based on their type's TTL.
class ParkingCrowdsourceService {
  ParkingCrowdsourceService._();
  static final ParkingCrowdsourceService instance =
      ParkingCrowdsourceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ZoneAggregationService _zoneService = ZoneAggregationService.instance;

  /// Firestore collection name
  static const String _collection = 'parkingReports';

  /// Geohash precision for queries (5 = ~4.9km × 4.9km cell)
  static const int _queryGeohashPrecision = 5;

  /// Geohash precision for storage (7 = ~150m × 150m cell)
  static const int _storageGeohashPrecision = 7;

  /// Max reports a user can submit per hour (rate-limit client-side)
  static const int _maxReportsPerHour = 10;

  /// Minimum reliability score to show a report (0.0–1.0).
  /// Reports with ≥ [_minVotesForFilter] total votes AND a reliability score
  /// below this threshold are hidden from the feed.
  static const double _minReliabilityScore = 0.3;

  /// Minimum total votes before the reliability filter kicks in.
  /// Prevents brand-new reports from being hidden by a single downvote.
  static const int _minVotesForFilter = 3;

  /// Cache of recent user submissions for rate limiting
  final List<DateTime> _recentSubmissions = [];

  /// Active subscription for nearby reports stream
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _nearbySubscription;

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  /// Submit a new parking report.
  ///
  /// Returns the created [ParkingReport] on success, or `null` if rate-limited
  /// or the user is not authenticated.
  Future<ParkingReport?> submitReport({
    required ReportType reportType,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    String? note,
    String region = 'wi/milwaukee',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Crowdsource] User not authenticated');
      return null;
    }

    // Client-side rate limit
    if (!_checkRateLimit()) {
      debugPrint('[Crowdsource] Rate-limited: too many reports');
      return null;
    }

    final now = DateTime.now();
    final geohash = encodeGeohash(
      latitude,
      longitude,
      _storageGeohashPrecision,
    );
    final expiresAt = now.add(Duration(minutes: reportType.ttlMinutes));
    final zoneGeohash = geohash.substring(
      0,
      ZoneAggregationService.zonePrecision.clamp(1, geohash.length),
    );
    final zoneId = ZoneAggregationService.zoneDocId(region, zoneGeohash);

    final docRef = _firestore.collection(_collection).doc();
    final report = ParkingReport(
      id: docRef.id,
      userId: user.uid,
      reportType: reportType,
      latitude: latitude,
      longitude: longitude,
      geohash: geohash,
      timestamp: now,
      expiresAt: expiresAt,
      accuracyMeters: accuracyMeters,
      note: note,
      region: region,
      zoneId: zoneId,
    );

    try {
      await docRef.set(report.toFirestore());
      _recentSubmissions.add(now);
      debugPrint(
        '[Crowdsource] Report submitted: ${reportType.displayName} '
        'at $latitude,$longitude (geohash: $geohash, zone: $zoneId)',
      );

      // Fire-and-forget zone aggregation update
      _zoneService.updateZoneForReport(report, region: region).catchError((e) {
        debugPrint('[Crowdsource] Zone aggregation failed (non-blocking): $e');
      });

      return report;
    } catch (e) {
      debugPrint('[Crowdsource] Failed to submit report: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Reliability Filter
  // ---------------------------------------------------------------------------

  /// Filter out low-reliability and server-flagged reports.
  ///
  /// A report is hidden if:
  /// - It has been flagged by server-side moderation (`flagged == true`), OR
  /// - It has ≥ [_minVotesForFilter] total votes AND a [reliabilityScore]
  ///   below [_minReliabilityScore] (heavily downvoted by the community).
  static List<ParkingReport> _applyReliabilityFilter(
    List<ParkingReport> reports,
  ) {
    return reports.where((r) {
      // Server-flagged reports are always hidden
      if (r.flagged) return false;

      // Community reliability filter — only kicks in with enough votes
      final totalVotes = r.upvotes + r.downvotes;
      if (totalVotes >= _minVotesForFilter &&
          r.reliabilityScore < _minReliabilityScore) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Fetch active (non-expired) reports near a location.
  ///
  /// Uses geohash prefix matching for efficient Firestore queries without
  /// requiring a composite geo-index. Results are filtered client-side for
  /// TTL expiry.
  Future<List<ParkingReport>> getNearbyReports({
    required double latitude,
    required double longitude,
    int? geohashPrecision,
  }) async {
    final precision = geohashPrecision ?? _queryGeohashPrecision;
    final prefix = encodeGeohash(latitude, longitude, precision);
    final now = DateTime.now();

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: _geohashUpperBound(prefix))
          .where('isExpired', isEqualTo: false)
          .orderBy('geohash')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      return _applyReliabilityFilter(
        snapshot.docs
            .map((doc) => ParkingReport.fromFirestore(doc))
            .where((r) => now.isBefore(r.expiresAt)) // Client-side TTL check
            .toList(),
      );
    } catch (e) {
      debugPrint('[Crowdsource] Failed to query nearby reports: $e');
      return [];
    }
  }

  /// Stream of nearby reports for real-time updates.
  ///
  /// Emits a new list every time the underlying Firestore query changes.
  Stream<List<ParkingReport>> nearbyReportsStream({
    required double latitude,
    required double longitude,
    int? geohashPrecision,
  }) {
    final precision = geohashPrecision ?? _queryGeohashPrecision;
    final prefix = encodeGeohash(latitude, longitude, precision);

    return _firestore
        .collection(_collection)
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: _geohashUpperBound(prefix))
        .where('isExpired', isEqualTo: false)
        .orderBy('geohash')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return _applyReliabilityFilter(
            snapshot.docs
                .map((doc) => ParkingReport.fromFirestore(doc))
                .where((r) => now.isBefore(r.expiresAt))
                .toList(),
          );
        });
  }

  /// Start listening for nearby reports and call [onUpdate] with new data.
  void startListening({
    required double latitude,
    required double longitude,
    required void Function(List<ParkingReport> reports) onUpdate,
  }) {
    stopListening();
    final prefix = encodeGeohash(latitude, longitude, _queryGeohashPrecision);

    _nearbySubscription = _firestore
        .collection(_collection)
        .where('geohash', isGreaterThanOrEqualTo: prefix)
        .where('geohash', isLessThan: _geohashUpperBound(prefix))
        .where('isExpired', isEqualTo: false)
        .orderBy('geohash')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            final now = DateTime.now();
            final reports = _applyReliabilityFilter(
              snapshot.docs
                  .map((doc) => ParkingReport.fromFirestore(doc))
                  .where((r) => now.isBefore(r.expiresAt))
                  .toList(),
            );
            onUpdate(reports);
          },
          onError: (e) {
            debugPrint('[Crowdsource] Listener error: $e');
          },
        );
  }

  /// Stop the nearby reports listener.
  void stopListening() {
    _nearbySubscription?.cancel();
    _nearbySubscription = null;
  }

  // ---------------------------------------------------------------------------
  // Voting
  // ---------------------------------------------------------------------------

  /// Upvote a report (confirm it's accurate).
  Future<void> upvote(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'upvotes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[Crowdsource] Failed to upvote: $e');
    }
  }

  /// Downvote a report (flag as inaccurate).
  Future<void> downvote(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'downvotes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[Crowdsource] Failed to downvote: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  /// Aggregate nearby reports into a [SpotAvailability] summary.
  static SpotAvailability aggregateAvailability(List<ParkingReport> reports) {
    if (reports.isEmpty) {
      return SpotAvailability(
        geohashPrefix: '',
        totalReports: 0,
        availableSignals: 0,
        takenSignals: 0,
        enforcementSignals: 0,
        lastUpdated: DateTime.now(),
      );
    }

    int available = 0;
    int taken = 0;
    int enforcement = 0;

    for (final report in reports) {
      if (!report.isStillRelevant) continue;

      switch (report.reportType) {
        case ReportType.leavingSpot:
        case ReportType.spotAvailable:
          available++;
          break;
        case ReportType.parkedHere:
        case ReportType.spotTaken:
        case ReportType.streetSweepingActive:
        case ReportType.parkingBlocked:
          taken++;
          break;
        case ReportType.enforcementSpotted:
        case ReportType.towTruckSpotted:
          enforcement++;
          break;
      }
    }

    final estimatedOpen = (available - taken).clamp(0, available);

    return SpotAvailability(
      geohashPrefix: reports.first.geohash.substring(
        0,
        _queryGeohashPrecision.clamp(1, reports.first.geohash.length),
      ),
      totalReports: reports.length,
      availableSignals: available,
      takenSignals: taken,
      enforcementSignals: enforcement,
      estimatedOpenSpots: estimatedOpen,
      lastUpdated: reports
          .map((r) => r.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  // ---------------------------------------------------------------------------
  // My Reports
  // ---------------------------------------------------------------------------

  /// Get the current user's recent reports.
  Future<List<ParkingReport>> getMyReports({int limit = 20}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ParkingReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[Crowdsource] Failed to fetch my reports: $e');
      return [];
    }
  }

  /// Delete one of the current user's reports.
  Future<bool> deleteReport(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Verify ownership before deleting
      final doc = await _firestore.collection(_collection).doc(reportId).get();
      if (!doc.exists || doc.data()?['userId'] != user.uid) {
        debugPrint('[Crowdsource] Cannot delete: not owner');
        return false;
      }
      await _firestore.collection(_collection).doc(reportId).delete();
      return true;
    } catch (e) {
      debugPrint('[Crowdsource] Failed to delete report: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Rate Limiting (client-side)
  // ---------------------------------------------------------------------------

  bool _checkRateLimit() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    _recentSubmissions.removeWhere((t) => t.isBefore(oneHourAgo));
    return _recentSubmissions.length < _maxReportsPerHour;
  }

  // ---------------------------------------------------------------------------
  // Geohash Utilities
  // ---------------------------------------------------------------------------

  /// Encode lat/lon to a geohash string at the given precision.
  ///
  /// Precision guide:
  ///   5 → ~4.9km × 4.9km
  ///   6 → ~1.2km × 0.6km
  ///   7 → ~150m × 150m
  static String encodeGeohash(double lat, double lon, int precision) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    var minLat = -90.0, maxLat = 90.0;
    var minLon = -180.0, maxLon = 180.0;
    final hash = StringBuffer();
    var bit = 0;
    var ch = 0;
    var even = true;

    while (hash.length < precision) {
      if (even) {
        final mid = (minLon + maxLon) / 2;
        if (lon >= mid) {
          ch |= 1 << (4 - bit);
          minLon = mid;
        } else {
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit);
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        hash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return hash.toString();
  }

  /// Get the upper bound string for a geohash prefix range query.
  ///
  /// E.g., prefix "dp5dt" → "dp5du" so Firestore range query
  /// `>= prefix && < upperBound` captures all children of that prefix.
  static String _geohashUpperBound(String prefix) {
    if (prefix.isEmpty) return '';
    final lastChar = prefix.codeUnitAt(prefix.length - 1);
    return prefix.substring(0, prefix.length - 1) +
        String.fromCharCode(lastChar + 1);
  }

  /// Clean up resources.
  void dispose() {
    stopListening();
    _recentSubmissions.clear();
  }
}
