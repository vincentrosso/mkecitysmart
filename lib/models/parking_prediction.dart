class ParkingPrediction {
  const ParkingPrediction({
    required this.id,
    required this.blockId,
    required this.lat,
    required this.lng,
    required this.score,
    required this.hour,
    required this.dayOfWeek,
    this.eventScore = 0,
    this.weatherScore = 0,
  });

  final String id;
  final String blockId;
  final double lat;
  final double lng;

  /// Probability 0–1 of finding a spot.
  final double score;
  final int hour;
  final int dayOfWeek;
  final double eventScore;
  final double weatherScore;

  Map<String, dynamic> toJson() => {
    'id': id,
    'blockId': blockId,
    'lat': lat,
    'lng': lng,
    'score': score,
    'hour': hour,
    'dayOfWeek': dayOfWeek,
    'eventScore': eventScore,
    'weatherScore': weatherScore,
  };

  factory ParkingPrediction.fromJson(Map<String, dynamic> json) {
    return ParkingPrediction(
      id: json['id'] as String? ?? '',
      blockId: json['blockId'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      hour: json['hour'] as int? ?? 0,
      dayOfWeek: json['dayOfWeek'] as int? ?? 0,
      eventScore: (json['eventScore'] as num?)?.toDouble() ?? 0,
      weatherScore: (json['weatherScore'] as num?)?.toDouble() ?? 0,
    );
  }
}
