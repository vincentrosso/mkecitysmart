import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/food_location.dart';
import '../services/food_access_service.dart';
import '../services/location_service.dart';
import '../widgets/citysmart_scaffold.dart';

class FoodAccessScreen extends StatefulWidget {
  const FoodAccessScreen({super.key});

  @override
  State<FoodAccessScreen> createState() => _FoodAccessScreenState();
}

class _FoodAccessScreenState extends State<FoodAccessScreen> {
  final _service = FoodAccessService();
  List<FoodLocation> _locations = [];
  bool _loading = true;
  String? _error;
  FoodLocationType? _filter; // null = show all
  FoodLocation? _selected;
  double _userLat = 43.0389;
  double _userLng = -87.9065;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _locations = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load food resources';
        _loading = false;
      });
    }
  }

  List<FoodLocation> get _filtered {
    if (_filter == null) return _locations;
    return _locations.where((l) => l.type == _filter).toList();
  }

  List<FoodLocation> get _sortedByDistance {
    return FoodAccessService.sortByDistance(_filtered, _userLat, _userLng);
  }

  int _countByType(FoodLocationType type) =>
      _locations.where((l) => l.type == type).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final nearby = _sortedByDistance.take(20).toList();

    return CitySmartScaffold(
      title: 'Food Access',
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: () => _loadData(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
      body: Column(
        children: [
          // ── Filter chips ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF122A25),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All (${_locations.length})',
                  selected: _filter == null,
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '${_countByType(FoodLocationType.grocery)}',
                  icon: '🛒',
                  selected: _filter == FoodLocationType.grocery,
                  color: const Color(0xFF22C55E),
                  onTap: () => setState(() => _filter =
                      _filter == FoodLocationType.grocery
                          ? null
                          : FoodLocationType.grocery),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '${_countByType(FoodLocationType.pantry)}',
                  icon: '🏠',
                  selected: _filter == FoodLocationType.pantry,
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _filter =
                      _filter == FoodLocationType.pantry
                          ? null
                          : FoodLocationType.pantry),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: '${_countByType(FoodLocationType.farmersMarket)}',
                  icon: '🥕',
                  selected: _filter == FoodLocationType.farmersMarket,
                  color: const Color(0xFFA855F7),
                  onTap: () => setState(() => _filter =
                      _filter == FoodLocationType.farmersMarket
                          ? null
                          : FoodLocationType.farmersMarket),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} shown',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // ── Map ──
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_userLat, _userLng),
                    initialZoom: 12,
                    onTap: (_, __) => setState(() => _selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mkecitysmart.app',
                    ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 50,
                        size: const Size(44, 44),
                        markers: filtered
                            .map<Marker>((loc) => Marker(
                                  width: 38,
                                  height: 38,
                                  point: LatLng(loc.latitude, loc.longitude),
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selected = loc),
                                    child: _FoodMarker(
                                      location: loc,
                                      isSelected: _selected?.id == loc.id,
                                    ),
                                  ),
                                ))
                            .toList(),
                        builder: (context, markers) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A5F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(80),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${markers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading
                if (_loading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                // Error
                if (_error != null)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                // Data source
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Source: Data You Can Use',
                      style: TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Selected detail card ──
          if (_selected != null)
            _DetailCard(
              location: _selected!,
              userLat: _userLat,
              userLng: _userLng,
              onDirections: () => _openDirections(_selected!),
              onCall: _selected!.phone != null
                  ? () => _call(_selected!.phone!)
                  : null,
              onClose: () => setState(() => _selected = null),
            ),

          // ── Bottom list ──
          if (_selected == null)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1B2A),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'Nearby',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} locations',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              itemCount: nearby.length,
                              itemBuilder: (context, i) {
                                final loc = nearby[i];
                                final dist =
                                    FoodAccessService.distanceMiles(
                                  _userLat,
                                  _userLng,
                                  loc.latitude,
                                  loc.longitude,
                                );
                                return _LocationCard(
                                  location: loc,
                                  distanceMiles: math.sqrt(dist),
                                  onTap: () =>
                                      setState(() => _selected = loc),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDirections(FoodLocation loc) {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${loc.latitude},${loc.longitude}'
      '&destination_place_id=${Uri.encodeComponent(loc.name)}',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _call(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('tel:$cleaned'));
  }
}

// ── Map marker ──
class _FoodMarker extends StatelessWidget {
  final FoodLocation location;
  final bool isSelected;

  const _FoodMarker({required this.location, required this.isSelected});

  Color get _color {
    switch (location.type) {
      case FoodLocationType.grocery:
        return const Color(0xFF22C55E);
      case FoodLocationType.pantry:
        return const Color(0xFFF59E0B);
      case FoodLocationType.farmersMarket:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 42 : 34,
      height: isSelected ? 42 : 34,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white70,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _color.withAlpha(120)
                : Colors.black.withAlpha(60),
            blurRadius: isSelected ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          location.typeEmoji,
          style: TextStyle(fontSize: isSelected ? 18 : 14),
        ),
      ),
    );
  }
}

// ── Filter chip ──
class _FilterChip extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFF2A3A4A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location card in list ──
class _LocationCard extends StatelessWidget {
  final FoodLocation location;
  final double distanceMiles;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.distanceMiles,
    required this.onTap,
  });

  Color get _typeColor {
    switch (location.type) {
      case FoodLocationType.grocery:
        return const Color(0xFF22C55E);
      case FoodLocationType.pantry:
        return const Color(0xFFF59E0B);
      case FoodLocationType.farmersMarket:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2D45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3A4A)),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(location.typeEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.typeLabel,
                    style: TextStyle(
                      color: _typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (location.hours != null)
                    Text(
                      location.hours!,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Distance
            Text(
              '${distanceMiles.toStringAsFixed(1)} mi',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail card (shown when marker tapped) ──
class _DetailCard extends StatelessWidget {
  final FoodLocation location;
  final double userLat;
  final double userLng;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onClose;

  const _DetailCard({
    required this.location,
    required this.userLat,
    required this.userLng,
    required this.onDirections,
    this.onCall,
    required this.onClose,
  });

  Color get _typeColor {
    switch (location.type) {
      case FoodLocationType.grocery:
        return const Color(0xFF22C55E);
      case FoodLocationType.pantry:
        return const Color(0xFFF59E0B);
      case FoodLocationType.farmersMarket:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dist = math.sqrt(FoodAccessService.distanceMiles(
      userLat, userLng, location.latitude, location.longitude,
    ));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text(location.typeEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${location.typeLabel} · ${dist.toStringAsFixed(1)} mi away',
                      style: TextStyle(color: _typeColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Address
          Row(
            children: [
              const Icon(Icons.place, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location.address,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          // Hours
          if (location.hours != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location.hours!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          // Phone
          if (location.phone != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  location.phone!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (onCall != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
