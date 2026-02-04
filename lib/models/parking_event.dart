import 'package:flutter/material.dart';

/// Types of parking-related events that can be logged
enum ParkingEventType {
  /// Street sweeping alert received
  streetSweepingAlert,

  /// Alternate side parking reminder
  alternateSideReminder,

  /// Parking session started
  parkingStarted,

  /// Parking session ended
  parkingEnded,

  /// Parking meter expiring soon
  meterExpiring,

  /// Citation risk alert
  citationRiskAlert,

  /// Enforcement spotted nearby
  enforcementSpotted,

  /// Tow truck spotted nearby
  towTruckSpotted,

  /// Permit renewed
  permitRenewed,

  /// Permit expiring soon
  permitExpiring,

  /// Vehicle moved reminder
  moveVehicleReminder,

  /// User reported a sighting
  sightingReported,

  /// Garbage/recycling reminder
  garbageReminder,

  /// General notification
  generalNotification,
}

extension ParkingEventTypeExt on ParkingEventType {
  String get displayName {
    switch (this) {
      case ParkingEventType.streetSweepingAlert:
        return 'Street Sweeping Alert';
      case ParkingEventType.alternateSideReminder:
        return 'Alternate Side Reminder';
      case ParkingEventType.parkingStarted:
        return 'Parking Started';
      case ParkingEventType.parkingEnded:
        return 'Parking Ended';
      case ParkingEventType.meterExpiring:
        return 'Meter Expiring';
      case ParkingEventType.citationRiskAlert:
        return 'Citation Risk Alert';
      case ParkingEventType.enforcementSpotted:
        return 'Enforcement Spotted';
      case ParkingEventType.towTruckSpotted:
        return 'Tow Truck Spotted';
      case ParkingEventType.permitRenewed:
        return 'Permit Renewed';
      case ParkingEventType.permitExpiring:
        return 'Permit Expiring';
      case ParkingEventType.moveVehicleReminder:
        return 'Move Vehicle Reminder';
      case ParkingEventType.sightingReported:
        return 'Sighting Reported';
      case ParkingEventType.garbageReminder:
        return 'Garbage/Recycling Reminder';
      case ParkingEventType.generalNotification:
        return 'Notification';
    }
  }

  IconData get icon {
    switch (this) {
      case ParkingEventType.streetSweepingAlert:
        return Icons.cleaning_services;
      case ParkingEventType.alternateSideReminder:
        return Icons.swap_horiz;
      case ParkingEventType.parkingStarted:
        return Icons.local_parking;
      case ParkingEventType.parkingEnded:
        return Icons.directions_car;
      case ParkingEventType.meterExpiring:
        return Icons.timer;
      case ParkingEventType.citationRiskAlert:
        return Icons.warning_amber;
      case ParkingEventType.enforcementSpotted:
        return Icons.local_police;
      case ParkingEventType.towTruckSpotted:
        return Icons.car_crash;
      case ParkingEventType.permitRenewed:
        return Icons.verified;
      case ParkingEventType.permitExpiring:
        return Icons.schedule;
      case ParkingEventType.moveVehicleReminder:
        return Icons.notifications_active;
      case ParkingEventType.sightingReported:
        return Icons.report;
      case ParkingEventType.garbageReminder:
        return Icons.delete_outline;
      case ParkingEventType.generalNotification:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (this) {
      case ParkingEventType.streetSweepingAlert:
        return const Color(0xFF4299E1); // Blue
      case ParkingEventType.alternateSideReminder:
        return const Color(0xFFED8936); // Orange
      case ParkingEventType.parkingStarted:
        return const Color(0xFF48BB78); // Green
      case ParkingEventType.parkingEnded:
        return const Color(0xFF718096); // Gray
      case ParkingEventType.meterExpiring:
        return const Color(0xFFED8936); // Orange
      case ParkingEventType.citationRiskAlert:
        return const Color(0xFFF56565); // Red
      case ParkingEventType.enforcementSpotted:
        return const Color(0xFFF56565); // Red
      case ParkingEventType.towTruckSpotted:
        return const Color(0xFFF56565); // Red
      case ParkingEventType.permitRenewed:
        return const Color(0xFF48BB78); // Green
      case ParkingEventType.permitExpiring:
        return const Color(0xFFED8936); // Orange
      case ParkingEventType.moveVehicleReminder:
        return const Color(0xFFED8936); // Orange
      case ParkingEventType.sightingReported:
        return const Color(0xFF5E8A45); // Theme green
      case ParkingEventType.garbageReminder:
        return const Color(0xFF718096); // Gray
      case ParkingEventType.generalNotification:
        return const Color(0xFF4299E1); // Blue
    }
  }

  /// Whether this event type is considered important/urgent
  bool get isUrgent {
    switch (this) {
      case ParkingEventType.citationRiskAlert:
      case ParkingEventType.enforcementSpotted:
      case ParkingEventType.towTruckSpotted:
      case ParkingEventType.meterExpiring:
        return true;
      default:
        return false;
    }
  }
}

/// A single parking-related event in the user's history
class ParkingEvent {
  const ParkingEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.location,
    this.latitude,
    this.longitude,
    this.vehicleId,
    this.metadata = const {},
    this.read = false,
  });

  /// Unique identifier for this event
  final String id;

  /// Type of parking event
  final ParkingEventType type;

  /// Short title for the event
  final String title;

  /// Detailed description
  final String description;

  /// When this event occurred
  final DateTime timestamp;

  /// Optional location name
  final String? location;

  /// Optional latitude
  final double? latitude;

  /// Optional longitude
  final double? longitude;

  /// Optional vehicle ID this event relates to
  final String? vehicleId;

  /// Additional metadata (e.g., permit type, risk level)
  final Map<String, dynamic> metadata;

  /// Whether the user has seen this event
  final bool read;

  ParkingEvent copyWith({
    String? id,
    ParkingEventType? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? location,
    double? latitude,
    double? longitude,
    String? vehicleId,
    Map<String, dynamic>? metadata,
    bool? read,
  }) {
    return ParkingEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      vehicleId: vehicleId ?? this.vehicleId,
      metadata: metadata ?? this.metadata,
      read: read ?? this.read,
    );
  }

  factory ParkingEvent.fromJson(Map<String, dynamic> json) {
    return ParkingEvent(
      id: json['id'] as String,
      type: ParkingEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParkingEventType.generalNotification,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      vehicleId: json['vehicleId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'vehicleId': vehicleId,
    'metadata': metadata,
    'read': read,
  };

  @override
  String toString() => 'ParkingEvent(id: $id, type: $type, title: $title)';
}
