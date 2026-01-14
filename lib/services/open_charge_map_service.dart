import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ev_station.dart';

const String _ocmApiKey = String.fromEnvironment(
  'OCM_API_KEY',
  defaultValue: 'c067a985-6c35-498c-a5ea-e79fb8df450a',
);

class OpenChargeMapService {
  OpenChargeMapService({http.Client? client}) : _client = client ?? http.Client();

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

    final resp = await _client.get(uri, headers: {
      'Accept': 'application/json',
      'X-API-Key': _ocmApiKey,
    });

    if (resp.statusCode != 200) {
      throw Exception('OCM status ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) => _mapStation(e)).whereType<EVStation>().toList();
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

    final totalPorts = connections.isEmpty ? 1 : connections.length;
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
}
