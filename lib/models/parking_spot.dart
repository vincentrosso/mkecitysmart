class ParkingSpot {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final SpotType type;
  final SpotStatus status;
  final double? hourlyRate;
  final double? maxDuration;
  final List<String> restrictions;
  final double distance;
  final DateTime? availableUntil;

  const ParkingSpot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.type,
    required this.status,
    this.hourlyRate,
    this.maxDuration,
    required this.restrictions,
    required this.distance,
    this.availableUntil,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      type: SpotType.values.firstWhere((e) => e.name == json['type']),
      status: SpotStatus.values.firstWhere((e) => e.name == json['status']),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      maxDuration: (json['maxDuration'] as num?)?.toDouble(),
      restrictions: List<String>.from(json['restrictions'] as List),
      distance: (json['distance'] as num).toDouble(),
      availableUntil: json['availableUntil'] != null
          ? DateTime.parse(json['availableUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'type': type.name,
      'status': status.name,
      'hourlyRate': hourlyRate,
      'maxDuration': maxDuration,
      'restrictions': restrictions,
      'distance': distance,
      'availableUntil': availableUntil?.toIso8601String(),
    };
  }
}

enum SpotType {
  street,
  lot,
  garage,
  metered,
  permit,
  handicap,
  loading,
  motorcycle,
}

enum SpotStatus { available, occupied, reserved, outOfOrder, restricted }
