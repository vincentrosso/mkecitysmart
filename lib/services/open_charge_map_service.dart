import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ev_station.dart';

const String _ocmApiKey = String.fromEnvironment(
  'OCM_API_KEY',
  defaultValue: 'c067a985-6c35-498c-a5ea-e79fb8df450a',
);

class OpenChargeMapService {
  OpenChargeMapService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<EVStation>> fetchStations({
    required double lat,
    required double lng,
    double distanceKm = 15,
    int maxResults = 40,
  }) async {
    final uri = Uri.parse(
      'https://api.openchargemap.io/v3/poi/'
      '?output=json'
      '&latitude=$lat'
      '&longitude=$lng'
      '&distance=$distanceKm'
      '&distanceunit=KM'
      '&maxresults=$maxResults'
      '&key=$_ocmApiKey',
    );

    debugPrint('OpenChargeMap: Fetching stations near $lat,$lng');
    debugPrint('OpenChargeMap: URL: $uri');

    try {
      final resp = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'X-API-Key': _ocmApiKey,
              'User-Agent':
                  'MKE-CitySmart-App/1.0 (iOS; contact@mkecitysmart.com)',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('OpenChargeMap: Response status ${resp.statusCode}');

      if (resp.statusCode == 503) {
        // API temporarily blocking - return empty list with warning
        debugPrint(
          'OpenChargeMap: API temporarily unavailable (503). Try again later.',
        );
        return [];
      }

      if (resp.statusCode != 200) {
        final preview = resp.body.length > 200
            ? resp.body.substring(0, 200)
            : resp.body;
        debugPrint('OpenChargeMap: Error body $preview');
        throw Exception('OCM status ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as List<dynamic>;
      debugPrint('OpenChargeMap: Found ${data.length} raw stations');
      final stations = data
          .map((e) => _mapStation(e))
          .whereType<EVStation>()
          .toList();
      debugPrint('OpenChargeMap: Parsed ${stations.length} stations');
      return stations;
    } catch (e) {
      debugPrint('OpenChargeMap: Exception during fetch: $e');
      rethrow;
    }
  }

  EVStation? _mapStation(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final address = json['AddressInfo'] as Map<String, dynamic>?;
    final connections = (json['Connections'] as List?) ?? const [];
    final status = (json['StatusType']?['Title'] as String?) ?? 'Unknown';
    final usageCost = json['UsageCost'] as String?;

    final isAvailable = _isAvailableStatus(status);
    final connectorTypes = connections
        .map((c) => (c['ConnectionType']?['Title'] as String?)?.trim())
        .whereType<String>()
        .toList();

    final maxPower = connections
        .map((c) => (c['PowerKW'] as num?)?.toDouble() ?? 0)
        .fold<double>(0, (a, b) => b > a ? b : a);

    // Use NumberOfPoints from API (actual port count), or sum Quantity from
    // each connection, or fall back to counting connection types.
    final numberOfPoints = (json['NumberOfPoints'] as num?)?.toInt() ?? 0;
    final quantitySum = connections
        .map((c) => (c['Quantity'] as num?)?.toInt() ?? 1)
        .fold<int>(0, (a, b) => a + b);
    // Pick the highest non-zero value for best accuracy
    int totalPorts = [
      numberOfPoints,
      quantitySum,
      connections.length,
    ].where((n) => n > 0).fold<int>(1, (a, b) => b > a ? b : a);
    final availablePorts = isAvailable ? totalPorts : 0;

    return EVStation(
      id: '${json['ID'] ?? address?['ID'] ?? ''}',
      name: address?['Title'] as String? ?? 'EV Charger',
      address: _formatAddress(address),
      latitude: (address?['Latitude'] as num?)?.toDouble() ?? 0,
      longitude: (address?['Longitude'] as num?)?.toDouble() ?? 0,
      network: (json['OperatorInfo']?['Title'] as String?) ?? 'Unknown',
      connectorTypes: connectorTypes.isEmpty ? ['Unknown'] : connectorTypes,
      availablePorts: availablePorts,
      totalPorts: totalPorts == 0 ? availablePorts : totalPorts,
      maxPowerKw: maxPower == 0 ? 11 : maxPower,
      pricePerKwh: _parsePrice(usageCost),
      status: status,
      notes: usageCost,
    );
  }

  bool _isAvailableStatus(String status) {
    final s = status.toLowerCase();
    return s.contains('available') ||
        s.contains('operational') ||
        s.contains('in service') ||
        s.contains('in-service') ||
        s.contains('active');
  }

  String _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null) return 'Address unavailable';
    final parts = [
      addr['AddressLine1'],
      addr['Town'],
      addr['StateOrProvince'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  double _parsePrice(String? usageCost) {
    if (usageCost == null) return 0;
    final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(usageCost);
    if (match == null) return 0;
    return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
  }

  /// Estimated per-kWh pricing for known networks when the API has no data.
  /// Sources: public rate schedules as of early 2026.
  static double? estimatedPriceForNetwork(String network) {
    final n = network.toLowerCase();
    if (n.contains('tesla')) return 0.40;
    if (n.contains('evgo')) return 0.35;
    if (n.contains('chargepoint')) return 0.30;
    if (n.contains('electrify america')) return 0.48;
    if (n.contains('blink')) return 0.49;
    if (n.contains('flo')) return 0.35;
    if (n.contains('ev connect')) return 0.30;
    return null;
  }
}
