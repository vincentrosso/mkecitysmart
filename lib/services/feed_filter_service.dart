import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// Sighting types for filtering
enum SightingTypeFilter {
  all,
  towTruck,
  parkingEnforcer,
}

/// Filter options for the sightings feed
/// Designed for scalability - supports future filter additions
class FeedFilters {
  final double? radiusMiles;
  final Duration? timeWindow;
  final int limit;
  final DocumentSnapshot? lastDoc;
  final SightingTypeFilter typeFilter;
  final bool excludeReported; // Exclude sightings with 4+ reports

  const FeedFilters({
    this.radiusMiles,
    this.timeWindow,
    this.limit = 20,
    this.lastDoc,
    this.typeFilter = SightingTypeFilter.all,
    this.excludeReported = true,
  });

  FeedFilters copyWith({
    double? radiusMiles,
    Duration? timeWindow,
    int? limit,
    DocumentSnapshot? lastDoc,
    SightingTypeFilter? typeFilter,
    bool? excludeReported,
    bool clearRadius = false,
    bool clearTimeWindow = false,
    bool clearLastDoc = false,
  }) {
    return FeedFilters(
      radiusMiles: clearRadius ? null : (radiusMiles ?? this.radiusMiles),
      timeWindow: clearTimeWindow ? null : (timeWindow ?? this.timeWindow),
      limit: limit ?? this.limit,
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
      typeFilter: typeFilter ?? this.typeFilter,
      excludeReported: excludeReported ?? this.excludeReported,
    );
  }

  /// Preset filter options - easily extensible
  static const List<double?> radiusOptions = [1.0, 5.0, 10.0, 25.0, null]; // null = city-wide
  static const List<Duration?> timeOptions = [
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 6),
    Duration(hours: 24),
    Duration(hours: 72), // 3 days
    null, // null = all time
  ];

  String get radiusLabel {
    if (radiusMiles == null) return 'City-wide';
    return '${radiusMiles!.toInt()} mi';
  }

  String get timeLabel {
    if (timeWindow == null) return 'All time';
    final hours = timeWindow!.inHours;
    if (hours == 1) return 'Last hour';
    if (hours < 24) return 'Last $hours hrs';
    final days = hours ~/ 24;
    return 'Last $days day${days > 1 ? 's' : ''}';
  }

  String get typeLabel {
    switch (typeFilter) {
      case SightingTypeFilter.all:
        return 'All types';
      case SightingTypeFilter.towTruck:
        return 'Tow trucks';
      case SightingTypeFilter.parkingEnforcer:
        return 'Enforcers';
    }
  }

  /// Create a cache key for this filter combination
  String get cacheKey => '${radiusMiles}_${timeWindow?.inMinutes}_${typeFilter.name}_$excludeReported';
}

/// Result wrapper for feed queries with metadata
class FeedResult {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Position? userPosition;
  final bool hasMore;
  final DateTime fetchedAt;
  final String? error;

  FeedResult({
    required this.docs,
    this.userPosition,
    this.hasMore = true,
    DateTime? fetchedAt,
    this.error,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get isStale => DateTime.now().difference(fetchedAt).inMinutes > 2;
}

/// Service for filtering and querying the sightings feed
/// Singleton pattern for efficient resource usage at scale
class FeedFilterService {
  final LocationService _locationService = LocationService();
  
  // Cache for recent results to reduce Firestore reads
  final Map<String, FeedResult> _cache = {};
  
  // Track last user position to avoid redundant location requests
  Position? _lastPosition;
  DateTime? _lastPositionTime;
  static const Duration _positionCacheDuration = Duration(seconds: 30);
  
  static final FeedFilterService _instance = FeedFilterService._internal();
  factory FeedFilterService() => _instance;
  FeedFilterService._internal();

  /// Clear all cached data (useful after posting a new sighting)
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('[FeedFilterService] Cache cleared');
    }
  }

