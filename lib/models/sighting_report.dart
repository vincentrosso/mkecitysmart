enum SightingType { parkingEnforcer, towTruck }

class SightingReport {
  const SightingReport({
    required this.id,
    required this.type,
    required this.location,
    this.latitude,
    this.longitude,
    required this.notes,
    required this.reportedAt,
    this.occurrences = 1,
  });

  final String id;
  final SightingType type;
  final String location;
  final double? latitude;
  final double? longitude;
  final String notes;
  final DateTime reportedAt;
  final int occurrences;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'reportedAt': reportedAt.toIso8601String(),
      'occurrences': occurrences,
    };
  }

  factory SightingReport.fromJson(Map<String, dynamic> json) {
    final typeName =
        json['type'] as String? ?? SightingType.parkingEnforcer.name;
    return SightingReport(
      id: json['id'] as String? ?? '',
      type: SightingType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => SightingType.parkingEnforcer,
      ),
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      reportedAt:
          DateTime.tryParse(json['reportedAt'] as String? ?? '') ??
          DateTime.now(),
      occurrences: json['occurrences'] as int? ?? 1,
    );
  }
}
