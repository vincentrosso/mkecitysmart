import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/analytics_service.dart';
import '../services/feed_filter_service.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CitySmartScaffold(
      title: 'MKE CitySmart',
      currentIndex: 2,
      body: _FeedBody(),
    );
  }
}

class _FeedBody extends StatefulWidget {
  const _FeedBody();

  @override
  State<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<_FeedBody> {
  final FeedFilterService _filterService = FeedFilterService();
  FeedFilters _filters = const FeedFilters(
    radiusMiles: 5.0, // Default: 5 miles
    timeWindow: Duration(hours: 2), // Default: last 2 hours
  );
  
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  Position? _userPosition;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _warning; // Non-fatal warnings (e.g., location unavailable)
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('FeedScreen');
    _loadFeed();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _loadFeed({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _warning = null;
        _docs = [];
        _lastDoc = null;
        _hasMore = true;
      });
    }

    try {
      final query = _filterService.buildQuery(
        filters: _filters.copyWith(lastDoc: _lastDoc),
      );
      
      final snapshot = await query.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timed out. Please check your connection.'),
      );
      final rawDocs = snapshot.docs;
      
      if (kDebugMode) {
        debugPrint('[Feed] Raw docs: ${rawDocs.length}, filters: radius=${_filters.radiusMiles}, time=${_filters.timeWindow?.inHours}h');
      }

      // Apply radius filter if needed
      final result = await _filterService.filterByRadius(
        docs: rawDocs,
        filters: _filters,
      );

      if (!mounted) return; // Check if widget is still mounted

      setState(() {
        if (refresh) {
          _docs = result.docs;
        } else {
          _docs = [..._docs, ...result.docs];
        }
        _userPosition = result.userPosition;
        _warning = result.error; // Non-fatal errors like location unavailable
        _lastDoc = rawDocs.isNotEmpty ? rawDocs.last : null;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Feed] Error: $e');
        debugPrint('[Feed] Stack: $stackTrace');
      }
      
      if (!mounted) return;
      
      // Provide user-friendly error messages
      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Access denied. Please sign in to view the feed.';
      } else if (e.toString().contains('unavailable') || e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('timed out')) {
        errorMessage = e.toString();
      } else {
        errorMessage = 'Failed to load feed. Please try again.';
      }
      
      setState(() {
        _error = errorMessage;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _loadFeed(refresh: false);
  }

  void _updateFilters(FeedFilters newFilters) {
    // Track filter changes for analytics
    AnalyticsService.instance.logEvent('feed_filters_changed', parameters: {
      'radius_miles': newFilters.radiusMiles?.toString() ?? 'all',
      'time_window_hours': newFilters.timeWindow != null 
          ? (newFilters.timeWindow!.inMinutes / 60).toString()
          : 'all',
      'sighting_type': newFilters.typeFilter.name,
    });
    
    setState(() {
      _filters = newFilters;
    });
    _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Warning banner (non-fatal issues)
        if (_warning != null && !_loading)
          _WarningBanner(message: _warning!, onDismiss: () => setState(() => _warning = null)),
        
        // Filter bar
        _FilterBar(
          filters: _filters,
          onFiltersChanged: _updateFilters,
        ),
        
        // Feed content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(error: _error!, onRetry: _loadFeed)
                  : RefreshIndicator(
                      onRefresh: () => _loadFeed(),
                      child: _docs.isEmpty
                          ? _EmptyFeedView(filters: _filters)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: _docs.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _docs.length) {
                                  return _LoadMoreButton(
                                    loading: _loadingMore,
                                    onTap: _loadMore,
                                  );
                                }
                                
                                return _SightingCard(
                                  doc: _docs[index],
                                  userPosition: _userPosition,
                                  filterService: _filterService,
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final FeedFilters filters;
  final ValueChanged<FeedFilters> onFiltersChanged;

  const _FilterBar({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Radius filter
          Expanded(
            child: _FilterDropdown<double?>(
              icon: Icons.location_on,
              label: filters.radiusLabel,
              value: filters.radiusMiles,
              items: FeedFilters.radiusOptions,
              itemLabel: (v) => v == null ? 'City-wide' : '${v.toInt()} mi',
              onChanged: (v) => onFiltersChanged(
                filters.copyWith(
                  radiusMiles: v,
                  clearRadius: v == null,
                  clearLastDoc: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Time filter
          Expanded(
            child: _FilterDropdown<Duration?>(
              icon: Icons.schedule,
              label: filters.timeLabel,
              value: filters.timeWindow,
              items: FeedFilters.timeOptions,
              itemLabel: (v) {
                if (v == null) return 'All time';
                final hours = v.inHours;
                if (hours == 1) return 'Last hour';
                if (hours < 24) return 'Last $hours hrs';
                return 'Last ${hours ~/ 24} day${hours >= 48 ? 's' : ''}';
              },
              onChanged: (v) => onFiltersChanged(
                filters.copyWith(
                  timeWindow: v,
                  clearTimeWindow: v == null,
                  clearLastDoc: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kCitySmartGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kCitySmartGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: kCitySmartGreen),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: kCitySmartGreen,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: kCitySmartGreen),
          ],
        ),
      ),
      itemBuilder: (context) => items.map((item) {
        final isSelected = item == value;
        return PopupMenuItem<T>(
          value: item,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check, size: 18, color: kCitySmartGreen)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 8),
              Text(itemLabel(item)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SightingCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Position? userPosition;
  final FeedFilterService filterService;

  const _SightingCard({
    required this.doc,
    required this.userPosition,
    required this.filterService,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final data = doc.data();
    
    final type = (data['type'] ?? 'unknown').toString();
    final title = (data['title'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final notes = (data['notes'] ?? '').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final lat = data['latitude'] as double?;
    final lng = data['longitude'] as double?;
    final reports = data['reports'] as int? ?? 0;

    // Calculate distance if we have user position and sighting coordinates
    String? distanceText;
    if (userPosition != null && lat != null && lng != null) {
      final miles = filterService.calculateDistanceMiles(
        lat1: userPosition!.latitude,
        lng1: userPosition!.longitude,
        lat2: lat,
        lng2: lng,
      );
      distanceText = filterService.formatDistance(miles);
    }

    // Determine icon and color based on type
    final isTow = type == 'tow' || type == 'towTruck';
    final icon = isTow ? Icons.local_shipping : Icons.shield;
    final iconColor = isTow ? Colors.red.shade700 : Colors.blue.shade700;
    final typeLabel = isTow ? 'Tow Truck' : 'Parking Enforcer';

    // Format time
    String timeText = '';
    if (createdAt != null) {
      timeText = filterService.formatRelativeTime(createdAt.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/alert-detail',
          arguments: doc.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type icon and time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isNotEmpty ? title : typeLabel,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (timeText.isNotEmpty) ...[
                              Icon(Icons.schedule, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                timeText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (distanceText != null && distanceText.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.near_me, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (reports > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, size: 12, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '$reports',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Location
              if (location.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Notes/message
              if (message.isNotEmpty || notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message.isNotEmpty ? message : notes,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeedView extends StatelessWidget {
  final FeedFilters filters;

  const _EmptyFeedView({required this.filters});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.search_off,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No sightings found',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Try expanding your radius or time window to see more sightings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Current filters:\n${filters.radiusLabel} • ${filters.timeLabel}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoadMoreButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more'),
              ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _WarningBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber.shade900,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: Colors.amber.shade800),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
