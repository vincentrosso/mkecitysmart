import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/ticket_risk_prediction_service.dart';

void main() {
  group('TicketRiskPredictionService', () {
    final service = TicketRiskPredictionService();
    final baseTime = DateTime(2024, 3, 15, 8); // weekday morning rush.

    test('predictRisk combines factors and clamps between 0 and 1', () {
      final risk = service.predictRisk(
        when: baseTime,
        latitude: 43.0,
        longitude: -87.0,
        eventLoad: 1,
        historicalDensity: 1,
      );
      expect(risk, inInclusiveRange(0.0, 1.0));
      expect(risk, greaterThan(0.5));
    });

    test('high congestion produces high risk message', () {
      final risk = service.predictRiskWithCityStats(
        when: baseTime,
        latitude: 43.0,
        longitude: -87.0,
        eventLoad: 1,
        historicalDensity: 1,
        monthlyFactor: 1,
        cityHotspotDensity: 1,
      );
      expect(risk, closeTo(1.0, 0.0001));
      expect(
        service.riskMessage(risk),
        contains('Very high ticket risk'),
      );
    });

    test('low congestion produces low risk and message', () {
      final risk = service.predictRisk(
        when: DateTime(2024, 3, 16, 3), // weekend early morning
        latitude: 43.0,
        longitude: -87.0,
        eventLoad: 0,
        historicalDensity: 0,
      );
      expect(risk, lessThan(0.5));
      expect(service.riskMessage(risk), contains('Low ticket risk'));
    });

    test('moderate scores map to moderate messaging', () {
      final risk = service.predictRiskWithCityStats(
        when: DateTime(2024, 3, 15, 12), // midday
        latitude: 43.0,
        longitude: -87.0,
        historicalDensity: 0.5,
        eventLoad: 0.3,
        cityHotspotDensity: 0.2,
      );
      expect(risk, inInclusiveRange(0.5, 0.8));
      expect(service.riskMessage(risk), contains('Moderate ticket risk'));
    });
  });
}
