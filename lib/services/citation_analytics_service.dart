import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Anonymized citation data point for analytics
/// This is what gets stored in Firestore for the risk/predictive engines
class CitationDataPoint {
  const CitationDataPoint({
    required this.violationType,
    required this.latitude,
    required this.longitude,
    required this.issuedAt,
    this.amount,
    this.meterNumber,
    this.dayOfWeek,
    this.hourOfDay,
    this.streetName,
    this.neighborhood,
  });

  /// Type of violation (normalized to match our known types)
  final String violationType;

  /// Location coordinates
  final double latitude;
  final double longitude;

  /// When the citation was issued
  final DateTime issuedAt;

  /// Fine amount (for pattern analysis)
  final double? amount;

  /// Meter number if applicable
  final String? meterNumber;

  /// Day of week (1=Monday, 7=Sunday)
  final int? dayOfWeek;

  /// Hour of day (0-23)
  final int? hourOfDay;

  /// Extracted street name for aggregation
  final String? streetName;

  /// Neighborhood/area for zone analysis
  final String? neighborhood;

  Map<String, dynamic> toFirestore() {
    return {
      'violationType': violationType,
      'latitude': latitude,
      'longitude': longitude,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'amount': amount,
      'meterNumber': meterNumber,
      'dayOfWeek': dayOfWeek ?? issuedAt.weekday,
      'hourOfDay': hourOfDay ?? issuedAt.hour,
      'streetName': streetName,
      'neighborhood': neighborhood,
      // Geohash for efficient geo queries (simple version)
      'geoHash': _simpleGeoHash(latitude, longitude),
      'submittedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Simple geohash for clustering nearby citations
  static String _simpleGeoHash(double lat, double lng) {
    // Round to ~100m precision for clustering
    final latRounded = (lat * 1000).round();
    final lngRounded = (lng * 1000).round();
    return '$latRounded,$lngRounded';
  }

  factory CitationDataPoint.fromFirestore(Map<String, dynamic> data) {
    final issuedAt =
        (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return CitationDataPoint(
      violationType: data['violationType'] as String? ?? 'OTHER',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      issuedAt: issuedAt,
      amount: (data['amount'] as num?)?.toDouble(),
      meterNumber: data['meterNumber'] as String?,
      dayOfWeek: data['dayOfWeek'] as int?,
      hourOfDay: data['hourOfDay'] as int?,
      streetName: data['streetName'] as String?,
      neighborhood: data['neighborhood'] as String?,
    );
  }
}

/// Service for collecting and aggregating citation data for analytics
class CitationAnalyticsService {
  static final CitationAnalyticsService _instance =
      CitationAnalyticsService._internal();
  factory CitationAnalyticsService() => _instance;
  CitationAnalyticsService._internal();

  static CitationAnalyticsService get instance => _instance;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Collection for aggregated (anonymized) citation data - powers the risk engine
  CollectionReference get _citationAnalytics =>
      _firestore.collection('citation_analytics');

  /// Collection for per-user citations (private, with photo paths etc)
  CollectionReference _userCitations(String userId) =>
      _firestore.collection('users').doc(userId).collection('citations');

  /// Submit a citation from OCR scan or manual entry
  /// This stores:
  /// 1. Full data in user's private collection
  /// 2. Anonymized data in shared analytics collection for risk engine
  Future<void> submitCitation({
    required String citationNumber,
    required String violationType,
    required double latitude,
    required double longitude,
    required DateTime issuedAt,
    String? licensePlate, // Stored only in private collection
    double? amount,
    String? location,
    String? meterNumber,
    String? photoPath,
    bool fromOcr = false,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ Cannot submit citation: user not logged in');
      return;
    }

    try {
      // 1. Store full citation in user's private collection
      final userCitationData = {
        'citationNumber': citationNumber,
        'licensePlate': licensePlate,
        'violationType': violationType,
        'latitude': latitude,
        'longitude': longitude,
        'issuedAt': Timestamp.fromDate(issuedAt),
        'amount': amount,
        'location': location,
        'meterNumber': meterNumber,
        'photoPath': photoPath,
        'fromOcr': fromOcr,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _userCitations(userId).doc(citationNumber).set(userCitationData);
      debugPrint('✅ User citation saved: $citationNumber');

      // 2. Submit anonymized data to analytics collection
      // This powers the risk engine without exposing personal data
      final analyticsData = CitationDataPoint(
        violationType: _normalizeViolationType(violationType),
        latitude: latitude,
        longitude: longitude,
        issuedAt: issuedAt,
        amount: amount,
        meterNumber: meterNumber,
        streetName: _extractStreetName(location),
        neighborhood: _detectNeighborhood(latitude, longitude),
      );

      // Use a hash of citation number to prevent duplicates without storing actual number
      final analyticsDocId = _hashCitationNumber(citationNumber);
      await _citationAnalytics
          .doc(analyticsDocId)
          .set(analyticsData.toFirestore());
      debugPrint('📊 Analytics data submitted for risk engine');

      // 3. Update aggregated stats
      await _updateAggregatedStats(analyticsData);
    } catch (e, stack) {
      debugPrint('❌ Failed to submit citation: $e\n$stack');
      rethrow;
    }
  }

  /// Get user's submitted citations
  Future<List<Map<String, dynamic>>> getUserCitations() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _userCitations(
        userId,
      ).orderBy('issuedAt', descending: true).limit(50).get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get user citations: $e');
      return [];
    }
  }

  /// Get citation hotspots from aggregated data
  Future<List<CitationDataPoint>> getCitationHotspots({
    double? nearLatitude,
    double? nearLongitude,
    double radiusKm = 2.0,
    int limit = 100,
  }) async {
    try {
      Query query = _citationAnalytics
          .orderBy('issuedAt', descending: true)
          .limit(limit);

      // If location provided, filter by geohash prefix
      if (nearLatitude != null && nearLongitude != null) {
        final centerHash = CitationDataPoint._simpleGeoHash(
          nearLatitude,
          nearLongitude,
        );
        // Get citations in the same general area
        query = _citationAnalytics
            .where(
              'geoHash',
              isGreaterThanOrEqualTo: centerHash.split(',').first,
            )
            .limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => CitationDataPoint.fromFirestore(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to get citation hotspots: $e');
      return [];
    }
  }

  /// Get violation statistics for a location
  Future<Map<String, dynamic>> getLocationStats(double lat, double lng) async {
    try {
      final geoHash = CitationDataPoint._simpleGeoHash(lat, lng);

      // Look for aggregated stats doc
      final statsDoc = await _firestore
          .collection('citation_stats')
          .doc(geoHash)
          .get();

      if (statsDoc.exists) {
        return statsDoc.data() ?? {};
      }

      return {
        'totalCitations': 0,
        'topViolations': <String>[],
        'peakHours': <int>[],
      };
    } catch (e) {
      debugPrint('❌ Failed to get location stats: $e');
      return {};
    }
  }

  /// Update aggregated statistics when new citation is added
  Future<void> _updateAggregatedStats(CitationDataPoint citation) async {
    try {
      final geoHash = CitationDataPoint._simpleGeoHash(
        citation.latitude,
        citation.longitude,
      );
      final statsRef = _firestore.collection('citation_stats').doc(geoHash);

      await _firestore.runTransaction((transaction) async {
        final statsDoc = await transaction.get(statsRef);

        if (statsDoc.exists) {
          // Update existing stats
          final data = statsDoc.data() ?? {};
          final totalCitations = (data['totalCitations'] as int? ?? 0) + 1;

          // Update violation counts
          final violationCounts = Map<String, int>.from(
            (data['violationCounts'] as Map<String, dynamic>?) ?? {},
          );
          violationCounts[citation.violationType] =
              (violationCounts[citation.violationType] ?? 0) + 1;

          // Update hour counts
          final hourCounts = List<int>.from(
            (data['hourCounts'] as List<dynamic>?) ?? List.filled(24, 0),
          );
          hourCounts[citation.hourOfDay ?? citation.issuedAt.hour]++;

          // Update day of week counts
          final dayOfWeekCounts = List<int>.from(
            (data['dayOfWeekCounts'] as List<dynamic>?) ?? List.filled(7, 0),
          );
          dayOfWeekCounts[(citation.dayOfWeek ?? citation.issuedAt.weekday) -
              1]++;

          transaction.update(statsRef, {
            'totalCitations': totalCitations,
            'violationCounts': violationCounts,
            'hourCounts': hourCounts,
            'dayOfWeekCounts': dayOfWeekCounts,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new stats document
          final hourCounts = List.filled(24, 0);
          hourCounts[citation.hourOfDay ?? citation.issuedAt.hour] = 1;

          final dayOfWeekCounts = List.filled(7, 0);
          dayOfWeekCounts[(citation.dayOfWeek ?? citation.issuedAt.weekday) -
                  1] =
              1;

          transaction.set(statsRef, {
            'geoHash': geoHash,
            'latitude': citation.latitude,
            'longitude': citation.longitude,
            'totalCitations': 1,
            'violationCounts': {citation.violationType: 1},
            'hourCounts': hourCounts,
            'dayOfWeekCounts': dayOfWeekCounts,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('📈 Updated aggregated stats for geoHash: $geoHash');
    } catch (e) {
      debugPrint('⚠️ Failed to update aggregated stats: $e');
      // Non-fatal, continue
    }
  }

  /// Normalize violation type to match our known categories
  String _normalizeViolationType(String violation) {
    final v = violation.toUpperCase();

    if (v.contains('NIGHT')) return 'NIGHT PARKING';
    if (v.contains('METER')) return 'METER PARKING VIOLATION';
    if (v.contains('OVERTIME') ||
        v.contains('EXCESS') ||
        v.contains('2 HOUR')) {
      return 'PARKED IN EXCESS OF 2 HOURS PROHIBITED';
    }
    if (v.contains('REGISTRATION'))
      return 'FAILURE TO DISPLAY CURRENT REGISTRATION';
    if (v.contains('HYDRANT')) return 'FIRE HYDRANT VIOLATION';
    if (v.contains('SIGN') || v.contains('PROHIBITED')) {
      return 'PARKING PROHIBITED BY OFFICIAL SIGN';
    }
    if (v.contains('HANDICAP') || v.contains('DISABLED'))
      return 'HANDICAPPED ZONE VIOLATION';
    if (v.contains('BUS')) return 'PARKED IN BUS STOP/ZONE';
    if (v.contains('LOADING')) return 'LOADING ZONE VIOLATION';
    if (v.contains('CROSSWALK')) return 'CROSSWALK VIOLATION';
    if (v.contains('DOUBLE')) return 'DOUBLE PARKING';
    if (v.contains('STREET CLEANING') || v.contains('SWEEPING')) {
      return 'STREET CLEANING VIOLATION';
    }
    if (v.contains('ALTERNATE SIDE')) return 'ALTERNATE SIDE PARKING VIOLATION';

    return violation;
  }

  /// Extract street name from location string
  String? _extractStreetName(String? location) {
    if (location == null || location.isEmpty) return null;

    final upper = location.toUpperCase();

    // Extract the main street name
    final streetPattern = RegExp(
      r'\b([NSEW]\.?\s+)?(\w+)\s+(ST|AVE|BLVD|DR|RD|WAY|CT|PL|LN)\b',
      caseSensitive: false,
    );
    final match = streetPattern.firstMatch(upper);
    if (match != null) {
      return match.group(0)?.trim();
    }

    return null;
  }

  /// Detect neighborhood based on coordinates
  /// Simple version - could be enhanced with proper boundary data
  String? _detectNeighborhood(double lat, double lng) {
    // Milwaukee neighborhood approximate boundaries
    // This is simplified - ideally would use proper GeoJSON boundaries

    // Downtown
    if (lat >= 43.0300 && lat <= 43.0500 && lng >= -87.920 && lng <= -87.900) {
      return 'Downtown';
    }
    // Third Ward
    if (lat >= 43.0280 && lat <= 43.0380 && lng >= -87.910 && lng <= -87.900) {
      return 'Third Ward';
    }
    // East Side
    if (lat >= 43.0400 && lat <= 43.0700 && lng >= -87.900 && lng <= -87.870) {
      return 'East Side';
    }
    // Riverwest
    if (lat >= 43.0600 && lat <= 43.0900 && lng >= -87.920 && lng <= -87.900) {
      return 'Riverwest';
    }
    // Bay View
    if (lat >= 42.9900 && lat <= 43.0300 && lng >= -87.910 && lng <= -87.880) {
      return 'Bay View';
    }
    // Walker's Point
    if (lat >= 43.0150 && lat <= 43.0300 && lng >= -87.930 && lng <= -87.910) {
      return 'Walkers Point';
    }
    // Brady Street
    if (lat >= 43.0450 && lat <= 43.0550 && lng >= -87.905 && lng <= -87.890) {
      return 'Brady Street';
    }

    return null;
  }

  /// Create a hash of citation number for deduplication
  String _hashCitationNumber(String citationNumber) {
    // Simple hash for document ID - prevents storing actual citation numbers
    // in the public analytics collection
    int hash = 0;
    for (int i = 0; i < citationNumber.length; i++) {
      hash = ((hash << 5) - hash + citationNumber.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return 'cit_${hash.toRadixString(16)}';
  }
}
