import 'dart:convert';

import 'package:http/http.dart' as http;

const String apiBaseUrl = String.fromEnvironment(
  'CITYSMART_API_BASE',
  defaultValue: 'https://api.citysmart-milwaukee.com/v1',
);

const String apiKey = String.fromEnvironment(
  'CITYSMART_API_KEY',
  defaultValue: '',
);

class ApiClient {
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
    return http.post(uri, headers: mergedHeaders, body: body);
  }
}