  /// Get cached user position or fetch new one
  Future<Position?> _getCachedPosition() async {
    if (_lastPosition != null && 
        _lastPositionTime != null &&
        DateTime.now().difference(_lastPositionTime!) < _positionCacheDuration) {
      return _lastPosition;
    }
    
    try {
      _lastPosition = await _locationService.getCurrentPosition();
      _lastPositionTime = DateTime.now();
      return _lastPosition;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FeedFilterService] Error getting position: $e');
      }
      return _lastPosition; // Return stale position if available
    }
  }

  /// Build the Firestore query with filters
  /// Optimized for index usage and scalability
  Query<Map<String, dynamic>> buildQuery({
    required FeedFilters filters,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('alerts')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    // Apply time window filter if set (uses composite index)
    if (filters.timeWindow != null) {
      final cutoff = DateTime.now().subtract(filters.timeWindow!);
      query = query.where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff));
    }

    // Apply pagination
    if (filters.lastDoc != null) {
      query = query.startAfterDocument(filters.lastDoc!);
    }

    // Calculate fetch limit:
    // - If radius filtering, fetch more to account for client-side filtering
    // - Cap at 100 to prevent excessive reads
    final int baseFetchLimit;
    if (filters.radiusMiles != null) {
      // Fetch 3x for small radius, less for larger
      final multiplier = filters.radiusMiles! <= 5 ? 4 : 3;
      baseFetchLimit = (filters.limit * multiplier).clamp(filters.limit, 100);
    } else {
      baseFetchLimit = filters.limit;
    }
    query = query.limit(baseFetchLimit);

    return query;
  }

  /// Filter documents by radius from user's current position
  /// Uses cached position when available for performance
  Future<FeedResult> filterByRadius({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required FeedFilters filters,
  }) async {
    final radiusMiles = filters.radiusMiles;
    final limit = filters.limit;

    if (radiusMiles == null) {
      // No radius filter - apply type filter only
      final filtered = _applyTypeFilter(docs, filters);
      return FeedResult(
        docs: filtered.take(limit).toList(),
        hasMore: docs.length >= limit,
      );
    }

    // Get user's current position (cached)
    final position = await _getCachedPosition();
    if (position == null) {
      // Can't filter by radius without position
      if (kDebugMode) {
        debugPrint('[FeedFilterService] No position available, returning unfiltered');
      }
      final filtered = _applyTypeFilter(docs, filters);
      return FeedResult(
        docs: filtered.take(limit).toList(),
        hasMore: docs.length >= limit,
        error: 'Location unavailable - showing all results',
      );
    }

    // Filter docs by distance and type
    final filtered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    
    for (final doc in docs) {
      // Apply type filter first (faster)
      if (!_matchesTypeFilter(doc, filters.typeFilter)) {
        continue;
      }
      
      // Apply report filter
      if (filters.excludeReported) {
        final reports = doc.data()['reports'] as int? ?? 0;
        if (reports >= 4) continue;
      }

      final data = doc.data();
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      
      if (lat == null || lng == null) {
        // Skip docs without location when radius filtering
        continue;
      }

      final distanceKm = _locationService.calculateDistanceKm(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: lat,
        endLng: lng,
      );
      final distanceMiles = distanceKm * 0.621371;

      if (distanceMiles <= radiusMiles) {
        filtered.add(doc);
        if (filtered.length >= limit) break;
      }
    }

    return FeedResult(
      docs: filtered,
      userPosition: position,
      hasMore: docs.length >= limit && filtered.length >= limit,
    );
  }

  /// Apply type filter to documents
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyTypeFilter(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    FeedFilters filters,
  ) {
    if (filters.typeFilter == SightingTypeFilter.all && !filters.excludeReported) {
      return docs;
    }

    return docs.where((doc) {
      if (!_matchesTypeFilter(doc, filters.typeFilter)) {
        return false;
      }
      if (filters.excludeReported) {
        final reports = doc.data()['reports'] as int? ?? 0;
        if (reports >= 4) return false;
      }
      return true;
    }).toList();
  }

  /// Check if a document matches the type filter
  bool _matchesTypeFilter(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    SightingTypeFilter filter,
  ) {
    if (filter == SightingTypeFilter.all) return true;
    
    final type = (doc.data()['type'] ?? '').toString().toLowerCase();
    switch (filter) {
      case SightingTypeFilter.towTruck:
        return type == 'tow' || type == 'towtruck';
      case SightingTypeFilter.parkingEnforcer:
        return type == 'parkingenforcer' || type == 'enforcer';
      case SightingTypeFilter.all:
        return true;
    }
  }

  /// Calculate distance in miles between two points
  double calculateDistanceMiles({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final distanceKm = _locationService.calculateDistanceKm(
      startLat: lat1,
      startLng: lng1,
      endLat: lat2,
      endLng: lng2,
    );
    return distanceKm * 0.621371;
  }

  /// Format a relative time string
  String formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.isNegative) return 'Just now';
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }

  /// Format distance for display
  String formatDistance(double? miles) {
    if (miles == null) return '';
    if (miles < 0.1) return '< 0.1 mi';
    if (miles < 1) return '${(miles * 10).round() / 10} mi';
    if (miles < 10) return '${miles.toStringAsFixed(1)} mi';
    return '${miles.round()} mi';
  }

  /// Get a geohash prefix for a given radius (for future geo-indexing)
  /// This enables server-side radius filtering at scale
  int geohashPrecisionForRadius(double radiusMiles) {
    // Geohash precision determines the size of the search area
    // Higher precision = smaller area = more accurate but more queries
    if (radiusMiles <= 0.5) return 7; // ~0.15km cells
    if (radiusMiles <= 1) return 6;   // ~1.2km cells
    if (radiusMiles <= 5) return 5;   // ~4.9km cells
    if (radiusMiles <= 10) return 4;  // ~20km cells
    return 4;
  }
}
