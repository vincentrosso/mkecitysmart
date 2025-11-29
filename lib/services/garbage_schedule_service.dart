import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/garbage_schedule.dart';

class GarbageScheduleService {
  GarbageScheduleService({required this.baseUrl, this.authToken});

  final String baseUrl;
  final String? authToken;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<GarbageSchedule>> fetchByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      'geometry': '$longitude,$latitude',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return features.map(_fromFeature).toList();
  }

  Future<List<GarbageSchedule>> fetchByAddress(String address) async {
    final where = "UPPER(ADDRESS) LIKE '%${address.toUpperCase()}%'";
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      'where': where,
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await http.get(uri, headers: _headers());
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return features.map(_fromFeature).toList();
  }

  GarbageSchedule _fromFeature(Map<String, dynamic> feature) {
    final attrs = feature['attributes'] as Map<String, dynamic>? ?? {};
    final typeStr = (attrs['type'] ??
            attrs['TYPE'] ??
            attrs['service'] ??
            attrs['SERVICE'] ??
            attrs['material'] ??
            '')
        .toString()
        .toLowerCase();
    final type =
        typeStr.contains('recycl') ? PickupType.recycling : PickupType.garbage;
    final route =
        (attrs['route'] ?? attrs['ROUTE'] ?? attrs['routeId'] ?? 'unknown')
            .toString();
    final addr = (attrs['address'] ??
            attrs['ADDRESS'] ??
            attrs['location'] ??
            attrs['LOCATION'] ??
            '')
        .toString();

    final dynamic pickupRaw = attrs['pickupDate'] ??
        attrs['PICKUPDATE'] ??
        attrs['nextPickup'] ??
        attrs['NEXT_PICKUP'] ??
        attrs['NEXT_PICKUPDATE'] ??
        attrs['PICKUPDAY'];
    final pickupDate = _toDateFromAttribute(pickupRaw);

    return GarbageSchedule(
      routeId: route,
      address: addr,
      pickupDate: pickupDate,
      type: type,
    );
  }

  DateTime _toDateFromAttribute(dynamic value) {
    final now = DateTime.now();
    if (value == null) return now;
    if (value is int) {
      // assume epoch millis
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      // try ISO
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      // try day-of-week name
      final day = _weekdayFromName(value);
      if (day != null) {
        final daysToAdd = (day - now.weekday + 7) % 7;
        return now.add(Duration(days: daysToAdd == 0 ? 7 : daysToAdd));
      }
    }
    return now;
  }

  int? _weekdayFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mon')) return DateTime.monday;
    if (lower.contains('tue')) return DateTime.tuesday;
    if (lower.contains('wed')) return DateTime.wednesday;
    if (lower.contains('thu')) return DateTime.thursday;
    if (lower.contains('fri')) return DateTime.friday;
    if (lower.contains('sat')) return DateTime.saturday;
    if (lower.contains('sun')) return DateTime.sunday;
    return null;
  }
}
