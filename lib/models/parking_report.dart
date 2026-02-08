import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Types of crowdsourced parking reports users can submit
enum ReportType {
  /// User is leaving a parking spot (spot about to be available)
  leavingSpot,

  /// User just parked here (spot now taken)
  parkedHere,

  /// User sees an available spot nearby
  spotAvailable,

  /// User sees a spot is taken / no spots in area
  spotTaken,

  /// Enforcement officer spotted in area
  enforcementSpotted,

  /// Tow truck spotted in area
  towTruckSpotted,

  /// Street is being swept (move your car!)
  streetSweepingActive,

  /// Construction or event blocking parking
  parkingBlocked,
}

extension ReportTypeExt on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.leavingSpot:
        return 'Leaving Spot';
      case ReportType.parkedHere:
        return 'Parked Here';
      case ReportType.spotAvailable:
        return 'Spot Available';
      case ReportType.spotTaken:
        return 'Spot Taken';
      case ReportType.enforcementSpotted:
        return 'Enforcement Spotted';
      case ReportType.towTruckSpotted:
        return 'Tow Truck Spotted';
      case ReportType.streetSweepingActive:
        return 'Street Sweeping Active';
      case ReportType.parkingBlocked:
        return 'Parking Blocked';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.leavingSpot:
        return Icons.directions_car_outlined;
      case ReportType.parkedHere:
        return Icons.local_parking;
      case ReportType.spotAvailable:
        return Icons.check_circle_outline;
      case ReportType.spotTaken:
        return Icons.cancel_outlined;
      case ReportType.enforcementSpotted:
        return Icons.policy;
      case ReportType.towTruckSpotted:
        return Icons.fire_truck;
      case ReportType.streetSweepingActive:
        return Icons.cleaning_services;
      case ReportType.parkingBlocked:
        return Icons.block;
    }
  }

  /// How long this report type stays relevant (TTL in minutes)
  int get ttlMinutes {
    switch (this) {
      case ReportType.leavingSpot:
        return 10; // Spot freed up quickly
      case ReportType.parkedHere:
        return 120; // Parked for a while
      case ReportType.spotAvailable:
        return 15; // Available spots go fast
      case ReportType.spotTaken:
        return 60; // Taken for a while
      case ReportType.enforcementSpotted:
        return 30; // Enforcement moves through
      case ReportType.towTruckSpotted:
        return 20; // Tow trucks are transient
      case ReportType.streetSweepingActive:
        return 180; // Sweeping takes hours
      case ReportType.parkingBlocked:
        return 480; // Construction/events last a while
    }
  }

  /// Whether this report type is positive for parking availability
  bool get isPositiveSignal {
    switch (this) {
      case ReportType.leavingSpot:
      case ReportType.spotAvailable:
        return true;
      case ReportType.parkedHere:
      case ReportType.spotTaken:
      case ReportType.enforcementSpotted:
      case ReportType.towTruckSpotted:
      case ReportType.streetSweepingActive:
      case ReportType.parkingBlocked:
        return false;
    }
  }
}

/// A crowdsourced parking report from a user
class ParkingReport {
  final String id;
  final String userId;
  final ReportType reportType;
  final double latitude;
  final double longitude;
  final String geohash;
  final DateTime timestamp;
  final DateTime expiresAt;
  final double? accuracyMeters; // GPS accuracy
  final String? note; // Optional user note
  final int upvotes;
  final int downvotes;
  final bool isExpired;

  /// Whether this report has been flagged by server-side moderation.
  /// Flagged reports are hidden from the live feed.
  final bool flagged;

  /// Region this report belongs to (e.g. "wi/milwaukee").
  /// Enables multi-region partitioning for scaling to other cities/states.
  final String region;

  /// Zone document ID this report rolls up into.
  /// Format: "{region}_{geohash7}", e.g. "wi_milwaukee_dp5dtpp".
  final String? zoneId;

  const ParkingReport({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.timestamp,
    required this.expiresAt,
    this.accuracyMeters,
    this.note,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isExpired = false,
    this.flagged = false,
    this.region = 'wi/milwaukee',
    this.zoneId,
  });

  /// Create from Firestore document
  factory ParkingReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ParkingReport(
      id: doc.id,
      userId: data['userId'] as String,
      reportType: ReportType.values.firstWhere(
        (t) => t.name == data['reportType'],
        orElse: () => ReportType.spotTaken,
      ),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      geohash: data['geohash'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accuracyMeters: (data['accuracyMeters'] as num?)?.toDouble(),
      note: data['note'] as String?,
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (data['downvotes'] as num?)?.toInt() ?? 0,
      isExpired: data['isExpired'] as bool? ?? false,
      flagged: data['flagged'] as bool? ?? false,
      region: data['region'] as String? ?? 'wi/milwaukee',
      zoneId: data['zoneId'] as String?,
    );
  }

