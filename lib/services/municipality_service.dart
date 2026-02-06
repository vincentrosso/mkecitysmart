import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

/// Represents a detected municipality/city
class Municipality {
  const Municipality({
    required this.city,
    required this.state,
    required this.country,
    this.county,
    this.postalCode,
  });

  /// City/municipality name (e.g., "Milwaukee", "Waukesha", "Madison")
  final String city;

  /// State/province (e.g., "Wisconsin", "Illinois")
  final String state;

  /// Country code (e.g., "US", "CA")
  final String country;

  /// County if available
  final String? county;

  /// Postal/ZIP code if available
  final String? postalCode;

  /// Unique identifier for this municipality
  String get id =>
      '${city.toLowerCase().replaceAll(' ', '_')}_${state.toLowerCase().replaceAll(' ', '_')}';

  /// Display name (e.g., "Milwaukee, WI")
  String get displayName => '$city, ${_stateAbbreviation(state)}';

  /// Full display name (e.g., "Milwaukee, Wisconsin")
  String get fullDisplayName => '$city, $state';

  /// Whether this is the primary supported city (Milwaukee)
  bool get isPrimaryCity =>
      city.toLowerCase() == 'milwaukee' && state.toLowerCase() == 'wisconsin';

  /// Whether this city is in Wisconsin
  bool get isInWisconsin => state.toLowerCase() == 'wisconsin';

  /// State abbreviation helper
  static String _stateAbbreviation(String state) {
    const abbrevs = {
      'wisconsin': 'WI',
      'illinois': 'IL',
      'minnesota': 'MN',
      'iowa': 'IA',
      'michigan': 'MI',
      'indiana': 'IN',
      'ohio': 'OH',
      'california': 'CA',
      'new york': 'NY',
      'texas': 'TX',
      'florida': 'FL',
    };
    return abbrevs[state.toLowerCase()] ?? state.substring(0, 2).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'country': country,
    'county': county,
    'postalCode': postalCode,
    'id': id,
  };

  factory Municipality.fromJson(Map<String, dynamic> json) => Municipality(
    city: json['city'] as String? ?? 'Unknown',
    state: json['state'] as String? ?? 'Unknown',
    country: json['country'] as String? ?? 'US',
    county: json['county'] as String?,
    postalCode: json['postalCode'] as String?,
  );

  @override
  String toString() => 'Municipality($displayName)';
}

/// Service for detecting municipality from coordinates
class MunicipalityService {
  static final MunicipalityService _instance = MunicipalityService._internal();
  factory MunicipalityService() => _instance;
  MunicipalityService._internal();

  static MunicipalityService get instance => _instance;

  /// Cache of recently looked up municipalities
  final Map<String, Municipality> _cache = {};

  /// Default municipality (Milwaukee) for fallback
  static const Municipality defaultMunicipality = Municipality(
    city: 'Milwaukee',
    state: 'Wisconsin',
    country: 'US',
    county: 'Milwaukee County',
  );

  /// Known Wisconsin municipalities for quick matching and validation
  static const List<String> _knownWisconsinCities = [
    'Milwaukee',
    'Madison',
    'Green Bay',
    'Kenosha',
    'Racine',
    'Appleton',
    'Waukesha',
    'Oshkosh',
    'Eau Claire',
    'Janesville',
    'West Allis',
    'La Crosse',
    'Sheboygan',
    'Wauwatosa',
    'Fond du Lac',
    'New Berlin',
    'Brookfield',
    'Greenfield',
    'Beloit',
    'Menomonee Falls',
    'Franklin',
    'Oak Creek',
    'Manitowoc',
    'West Bend',
    'Sun Prairie',
    'Superior',
    'Stevens Point',
    'Neenah',
    'Fitchburg',
    'Muskego',
    'Watertown',
    'De Pere',
    'Mequon',
    'South Milwaukee',
    'Cudahy',
    'Shorewood',
    'Whitefish Bay',
    'Glendale',
    'Brown Deer',
    'Fox Point',
    'River Hills',
    'Bayside',
  ];

  /// Check if a city name is a known Wisconsin municipality
  bool isKnownWisconsinCity(String cityName) {
    return _knownWisconsinCities.any(
      (city) => city.toLowerCase() == cityName.toLowerCase(),
    );
  }

