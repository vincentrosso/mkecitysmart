import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mkecitysmart/services/weather_service.dart';

void main() {
  group('WeatherSummary', () {
    test('stores temperature, forecast and precipitation', () {
      final summary = WeatherSummary(
        temperatureF: 32.0,
        shortForecast: 'Snow',
        probabilityOfPrecip: 80,
      );
      expect(summary.temperatureF, 32.0);
      expect(summary.shortForecast, 'Snow');
      expect(summary.probabilityOfPrecip, 80);
    });
  });

  group('WeatherAlert', () {
    test('stores alert fields including nullable dates', () {
      final alert = WeatherAlert(
        event: 'Winter Storm Warning',
        headline: 'Heavy snow expected',
        severity: 'Severe',
        effective: DateTime(2026, 2, 7),
        expires: DateTime(2026, 2, 8),
      );
      expect(alert.event, 'Winter Storm Warning');
      expect(alert.headline, 'Heavy snow expected');
      expect(alert.severity, 'Severe');
      expect(alert.effective, DateTime(2026, 2, 7));
      expect(alert.expires, DateTime(2026, 2, 8));
    });

    test('accepts null dates', () {
      final alert = WeatherAlert(
        event: 'Heat Advisory',
        headline: 'Hot',
        severity: 'Moderate',
        effective: null,
        expires: null,
      );
      expect(alert.effective, isNull);
      expect(alert.expires, isNull);
    });
  });

  group('WeatherService.fetchCurrent', () {
    test('returns WeatherSummary on valid two-step API response', () async {
      final client = http_testing.MockClient((request) async {
        if (request.url.host == 'api.weather.gov' &&
            request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/MKX/90,67/forecast/hourly',
              },
            }),
            200,
          );
        }
        if (request.url.path.contains('forecast/hourly')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'periods': [
                  {
                    'temperature': 28,
                    'shortForecast': 'Partly Cloudy',
                    'probabilityOfPrecipitation': {'value': 15},
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0389, lng: -87.9065);

      expect(result, isNotNull);
      expect(result!.temperatureF, 28.0);
      expect(result.shortForecast, 'Partly Cloudy');
      expect(result.probabilityOfPrecip, 15);
    });

    test('returns null when points endpoint returns non-200', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('Server error', 500),
      );
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNull);
    });

    test('returns null when points response has no forecastHourly', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({'properties': {}}), 200);
      });
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNull);
    });

    test('returns null when hourly forecast returns non-200', () async {
      final client = http_testing.MockClient((request) async {
        if (request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/X/0,0/forecast/hourly',
              },
            }),
            200,
          );
        }
        return http.Response('Error', 503);
      });
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNull);
    });

    test('returns null when hourly periods list is empty', () async {
      final client = http_testing.MockClient((request) async {
        if (request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/X/0,0/forecast/hourly',
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'properties': {'periods': []},
          }),
          200,
        );
      });
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNull);
    });

    test('returns null when temperature is missing from first period', () async {
      final client = http_testing.MockClient((request) async {
        if (request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/X/0,0/forecast/hourly',
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'properties': {
              'periods': [
                {
                  'shortForecast': 'Cloudy',
                  'probabilityOfPrecipitation': {'value': 10},
                },
              ],
            },
          }),
          200,
        );
      });
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNull);
    });

    test('handles null precipitation value gracefully', () async {
      final client = http_testing.MockClient((request) async {
        if (request.url.path.startsWith('/points/')) {
          return http.Response(
            jsonEncode({
              'properties': {
                'forecastHourly':
                    'https://api.weather.gov/gridpoints/X/0,0/forecast/hourly',
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'properties': {
              'periods': [
                {
                  'temperature': 55,
                  'shortForecast': 'Sunny',
                  'probabilityOfPrecipitation': {'value': null},
                },
              ],
            },
          }),
          200,
        );
      });
      final service = WeatherService(client: client);
      final result = await service.fetchCurrent(lat: 43.0, lng: -87.9);
      expect(result, isNotNull);
      expect(result!.temperatureF, 55.0);
      expect(result.probabilityOfPrecip, 0);
    });
  });

  group('WeatherService.fetchAlerts', () {
    test('returns list of WeatherAlerts on valid response', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {
                  'event': 'Winter Storm Warning',
                  'headline': 'Heavy snow tonight',
                  'severity': 'Severe',
                  'effective': '2026-02-07T18:00:00Z',
                  'expires': '2026-02-08T06:00:00Z',
                },
              },
              {
                'properties': {
                  'event': 'Wind Advisory',
                  'headline': 'Gusty winds',
                  'severity': 'Moderate',
                  'effective': '2026-02-07T12:00:00Z',
                  'expires': '2026-02-07T20:00:00Z',
                },
              },
            ],
          }),
          200,
        );
      });
      final service = WeatherService(client: client);
      final alerts = await service.fetchAlerts(lat: 43.0389, lng: -87.9065);

      expect(alerts, hasLength(2));
      expect(alerts[0].event, 'Winter Storm Warning');
      expect(alerts[0].severity, 'Severe');
      expect(alerts[1].event, 'Wind Advisory');
    });

    test('returns empty list when API returns non-200', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response('Error', 500),
      );
      final service = WeatherService(client: client);
      final alerts = await service.fetchAlerts(lat: 43.0, lng: -87.9);
      expect(alerts, isEmpty);
    });

    test('returns empty list when no features in response', () async {
      final client = http_testing.MockClient(
        (_) async => http.Response(jsonEncode({'features': []}), 200),
      );
      final service = WeatherService(client: client);
      final alerts = await service.fetchAlerts(lat: 43.0, lng: -87.9);
      expect(alerts, isEmpty);
    });

    test('handles alerts with missing optional fields', () async {
      final client = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'properties': {'event': 'Flood Watch'},
              },
            ],
          }),
          200,
        );
      });
      final service = WeatherService(client: client);
      final alerts = await service.fetchAlerts(lat: 43.0, lng: -87.9);

      expect(alerts, hasLength(1));
      expect(alerts[0].event, 'Flood Watch');
      expect(alerts[0].headline, 'Alert in your area');
      expect(alerts[0].severity, 'Unknown');
      expect(alerts[0].effective, isNull);
      expect(alerts[0].expires, isNull);
    });
  });
}
