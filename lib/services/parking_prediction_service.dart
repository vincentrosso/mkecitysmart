import 'dart:math';

/// Simple parking availability predictor.
///
/// Inputs:
/// - day/time (DateTime)
/// - location (lat/lng)
/// - optional event load (0-1)
///
/// Output:
/// - A predicted probability (0-1) of finding a spot nearby.
class ParkingPredictionService {
  /// Predict availability score (0-1) for a single point.
  double predict({
    required DateTime when,
    required double latitude,
    required double longitude,
    double eventLoad = 0.0, // 0 (no event) to 1 (major event)
    double cityBias = 0.0, // simple city modifier 0-1
  }) {
    final hourScore = _hourFactor(when.hour);
    final dayScore = _dayFactor(when.weekday);
    final eventPenalty = 1 - (eventLoad.clamp(0, 1) * 0.35);
    final locationNoise = _locationNoise(latitude, longitude);
    final cityFactor = 1 - cityBias.clamp(0, 1) * 0.2; // higher bias lowers availability slightly

    // Combine factors; clamp to [0,1].
    final raw = hourScore * 0.4 +
        dayScore * 0.3 +
        eventPenalty * 0.2 +
        locationNoise * 0.1;
    return (raw * cityFactor).clamp(0.0, 1.0);
  }

  /// Predict a set of nearby points (simple grid fan-out).
  List<PredictedPoint> predictNearby({
    required DateTime when,
    required double latitude,
    required double longitude,
    double eventLoad = 0,
    int samples = 5,
    double cityBias = 0.0,
  }) {
    final rng = Random(latitude.hashCode ^ longitude.hashCode ^ when.hashCode);
    return List.generate(samples, (i) {
      final offsetLat = (rng.nextDouble() - 0.5) * 0.002; // ~200m
      final offsetLng = (rng.nextDouble() - 0.5) * 0.002;
      final lat = latitude + offsetLat;
      final lng = longitude + offsetLng;
      final score = predict(
        when: when,
        latitude: lat,
        longitude: lng,
        eventLoad: eventLoad,
        cityBias: cityBias,
      );
      return PredictedPoint(latitude: lat, longitude: lng, score: score);
    });
  }

  double _hourFactor(int hour) {
    // Higher at late night/early morning, lower at rush.
    if (hour >= 7 && hour <= 9) return 0.25; // morning rush
    if (hour >= 16 && hour <= 19) return 0.3; // evening rush
    if (hour >= 11 && hour <= 13) return 0.45; // midday
    if (hour >= 22 || hour <= 5) return 0.75; // late night
    return 0.6; // shoulder hours
  }

  double _dayFactor(int weekday) {
    // 1=Mon ... 7=Sun
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return 0.65; // weekends slightly easier
    }
    return 0.5; // weekdays
  }

  double _locationNoise(double lat, double lng) {
    // Simple, deterministic pseudo-noise based on coords.
    final hash = (lat * 1000).round() ^ (lng * 1000).round();
    return (hash % 100) / 100.0; // 0-0.99
  }
}

class PredictedPoint {
  const PredictedPoint({
    required this.latitude,
    required this.longitude,
    required this.score,
  });

  final double latitude;
  final double longitude;
  final double score; // 0-1 likelihood of finding a spot
}
