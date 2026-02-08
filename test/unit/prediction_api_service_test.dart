import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'package:mkecitysmart/services/api_client.dart';

@GenerateMocks([ApiClient])
void main() {
  group(
    'PredictionApiService',
    () {},
    skip:
        'Legacy mkecitysmart-era test; update/remove when reintroducing PredictionApiService',
  );
}

/*
  group('PredictionApiService', () {
    late MockApiClient mockClient;
    late PredictionApiService service;

    setUp(() {
      mockClient = MockApiClient();
      service = PredictionApiService(mockClient);
    });

    test('returns parsed predictions on success', () async {
      final body = '[{"score":0.8,"lat":1.0,"lng":2.0,"id":"p1","blockId":"b1","hour":1,"dayOfWeek":2}]';
      when(mockClient.post(any, jsonBody: anyNamed('jsonBody'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(body, 200));

      final result = await service.fetchPredictions(lat: 1, lng: 2, radiusMiles: 5);

      expect(result, hasLength(1));
      expect(result.first.score, 0.8);
      expect(result.first.id, 'p1');
      expect(result.first.blockId, 'b1');
    });

    test('returns empty list on non-200 response', () async {
      when(mockClient.post(any, jsonBody: anyNamed('jsonBody'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('oops', 500));

      final result = await service.fetchPredictions(lat: 1, lng: 2, radiusMiles: 5);

      expect(result, isEmpty);
    });

    test('returns empty list on malformed body', () async {
      when(mockClient.post(any, jsonBody: anyNamed('jsonBody'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{"not": "a list"}', 200));

      final result = await service.fetchPoints(lat: 1, lng: 2, radiusMiles: 5);

      expect(result, isEmpty);
    });
  });
}

*/
