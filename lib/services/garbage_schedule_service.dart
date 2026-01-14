import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/garbage_schedule.dart';

/// Service for fetching garbage/recycling schedules.
/// Supports both JSON (ArcGIS-style) and the Milwaukee DPW HTML endpoint.
class GarbageScheduleService {
  GarbageScheduleService({
    required this.baseUrl,
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String? authToken;
  final http.Client _client;

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await _client.get(uri, headers: _headers());
    } on http.ClientException catch (e) {
      throw Exception(
        'Network blocked fetching schedule (CORS/offline): ${e.message}',
      );
    }
  }

  /// Fetch schedule by coordinates (ArcGIS JSON).
  Future<List<GarbageSchedule>> fetchByLocation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      // ArcGIS expects x,y = lon,lat
      'geometry': '${longitude.toStringAsFixed(6)},${latitude.toStringAsFixed(6)}',
      'geometryType': 'esriGeometryPoint',
      'inSR': '4326',
      'spatialRel': 'esriSpatialRelIntersects',
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await _safeGet(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    return _parseJsonFeatures(resp.body);
  }

  /// Fetch schedule by address. If the endpoint is the DPW HTML servlet, fall back to HTML parsing.
  Future<List<GarbageSchedule>> fetchByAddress(String address) async {
    if (baseUrl.contains('DPWServletsPublic/garbage_day')) {
      return _fetchByAddressHtml(address);
    }

    final where = "UPPER(ADDRESS) LIKE '%${address.toUpperCase()}%'";
    final uri = Uri.parse('$baseUrl/query').replace(queryParameters: {
      'f': 'json',
      'where': where,
      'outFields': '*',
      'returnGeometry': 'false',
    });
    final resp = await _safeGet(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }
    return _parseJsonFeatures(resp.body);
  }

  List<GarbageSchedule> _parseJsonFeatures(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return features.map(_fromFeature).toList();
  }

  Future<List<GarbageSchedule>> _fetchByAddressHtml(String address) async {
    final parts = _AddressParts.fromFreeform(address);
    final form = {
      'embed': 'N',
      'laddr': parts.houseNumber,
      'sdir': parts.direction ?? '',
      'sname': parts.streetName,
      'stype': parts.streetType ?? '',
      'faddr': parts.formattedStreet,
    };

    final resp = await _client.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: form,
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch schedule: ${resp.statusCode}');
    }

    final html = resp.body;
    final garbage = _extractSection(html, 'Next Scheduled Garbage Pickup:');
    final recycling = _extractSection(html, 'Next Scheduled Recycling Pickup:');

    final schedules = <GarbageSchedule>[];
    if (garbage != null) {
      schedules.add(
        GarbageSchedule(
          routeId: garbage.route,
          address: parts.formattedAddress,
          pickupDate: garbage.date,
          type: PickupType.garbage,
        ),
      );
    }
    if (recycling != null) {
      schedules.add(
        GarbageSchedule(
          routeId: recycling.route,
          address: parts.formattedAddress,
          pickupDate: recycling.date,
          type: PickupType.recycling,
        ),
      );
    }

    if (schedules.isEmpty) {
      throw Exception('Schedule not found for the provided address.');
    }
    return schedules;
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
      address: addr.isNotEmpty ? addr : 'Unknown address',
      pickupDate: pickupDate,
      type: type,
    );
  }

  DateTime _toDateFromAttribute(dynamic value) {
    final now = DateTime.now();
    if (value == null) return now;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
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

  _PickupInfo? _extractSection(String html, String heading) {
    final start = html.toLowerCase().indexOf(heading.toLowerCase());
    if (start == -1) return null;

    final slice = html.substring(start);
    final matches = RegExp(
      r'<strong>([^<]+)</strong>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(slice).take(2).toList();
    if (matches.length < 2) return null;

    final route = matches[0].group(1)?.trim();
    final dateStr = matches[1].group(1)?.trim();
    if (route == null || route.isEmpty || dateStr == null || dateStr.isEmpty) {
      return null;
    }

    final parsedDate = _parseDate(dateStr);
    if (parsedDate == null) return null;

    return _PickupInfo(route: route, date: parsedDate);
  }

  DateTime? _parseDate(String raw) {
    final normalized = _titleCase(raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim());
    try {
      return DateFormat('EEEE MMMM d, yyyy', 'en_US').parse(normalized);
    } catch (_) {
      return null;
    }
  }

  String _titleCase(String input) {
    return input
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _AddressParts {
  _AddressParts({
    required this.houseNumber,
    required this.streetName,
    required this.formattedStreet,
    required this.formattedAddress,
    this.direction,
    this.streetType,
  });

  final String houseNumber;
  final String streetName;
  final String formattedStreet;
  final String formattedAddress;
  final String? direction;
  final String? streetType;

  static _AddressParts fromFreeform(String address) {
    final cleaned = address.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleaned.split(' ');
    if (parts.length < 2) {
      throw Exception('Enter a full street address (number, direction, name, type).');
    }

    final house = parts.removeAt(0);
    if (!RegExp(r'^\d+').hasMatch(house)) {
      throw Exception('Include a house number.');
    }

    const dirs = {'N', 'S', 'E', 'W'};
    String? direction;
    if (parts.isNotEmpty && dirs.contains(parts.first)) {
      direction = parts.removeAt(0);
    }

    const suffixes = {
      'ST',
      'AVE',
      'AV',
      'BLVD',
      'RD',
      'DR',
      'CT',
      'LN',
      'PL',
      'PKWY',
      'WAY',
      'TER',
      'CIR',
      'HWY',
    };
    String? type;
    if (parts.isNotEmpty && suffixes.contains(parts.last)) {
      type = parts.removeLast();
    }

    if (parts.isEmpty) {
      throw Exception('Street name missing.');
    }
    final name = parts.join(' ');
    final formattedStreet = [
      if (direction != null) direction,
      name,
      if (type != null) type,
    ].join(' ');

    return _AddressParts(
      houseNumber: house,
      direction: direction,
      streetName: name,
      streetType: type,
      formattedStreet: formattedStreet,
      formattedAddress: '$house $formattedStreet',
    );
  }
}

class _PickupInfo {
  _PickupInfo({required this.route, required this.date});
  final String route;
  final DateTime date;
}
