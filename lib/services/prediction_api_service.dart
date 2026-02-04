import 'dart:convert';

import '../models/parking_prediction.dart';
import 'api_client.dart';

class PredictionApiService {
  PredictionApiService(this._client);

  final ApiClient _client;

  Future<List<ParkingPrediction>> fetchPredictions({
    required double lat,
    required double lng,
    required int radiusMiles,
    bool includeEvents = true,
    bool includeWeather = true,
  }) async {
    final response = await _client.post(
      '/parking/predict',
      jsonBody: {
        'lat': lat,
        'lng': lng,
        'radiusMiles': radiusMiles,
        'includeEvents': includeEvents,
        'includeWeather': includeWeather,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map(
                (item) =>
                    ParkingPrediction.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  Future<List<ParkingPrediction>> fetchPoints({
    required double lat,
    required double lng,
    required int radiusMiles,
    bool includeEvents = true,
    bool includeWeather = true,
  }) async {
    final response = await _client.post(
      '/parking/predict/points',
      jsonBody: {
        'lat': lat,
        'lng': lng,
        'radiusMiles': radiusMiles,
        'includeEvents': includeEvents,
        'includeWeather': includeWeather,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map(
                (item) =>
                    ParkingPrediction.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }
}
