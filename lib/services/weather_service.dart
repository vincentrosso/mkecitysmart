import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherSummary {
  WeatherSummary({
    required this.temperatureF,
    required this.shortForecast,
    required this.probabilityOfPrecip,
  });

  final double temperatureF;
  final String shortForecast;
  final int probabilityOfPrecip;
}

class WeatherAlert {
  WeatherAlert({
    required this.event,
    required this.headline,
    required this.severity,
    required this.effective,
    required this.expires,
  });

  final String event;
  final String headline;
  final String severity;
  final DateTime? effective;
  final DateTime? expires;
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherSummary?> fetchCurrent({
    required double lat,
    required double lng,
  }) async {
    // Step 1: resolve grid via points endpoint
    final pointsUri = Uri.parse(
        'https://api.weather.gov/points/${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}');
    final pointsResp = await _client
        .get(pointsUri, headers: _headers())
        .timeout(const Duration(seconds: 10));
    if (pointsResp.statusCode != 200) return null;
    final pointsJson = jsonDecode(pointsResp.body) as Map<String, dynamic>;
    final hourlyUrl =
        (pointsJson['properties']?['forecastHourly'] as String?)?.trim();
    if (hourlyUrl == null) return null;

    // Step 2: grab first period from hourly forecast
    final hourlyResp = await _client
        .get(Uri.parse(hourlyUrl), headers: _headers())
        .timeout(const Duration(seconds: 10));
    if (hourlyResp.statusCode != 200) return null;
    final hourlyJson = jsonDecode(hourlyResp.body) as Map<String, dynamic>;
    final periods = hourlyJson['properties']?['periods'] as List<dynamic>?;
    if (periods == null || periods.isEmpty) return null;
    final first = periods.first as Map<String, dynamic>;
    final temp = (first['temperature'] as num?)?.toDouble();
    final precip = ((first['probabilityOfPrecipitation']?['value'] as num?)
                ?.toDouble())
            ?.round() ??
        0;
    final short = (first['shortForecast'] as String?) ?? 'N/A';
    if (temp == null) return null;

    return WeatherSummary(
      temperatureF: temp,
      shortForecast: short,
      probabilityOfPrecip: precip,
    );
  }

  Future<List<WeatherAlert>> fetchAlerts({
    required double lat,
    required double lng,
  }) async {
    final alertsUri = Uri.parse(
        'https://api.weather.gov/alerts/active?point=${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}');
    final resp = await _client
        .get(alertsUri, headers: _headers())
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return const [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? const [];
    return features.map((f) => _mapAlert(f)).whereType<WeatherAlert>().toList();
  }

  WeatherAlert? _mapAlert(dynamic f) {
    if (f is! Map<String, dynamic>) return null;
    final props = f['properties'] as Map<String, dynamic>? ?? {};
    return WeatherAlert(
      event: (props['event'] as String?) ?? 'Weather alert',
      headline: (props['headline'] as String?) ??
          (props['description'] as String?) ??
          'Alert in your area',
      severity: (props['severity'] as String?) ?? 'Unknown',
      effective: _parseDate(props['effective']),
      expires: _parseDate(props['expires']),
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, String> _headers() => const {
        'Accept': 'application/geo+json',
        'User-Agent': 'mkecitysmart/1.0 (support@mkecitysmart.com)',
      };
}
