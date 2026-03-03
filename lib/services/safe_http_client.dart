import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A wrapper around [http.Client] that catches network-level exceptions
/// (SocketException, ClientException) and returns a synthetic error response
/// instead of letting them propagate to Crashlytics as unhandled crashes.
///
/// Usage:
///   final client = SafeHttpClient(http.Client());
///   final resp = await client.get(uri); // Never throws on network errors
///   if (resp.statusCode == 0) { /* network error */ }
class SafeHttpClient extends http.BaseClient {
  SafeHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      return await _inner.send(request);
    } on SocketException catch (e) {
      debugPrint('[SafeHttpClient] Network unreachable: $e');
      return _errorResponse(request, 'Network is unreachable');
    } on http.ClientException catch (e) {
      debugPrint('[SafeHttpClient] Client error: $e');
      return _errorResponse(request, 'Connection failed');
    } on HandshakeException catch (e) {
      debugPrint('[SafeHttpClient] TLS error: $e');
      return _errorResponse(request, 'Secure connection failed');
    }
  }

  /// Returns a synthetic response with status 0 and an error body.
  /// Callers checking `resp.statusCode != 200` will gracefully skip.
  static http.StreamedResponse _errorResponse(
    http.BaseRequest request,
    String reason,
  ) {
    return http.StreamedResponse(
      Stream.value(reason.codeUnits),
      0, // status 0 = network error (never a real HTTP status)
      request: request,
      reasonPhrase: reason,
    );
  }

  @override
  void close() => _inner.close();
}