  /// Create from JSON (for local cache)
  factory ParkingReport.fromJson(Map<String, dynamic> json) {
    return ParkingReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      reportType: ReportType.values.firstWhere(
        (t) => t.name == json['reportType'],
        orElse: () => ReportType.spotTaken,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      geohash: json['geohash'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      note: json['note'] as String?,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      isExpired: json['isExpired'] as bool? ?? false,
      flagged: json['flagged'] as bool? ?? false,
      region: json['region'] as String? ?? 'wi/milwaukee',
      zoneId: json['zoneId'] as String?,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'reportType': reportType.name,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'accuracyMeters': accuracyMeters,
      'note': note,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isExpired': isExpired,
      'flagged': flagged,
      'region': region,
      'zoneId': zoneId,
    };
  }

  /// Convert to JSON (for local cache)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportType': reportType.name,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'accuracyMeters': accuracyMeters,
      'note': note,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isExpired': isExpired,
      'flagged': flagged,
      'region': region,
      'zoneId': zoneId,
    };
  }

  /// Whether this report is still relevant (not past TTL)
  bool get isStillRelevant => !isExpired && DateTime.now().isBefore(expiresAt);

  /// Reliability score based on votes (0.0 to 1.0)
  double get reliabilityScore {
    final totalVotes = upvotes + downvotes;
    if (totalVotes == 0) return 0.5; // Neutral default
    return upvotes / totalVotes;
  }

  /// Age of report in minutes
  int get ageMinutes => DateTime.now().difference(timestamp).inMinutes;

  ParkingReport copyWith({
    ReportType? reportType,
    double? latitude,
    double? longitude,
    String? geohash,
    DateTime? expiresAt,
    double? accuracyMeters,
    String? note,
    int? upvotes,
    int? downvotes,
    bool? isExpired,
    bool? flagged,
    String? region,
    String? zoneId,
  }) {
    return ParkingReport(
      id: id,
      userId: userId,
      reportType: reportType ?? this.reportType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      timestamp: timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      note: note ?? this.note,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isExpired: isExpired ?? this.isExpired,
      flagged: flagged ?? this.flagged,
      region: region ?? this.region,
      zoneId: zoneId ?? this.zoneId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingReport &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ParkingReport(id: $id, type: ${reportType.displayName}, '
      'lat: $latitude, lng: $longitude, age: ${ageMinutes}min)';
}

/// Aggregated spot availability summary for an area
class SpotAvailability {
  final String geohashPrefix;
  final int totalReports;
  final int availableSignals;
  final int takenSignals;
  final int enforcementSignals;
  final DateTime lastUpdated;

  /// Estimated number of open spots derived from signal counts.
  /// availableSignals − takenSignals, floored to 0.
  final int estimatedOpenSpots;

  const SpotAvailability({
    required this.geohashPrefix,
    required this.totalReports,
    required this.availableSignals,
    required this.takenSignals,
    required this.enforcementSignals,
    required this.lastUpdated,
    this.estimatedOpenSpots = 0,
  });

  /// Availability score: 0.0 (no spots) to 1.0 (plenty of spots)
  double get availabilityScore {
    if (totalReports == 0) return 0.5; // Unknown = neutral
    final signals = availableSignals - takenSignals;
    // Normalize to 0-1 range, with enforcement penalty
    final base = (signals / totalReports + 1) / 2; // -1..1 → 0..1
    final enforcementPenalty = enforcementSignals > 0 ? 0.1 : 0.0;
    return (base - enforcementPenalty).clamp(0.0, 1.0);
  }

  /// Human-readable availability label
  String get label {
    if (estimatedOpenSpots > 0) {
      return '~$estimatedOpenSpots spot${estimatedOpenSpots == 1 ? '' : 's'} open';
    }
    final score = availabilityScore;
    if (score >= 0.7) return 'Good availability';
    if (score >= 0.4) return 'Limited spots';
    if (score >= 0.2) return 'Very few spots';
    return 'No spots reported';
  }

  /// Color for availability display
  Color get color {
    final score = availabilityScore;
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  /// Whether enforcement has been spotted in this area
  bool get hasEnforcement => enforcementSignals > 0;
}
