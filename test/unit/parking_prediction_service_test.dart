import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/parking_prediction_service.dart';

void main() {
  group('ParkingPredictionService', () {
    final service = ParkingPredictionService();
    final baseTime = DateTime(2024, 3, 15, 8); // weekday morning rush hour.

    test('predict returns lower availability during rush hour', () {
      final rushScore = service.predict(
        when: baseTime,
        latitude: 43.0,
        longitude: -87.0,
        eventLoad: 0.2,
      );
      final lateNight = service.predict(
        when: DateTime(2024, 3, 16, 1),
        latitude: 43.0,
        longitude: -87.0,
      );

      expect(rushScore, lessThan(lateNight));
      expect(rushScore, inInclusiveRange(0.0, 1.0));
      expect(lateNight, inInclusiveRange(0.0, 1.0));
    });

    test('predictNearby returns requested sample count with varied coords', () {
      final results = service.predictNearby(
        when: baseTime,
        latitude: 43.05,
        longitude: -87.9,
        samples: 6,
        eventLoad: 0.1,
        cityBias: 0.2,
      );

      expect(results, hasLength(6));
      final uniqueCoords = results
          .map((p) => '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
          .toSet();
      expect(uniqueCoords.length, greaterThan(3));
      expect(
        results.every((p) => p.score >= 0 && p.score <= 1),
        isTrue,
      );
    });
  });
}
