import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mkecitysmart/services/weather_service.dart';

void main() {
  group('WeatherService', () {
    test('fetchCurrent pulls grid then hourly forecast', () async {
      final responses = <http.Response>[
        http.Response(
          jsonEncode({
            'properties': {'forecastHourly': 'https://example.com/hourly'},
          }),
          200,
        ),
        http.Response(
          jsonEncode({
            'properties': {
              'periods': [
                {
                  'temperature': 72,
                  'probabilityOfPrecipitation': {'value': 10},
                  'shortForecast': 'Sunny',
                }
              ],
            },
          }),
          200,
        ),
      ];
      var call = 0;
      final service = WeatherService(
        client: MockClient((request) async => responses[call++]),
      );

      final summary = await service.fetchCurrent(lat: 43.0, lng: -87.0);

      expect(summary, isNotNull);
      expect(summary!.temperatureF, 72);
      expect(summary.shortForecast, 'Sunny');
      expect(summary.probabilityOfPrecip, 10);
    });

    test('fetchAlerts maps features and tolerates empty', () async {
      final service = WeatherService(
        client: MockClient((_) async {
          final payload = {
            'features': [
              {
                'properties': {
                  'event': 'Flood Watch',
                  'headline': 'Rising river',
                  'severity': 'Severe',
                  'effective': '2024-03-15T10:00:00Z',
                  'expires': '2024-03-16T10:00:00Z',
              },
            },
            {'properties': null}, // yields default alert
            ],
          };
          return http.Response(jsonEncode(payload), 200);
        }),
      );

      final alerts = await service.fetchAlerts(lat: 43.0, lng: -87.0);

      expect(alerts, hasLength(2));
      expect(alerts.first.event, 'Flood Watch');
      expect(alerts.first.severity, 'Severe');
      expect(alerts.first.expires, isNotNull);
    });

    test('returns null/empty on non-200', () async {
      final service = WeatherService(
        client: MockClient((_) async => http.Response('nope', 500)),
      );

      final summary = await service.fetchCurrent(lat: 0, lng: 0);
      final alerts = await service.fetchAlerts(lat: 0, lng: 0);

      expect(summary, isNull);
      expect(alerts, isEmpty);
    });
  });
}
