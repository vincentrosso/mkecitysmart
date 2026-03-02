import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ev_station.dart';

/// NREL Alternative Fuel Stations API (US Dept of Energy).
///
/// More reliable and comprehensive than OpenChargeMap for US locations.
/// Register for a free key at https://developer.nrel.gov/signup/
const String _nrelApiKey = String.fromEnvironment(
  'NREL_API_KEY',
  defaultValue: 'DEMO_KEY',
);

class NRELChargingService {
  NRELChargingService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://developer.nrel.gov/api/alt-fuel-stations/v1';

  /// Fetch EV stations near a location, sorted by distance.
  Future<List<EVStation>> fetchStations({
    required double lat,
    required double lng,
    double radiusMiles = 10,
    int maxResults = 100,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/nearest.json'
      '?api_key=$_nrelApiKey'
      '&fuel_type=ELEC'
      '&latitude=$lat'
      '&longitude=$lng'
      '&radius=$radiusMiles'
      '&limit=$maxResults'
      '&status=E,T' // E = open, T = temporarily unavailable
      '&access=public',
    );

    debugPrint('NREL: Fetching stations near $lat,$lng');

    try {
      final resp = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('NREL: Response status ${resp.statusCode}');

      if (resp.statusCode != 200) {
        final preview = resp.body.length > 200
            ? resp.body.substring(0, 200)
            : resp.body;
        debugPrint('NREL: Error body $preview');
        throw Exception('NREL status ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = data['fuel_stations'] as List<dynamic>? ?? [];
      debugPrint('NREL: Found ${results.length} stations '
          '(${data['total_results']} total in radius)');

      final stations = results
          .map((e) => _mapStation(e))
          .whereType<EVStation>()
          .toList();
      debugPrint('NREL: Parsed ${stations.length} stations');
      return stations;
    } catch (e) {
      debugPrint('NREL: Exception during fetch: $e');
      rethrow;
    }
  }

  EVStation? _mapStation(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    final id = json['id']?.toString() ?? '';
    final name = (json['station_name'] as String?) ?? 'EV Charger';
    final address = _formatAddress(json);
    final lat = (json['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (json['longitude'] as num?)?.toDouble() ?? 0;
    final network = (json['ev_network'] as String?) ?? 'Unknown';
    final statusCode = (json['status_code'] as String?) ?? 'E';

    // Connector types
    final rawConnectors =
        (json['ev_connector_types'] as List?)?.cast<String>() ?? [];
    final connectorTypes = rawConnectors.map(_friendlyConnector).toList();
    if (connectorTypes.isEmpty) connectorTypes.add('Unknown');

    // Port counts
    final level2 = (json['ev_level2_evse_num'] as num?)?.toInt() ?? 0;
    final dcFast = (json['ev_dc_fast_num'] as num?)?.toInt() ?? 0;
    final totalPorts = level2 + dcFast;

    // Power — estimate from charger type
    final maxPower = dcFast > 0 ? 150.0 : (level2 > 0 ? 7.2 : 0.0);

    // Status
    final isAvailable = statusCode == 'E';
    final status = _statusLabel(statusCode);

    // Pricing
    final pricingStr = json['ev_pricing'] as String?;
    final price = _parsePrice(pricingStr, network);

    // Notes — combine hours + pricing
    final hours = json['access_days_time'] as String?;
    final notes = [
      if (hours != null && hours.isNotEmpty) hours,
      if (pricingStr != null && pricingStr.isNotEmpty) pricingStr,
    ].join(' · ');

    return EVStation(
      id: id,
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
      network: network,
      connectorTypes: connectorTypes,
      availablePorts: isAvailable ? totalPorts : 0,
      totalPorts: totalPorts == 0 ? 1 : totalPorts,
      maxPowerKw: maxPower == 0 ? 7.2 : maxPower,
      pricePerKwh: price,
      status: status,
      notes: notes.isEmpty ? null : notes,
    );
  }

  String _formatAddress(Map<String, dynamic> json) {
    final parts = [
      json['street_address'],
      json['city'],
      json['state'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Address unavailable' : parts.join(', ');
  }

  String _friendlyConnector(String raw) {
    switch (raw) {
      case 'J1772':
        return 'J1772 (Level 2)';
      case 'J1772COMBO':
        return 'CCS (DC Fast)';
      case 'CHADEMO':
        return 'CHAdeMO (DC Fast)';
      case 'TESLA':
        return 'Tesla';
      case 'NEMA1450':
        return 'NEMA 14-50';
      case 'NEMA515':
        return 'NEMA 5-15';
      case 'NEMA520':
        return 'NEMA 5-20';
      default:
        return raw;
    }
  }

  String _statusLabel(String code) {
    switch (code) {
      case 'E':
        return 'Available';
      case 'T':
        return 'Temporarily Unavailable';
      case 'P':
        return 'Planned';
      default:
        return 'Unknown';
    }
  }

  double _parsePrice(String? pricing, String network) {
    if (pricing != null && pricing.isNotEmpty) {
      final match = RegExp(r'(\d+[.,]?\d*)').firstMatch(pricing);
      if (match != null) {
        return double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
      }
    }
    // Fall back to estimated network pricing
    return estimatedPriceForNetwork(network) ?? 0;
  }

  /// Estimated per-kWh pricing for known networks when API has no data.
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
