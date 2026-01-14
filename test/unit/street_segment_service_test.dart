import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:mkecitysmart/services/street_segment_service.dart';

void main() {
  group('StreetSegmentService', () {
    test('returns null on non-200 response', () async {
      final client = MockClient((request) async => http.Response('err', 500));
      final service = StreetSegmentService(client: client);

      final result = await service.fetchByPoint(lat: 0, lng: 0);

      expect(result, isNull);
    });

    test('returns null when no features', () async {
      final payload = jsonEncode({'features': []});
      final client = MockClient((request) async => http.Response(payload, 200));
      final service = StreetSegmentService(client: client);

      final result = await service.fetchByPoint(lat: 0, lng: 0);

      expect(result, isNull);
    });

    test('parses street segment attributes', () async {
      final payload = jsonEncode({
        'features': [
          {
            'attributes': {
              'StreetName': 'Main',
              'StreetType': 'St',
              'SegmentType': 'Two Way',
            }
          }
        ]
      });
      final client = MockClient((request) async => http.Response(payload, 200));
      final service = StreetSegmentService(client: client);

      final result = await service.fetchByPoint(lat: 43.0, lng: -87.0);

      expect(result, isNotNull);
      expect(result!.streetName, 'Main');
      expect(result.streetType, 'St');
      expect(result.segmentType, 'Two Way');
      expect(result.display(), 'Main St (Two Way)');
    });
  });
}
