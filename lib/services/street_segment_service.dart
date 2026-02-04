import 'dart:convert';

import 'package:http/http.dart' as http;

class StreetSegment {
  StreetSegment({
    required this.streetName,
    required this.streetType,
    required this.segmentType,
  });

  final String streetName;
  final String streetType;
  final String segmentType;

  String display() {
    final type = streetType.isNotEmpty ? ' $streetType' : '';
    final seg = segmentType.isNotEmpty ? ' ($segmentType)' : '';
    return '$streetName$type$seg'.trim();
  }
}

class StreetSegmentService {
  StreetSegmentService({
    this.baseUrl =
        'https://milwaukeemaps.milwaukee.gov/arcgis/rest/services/reference/reference_map/MapServer/20',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<StreetSegment?> fetchByPoint({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse('$baseUrl/query').replace(
      queryParameters: {
        'f': 'json',
        'geometry': '$lng,$lat',
        'geometryType': 'esriGeometryPoint',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields':
            'StreetName,StreetType,SegmentType,FromLeftAddress,ToLeftAddress,FromRightAddress,ToRightAddress',
        'returnGeometry': 'false',
        'outSR': '4326',
        'resultRecordCount': '1',
      },
    );
    final resp = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? const [];
    if (features.isEmpty) return null;
    final attrs = features.first['attributes'] as Map<String, dynamic>? ?? {};
    final street = (attrs['StreetName'] as String?)?.trim() ?? '';
    if (street.isEmpty) return null;
    final type = (attrs['StreetType'] as String?)?.trim() ?? '';
    final segType = (attrs['SegmentType'] as String?)?.trim() ?? '';
    return StreetSegment(
      streetName: street,
      streetType: type,
      segmentType: segType,
    );
  }
}
