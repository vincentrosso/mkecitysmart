import 'dart:convert';

import 'package:http/http.dart' as http;

import 'safe_http_client.dart';

const String apiBaseUrl = String.fromEnvironment(
  'CITYSMART_API_BASE',
  defaultValue: 'https://api.citysmart-milwaukee.com/v1',
);

const String apiKey = String.fromEnvironment(
  'CITYSMART_API_KEY',
  defaultValue: '',
);

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? SafeHttpClient();

  final http.Client _client;

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? jsonBody,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'X-API-Key': apiKey,
      ...?headers,
    };
    final body = jsonBody == null ? null : jsonEncode(jsonBody);
    return _client.post(uri, headers: mergedHeaders, body: body);
  }
}
