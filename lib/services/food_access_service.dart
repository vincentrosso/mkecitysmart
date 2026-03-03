import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_location.dart';

/// Fetches Milwaukee food resource data from DYCU ArcGIS public services.
///
/// Data source: Data You Can Use (datayoucanuse.org)
/// No API key required — all public feature services.
class FoodAccessService {
  FoodAccessService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _arcgisBase =
      'https://services5.arcgis.com/3kr3fkJcIf6EOY6g/ArcGIS/rest/services';

  // Cached results to avoid re-fetching
  List<FoodLocation>? _cache;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(hours: 6);

  /// Fetch all food locations (pantries, grocery stores, farmers markets).
  /// Results are cached for 6 hours.
  Future<List<FoodLocation>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    final results = await Future.wait([
      _fetchPantries(),
      _fetchGroceryStores(),
      _fetchFarmersMarkets(),
    ]);

    _cache = [...results[0], ...results[1], ...results[2]];
    _cacheTime = DateTime.now();
    debugPrint('FoodAccess: Loaded ${_cache!.length} total locations '
        '(${results[0].length} pantries, ${results[1].length} grocery, '
        '${results[2].length} markets)');
    return _cache!;
  }

  /// Fetch only a specific type.
  Future<List<FoodLocation>> fetchByType(FoodLocationType type) async {
    final all = await fetchAll();
    return all.where((l) => l.type == type).toList();
  }

  /// Sort locations by distance from a point.
  static List<FoodLocation> sortByDistance(
    List<FoodLocation> locations,
    double lat,
    double lng,
  ) {
    final sorted = List<FoodLocation>.from(locations);
    sorted.sort((a, b) {
      final distA = _distance(lat, lng, a.latitude, a.longitude);
      final distB = _distance(lat, lng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return sorted;
  }

  /// Approximate distance in miles (Haversine shortcut for nearby points).
  static double distanceMiles(
      double lat1, double lng1, double lat2, double lng2) {
    return _distance(lat1, lng1, lat2, lng2);
  }

  // ── Private fetchers ──

  Future<List<FoodLocation>> _fetchPantries() async {
    return _fetchFeatureService(
      '$_arcgisBase/EmergencyFood_MKE/FeatureServer/0',
      FoodLocationType.pantry,
      nameField: 'USER_Company_Business_Name',
      addressField: 'USER_Address',
      phoneField: 'USER_Phone_Number',
      hoursField: 'USER_Notes',
      websiteField: 'USER_Website',
      serviceAreaField: 'USER_Service_Area',
    );
  }

  Future<List<FoodLocation>> _fetchGroceryStores() async {
    return _fetchFeatureService(
      '$_arcgisBase/MFC_GroceryStores/FeatureServer/0',
      FoodLocationType.grocery,
      nameField: 'USER_Company_Business_Name',
      addressField: 'USER_Address',
      phoneField: 'USER_Phone_Number',
      hoursField: 'USER_Notes',
    );
  }

  Future<List<FoodLocation>> _fetchFarmersMarkets() async {
    return _fetchFeatureService(
      '$_arcgisBase/MFC_FarmersMarkets/FeatureServer/0',
      FoodLocationType.farmersMarket,
      nameField: 'USER_Company_Business_Name',
      addressField: 'USER_Address',
      phoneField: 'USER_Phone_Number',
      hoursField: 'USER_Notes',
      websiteField: 'USER_Website',
    );
  }

  Future<List<FoodLocation>> _fetchFeatureService(
    String serviceUrl,
    FoodLocationType type, {
    required String nameField,
    required String addressField,
    String? phoneField,
    String? hoursField,
    String? websiteField,
    String? serviceAreaField,
  }) async {
    final uri = Uri.parse(
      '$serviceUrl/query'
      '?where=1%3D1'
      '&outFields=*'
      '&returnGeometry=true'
      '&f=json',
    );

    try {
      final resp = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        debugPrint('FoodAccess: Error ${resp.statusCode} from $serviceUrl');
        return [];
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      return features.map<FoodLocation?>((f) {
        final attrs = f['attributes'] as Map<String, dynamic>?;
        final geometry = f['geometry'] as Map<String, dynamic>?;
        if (attrs == null || geometry == null) return null;

        final lat = (geometry['y'] as num?)?.toDouble();
        final lng = (geometry['x'] as num?)?.toDouble();
        if (lat == null || lng == null || lat == 0 || lng == 0) return null;

        final name = (attrs[nameField] as String?)?.trim() ?? 'Unknown';
        final address = (attrs[addressField] as String?)?.trim() ?? '';

        return FoodLocation(
          id: '${type.name}_${attrs['ObjectID'] ?? name.hashCode}',
          name: name,
          address: address.isEmpty ? 'Milwaukee, WI' : address,
          latitude: lat,
          longitude: lng,
          type: type,
          phone: _cleanString(attrs[phoneField]),
          hours: _cleanString(attrs[hoursField]),
          website: _cleanString(attrs[websiteField]),
          serviceAreaZips: serviceAreaField != null
              ? _cleanString(attrs[serviceAreaField])
              : null,
        );
      }).whereType<FoodLocation>().toList();
    } catch (e) {
      debugPrint('FoodAccess: Exception fetching $type: $e');
      return [];
    }
  }

  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double _distance(
      double lat1, double lng1, double lat2, double lng2) {
    // Simple equirectangular approximation — good enough for city distances
    const milesPerDegLat = 69.0;
    final dLat = (lat2 - lat1) * milesPerDegLat;
    final dLng = (lng2 - lng1) * milesPerDegLat * 0.75; // cos(43°) ≈ 0.73
    return (dLat * dLat + dLng * dLng).abs().toDouble();
  }
}
