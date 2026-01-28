import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mkeparkapp_flutter/models/garbage_schedule.dart';
import 'package:mkeparkapp_flutter/services/garbage_schedule_service.dart';

void main() {
  group('GarbageScheduleService', () {
    test('fetchByLocation builds ArcGIS params and parses payload', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        final body = jsonEncode({
          'features': [
            {
              'attributes': {
                'route': '123',
                'address': '2469 N Holton St',
                'pickupDate': 1700000000000, // epoch millis
                'type': 'Recycling',
              },
            },
          ],
        });
        return http.Response(body, 200, headers: {'content-type': 'application/json'});
      });

      final service = GarbageScheduleService(
        baseUrl: 'https://example.com/garbage',
        authToken: 'token-123',
        client: mockClient,
      );

      final results = await service.fetchByLocation(latitude: 43.0673, longitude: -87.8946);

      expect(results, hasLength(1));
      final schedule = results.first;
      expect(schedule.type, PickupType.recycling);
      expect(schedule.routeId, '123');
      expect(schedule.address, contains('Holton'));
      expect(schedule.pickupDate.millisecondsSinceEpoch, 1700000000000);

      expect(capturedUri.path, '/garbage/query');
      expect(capturedUri.queryParameters['geometry'], '-87.894600,43.067300');
      expect(capturedUri.queryParameters['returnGeometry'], 'false');
      expect(capturedHeaders['Authorization'], 'Bearer token-123');
    });

    test('fetchByAddress handles string dates and fallbacks', () async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'features': [
            {
              'attributes': {
                'ROUTE': 'R-22',
                'ADDRESS': '401 W Wisconsin Ave',
                'NEXT_PICKUPDATE': '2024-03-15T05:00:00Z',
                'TYPE': 'Garbage',
              },
            },
            {
              'attributes': {
                'routeId': 'R-55',
                'location': 'Bay View',
                'PICKUPDAY': 'Monday',
                'material': 'Recycling',
              },
            },
          ],
        });
        return http.Response(body, 200);
      });

      final service = GarbageScheduleService(
        baseUrl: 'https://example.com/garbage',
        client: mockClient,
      );

      final results = await service.fetchByAddress('Wisconsin');
      expect(results, hasLength(2));

      final first = results.first;
      expect(first.routeId, 'R-22');
      expect(first.address, contains('Wisconsin'));
      expect(first.pickupDate.toUtc().year, 2024);
      expect(first.type, PickupType.garbage);

      final second = results[1];
      expect(second.type, PickupType.recycling);
      expect(second.address, contains('Bay View'));
      expect(second.pickupDate.weekday, DateTime.monday);
    });

    test('throws when backend responds with non-200', () async {
      final mockClient = MockClient((_) async => http.Response('nope', 500));
      final service = GarbageScheduleService(
        baseUrl: 'https://example.com/garbage',
        client: mockClient,
      );

      expect(
        () => service.fetchByAddress('Main St'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