  /// Get list of supported Wisconsin cities
  List<String> get supportedCities => List.unmodifiable(_knownWisconsinCities);

  /// Detect municipality from coordinates
  Future<Municipality> detectMunicipality(
    double latitude,
    double longitude,
  ) async {
    // Check cache first
    final cacheKey =
        '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Extract city - try locality first, then subAdministrativeArea
        String city =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Unknown';

        // Clean up city name
        city = _cleanCityName(city);

        final municipality = Municipality(
          city: city,
          state: place.administrativeArea ?? 'Unknown',
          country: place.isoCountryCode ?? 'US',
          county: place.subAdministrativeArea,
          postalCode: place.postalCode,
        );

        // Cache the result
        _cache[cacheKey] = municipality;
        debugPrint('🏙️ Detected municipality: ${municipality.displayName}');

        return municipality;
      }
    } catch (e) {
      debugPrint('⚠️ Municipality detection failed: $e');
    }

    // Fallback to Milwaukee if detection fails and coordinates are nearby
    if (_isNearMilwaukee(latitude, longitude)) {
      return defaultMunicipality;
    }

    // Return unknown municipality with approximate state
    final approxState = _approximateState(latitude, longitude);
    return Municipality(city: 'Unknown', state: approxState, country: 'US');
  }

  /// Clean up city name
  String _cleanCityName(String city) {
    // Remove "City of" prefix
    if (city.toLowerCase().startsWith('city of ')) {
      city = city.substring(8);
    }
    // Remove "Town of" prefix
    if (city.toLowerCase().startsWith('town of ')) {
      city = city.substring(8);
    }
    // Remove "Village of" prefix
    if (city.toLowerCase().startsWith('village of ')) {
      city = city.substring(11);
    }
    return city.trim();
  }

  /// Check if coordinates are near Milwaukee (within ~50 miles)
  bool _isNearMilwaukee(double lat, double lng) {
    // Milwaukee: 43.0389° N, 87.9065° W
    const milwaukeeLat = 43.0389;
    const milwaukeeLng = -87.9065;

    final latDiff = (lat - milwaukeeLat).abs();
    final lngDiff = (lng - milwaukeeLng).abs();

    // Roughly 0.7 degrees ≈ 50 miles
    return latDiff < 0.7 && lngDiff < 0.7;
  }

  /// Approximate state from coordinates (rough US bounds)
  String _approximateState(double lat, double lng) {
    // Wisconsin: roughly 42.5-47°N, 86.5-92.5°W
    if (lat >= 42.5 && lat <= 47 && lng >= -92.5 && lng <= -86.5) {
      return 'Wisconsin';
    }
    // Illinois: roughly 37-42.5°N, 87.5-91.5°W
    if (lat >= 37 && lat <= 42.5 && lng >= -91.5 && lng <= -87.5) {
      return 'Illinois';
    }
    // Minnesota: roughly 43.5-49°N, 89.5-97.5°W
    if (lat >= 43.5 && lat <= 49 && lng >= -97.5 && lng <= -89.5) {
      return 'Minnesota';
    }
    // Michigan: roughly 41.5-48.5°N, 82-90.5°W
    if (lat >= 41.5 && lat <= 48.5 && lng >= -90.5 && lng <= -82) {
      return 'Michigan';
    }
    return 'Unknown';
  }

  /// Get stats about collected data per municipality
  /// This will be useful for deciding when to "launch" in a new city
  Future<Map<String, int>> getMunicipalityCitationCounts() async {
    // This would query Firestore to count citations per municipality
    // For now, return empty - will be implemented with Cloud Function
    return {};
  }

  /// Check if a city has enough data for risk predictions
  bool hasSufficientData(String municipalityId, int citationCount) {
    // Thresholds for different features
    const minForBasicRisk = 50; // Show basic risk info
    // Future thresholds for expanded features:
    // 200+ citations: Show hotspot map
    // 500+ citations: Enable full predictions

    return citationCount >= minForBasicRisk;
  }

  /// Clear cache (useful after significant location change)
  void clearCache() {
    _cache.clear();
  }
}
