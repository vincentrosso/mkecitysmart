import 'package:flutter_test/flutter_test.dart';
import 'package:mkecitysmart/services/city_ticket_stats_service.dart';

void main() {
  group('CityTicketStatsService', () {
    final service = CityTicketStatsService();

    test('returns higher bias for known cities', () {
      final nyc = service.lookup(
        cityId: 'nyc',
        when: DateTime(2024, 1, 10),
        latitude: 40.7128,
        longitude: -74.0060,
      );
      final defaultCity = service.lookup(
        cityId: 'unknown',
        when: DateTime(2024, 1, 10),
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(nyc.monthlyFactor, greaterThan(defaultCity.monthlyFactor));
      expect(nyc.hotspotDensity, greaterThan(defaultCity.hotspotDensity));
    });

    test('seasonality adjusts month multiplier', () {
      final winter = service.lookup(
        cityId: 'chi',
        when: DateTime(2024, 1, 5),
        latitude: 41.8,
        longitude: -87.6,
      );
      final summer = service.lookup(
        cityId: 'chi',
        when: DateTime(2024, 7, 5),
        latitude: 41.8,
        longitude: -87.6,
      );

      expect(winter.monthlyFactor, greaterThan(summer.monthlyFactor));
      expect(winter.hotspotDensity, inInclusiveRange(0.0, 1.0));
      expect(summer.hotspotDensity, inInclusiveRange(0.0, 1.0));
    });
  });
}
