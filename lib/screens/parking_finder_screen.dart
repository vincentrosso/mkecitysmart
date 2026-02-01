import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/location_service.dart';
import '../services/parking_risk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/citysmart_scaffold.dart';

/// A dedicated parking finder map that shows the user's location,
/// nearby parking spots, and risk zones.
class ParkingFinderScreen extends StatefulWidget {
  const ParkingFinderScreen({super.key});

  @override
  State<ParkingFinderScreen> createState() => _ParkingFinderScreenState();
}

class _ParkingFinderScreenState extends State<ParkingFinderScreen> {
  final _mapController = MapController();
  final _locationService = LocationService();
  final _riskService = ParkingRiskService();

  LatLng _currentLocation = const LatLng(43.0389, -87.9065); // Milwaukee default
  bool _loadingLocation = true;
  bool _loadingSpots = true;
  String? _error;
  
  List<_ParkingSpot> _parkingSpots = [];
  _ParkingSpot? _selectedSpot;
  String? _currentRiskLevel;

  // Milwaukee parking spots - mix of garages, lots, and street parking
  static final List<_ParkingSpot> _milwaukeeParkingSpots = [
    // Downtown garages
    _ParkingSpot(
      id: '1',
      name: 'Milwaukee Center Parking',
      type: ParkingType.garage,
      lat: 43.0389,
      lng: -87.9115,
      address: '111 E Kilbourn Ave',
      rates: '\$3/hr, \$18 max',
      hours: '24/7',
      spaces: 850,
    ),
    _ParkingSpot(
      id: '2',
      name: 'Grand Avenue Ramp',
      type: ParkingType.garage,
      lat: 43.0380,
      lng: -87.9130,
      address: '275 W Wisconsin Ave',
      rates: '\$2/hr, \$15 max',
      hours: '6am-11pm',
      spaces: 1200,
    ),
    _ParkingSpot(
      id: '3',
      name: 'Third Ward Parking',
      type: ParkingType.garage,
      lat: 43.0340,
      lng: -87.9065,
      address: '333 N Broadway',
      rates: '\$2.50/hr, \$12 max',
      hours: '24/7',
      spaces: 600,
    ),
    // Surface lots
    _ParkingSpot(
      id: '4',
      name: 'Public Market Lot',
      type: ParkingType.lot,
      lat: 43.0338,
      lng: -87.9085,
      address: '400 N Water St',
      rates: '\$1.50/hr',
      hours: '6am-6pm',
      spaces: 120,
    ),
    _ParkingSpot(
      id: '5',
      name: 'Brady Street Lot',
      type: ParkingType.lot,
      lat: 43.0543,
      lng: -87.8906,
      address: '1701 N Humboldt Ave',
      rates: 'Free 2hrs, then \$1/hr',
      hours: '8am-10pm',
      spaces: 45,
    ),
    // Street parking zones
    _ParkingSpot(
      id: '6',
      name: 'Water St Metered',
      type: ParkingType.street,
      lat: 43.0395,
      lng: -87.9069,
      address: 'N Water St (Downtown)',
      rates: '\$1.50/hr metered',
      hours: '8am-6pm enforced',
      spaces: 30,
    ),
    _ParkingSpot(
      id: '7',
      name: 'East Side Street Parking',
      type: ParkingType.street,
      lat: 43.0520,
      lng: -87.8850,
      address: 'N Farwell Ave area',
      rates: '\$1/hr metered',
      hours: '9am-9pm enforced',
      spaces: 50,
    ),
    _ParkingSpot(
      id: '8',
      name: 'Lakefront Parking',
      type: ParkingType.lot,
      lat: 43.0450,
      lng: -87.8950,
      address: 'Lincoln Memorial Dr',
      rates: 'Free (2hr limit)',
      hours: '5am-10pm',
      spaces: 200,
    ),
    _ParkingSpot(
      id: '9',
      name: 'Fiserv Forum Parking',
      type: ParkingType.garage,
      lat: 43.0451,
      lng: -87.9173,
      address: '1111 Vel R. Phillips Ave',
      rates: '\$20-40 events',
      hours: 'Event hours',
      spaces: 1500,
    ),
    _ParkingSpot(
      id: '10',
      name: 'Walker\'s Point Lot',
      type: ParkingType.lot,
      lat: 43.0280,
      lng: -87.9120,
      address: '200 S 2nd St',
      rates: '\$1/hr',
      hours: '24/7',
      spaces: 80,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadParkingSpots();
  }

  Future<void> _loadLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _loadingLocation = false;
        });
        _mapController.move(_currentLocation, 14.0);
        _loadRiskForLocation();
      } else {
        setState(() {
          _loadingLocation = false;
          _error = 'Could not get location. Using Milwaukee downtown.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _error = 'Location unavailable: $e';
        });
      }
    }
  }

  Future<void> _loadRiskForLocation() async {
    try {
      final risk = await _riskService.getRiskForLocation(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );
      if (mounted && risk != null) {
        setState(() => _currentRiskLevel = risk.riskLevel.name);
      }
    } catch (_) {
      // Ignore risk loading errors
    }
  }

  void _loadParkingSpots() {
    setState(() => _loadingSpots = true);
    // Sort by distance from current location
    final sorted = List<_ParkingSpot>.from(_milwaukeeParkingSpots);
    sorted.sort((a, b) {
      final distA = _distanceBetween(_currentLocation, LatLng(a.lat, a.lng));
      final distB = _distanceBetween(_currentLocation, LatLng(b.lat, b.lng));
      return distA.compareTo(distB);
    });
    setState(() {
      _parkingSpots = sorted;
      _loadingSpots = false;
    });
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Mile, a, b);
  }

  void _selectSpot(_ParkingSpot spot) {
    setState(() => _selectedSpot = spot);
    _mapController.move(LatLng(spot.lat, spot.lng), 15.0);
  }

  Future<void> _openDirections(_ParkingSpot spot) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${spot.lat},${spot.lng}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _getSpotColor(ParkingType type) {
    switch (type) {
      case ParkingType.garage:
        return Colors.blue;
      case ParkingType.lot:
        return Colors.green;
      case ParkingType.street:
        return kCitySmartYellow;
    }
  }

  IconData _getSpotIcon(ParkingType type) {
    switch (type) {
      case ParkingType.garage:
        return Icons.local_parking;
      case ParkingType.lot:
        return Icons.square_outlined;
      case ParkingType.street:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CitySmartScaffold(
      title: 'Find parking',
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: _loadLocation,
          icon: const Icon(Icons.my_location),
          tooltip: 'Go to my location',
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/parking-heatmap'),
          icon: const Icon(Icons.layers),
          tooltip: 'Risk heatmap',
        ),
      ],
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.5,
              onTap: (_, __) => setState(() => _selectedSpot = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mkecitysmart.app',
              ),
              // User location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 16, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              // Parking spot markers
              MarkerLayer(
                markers: _parkingSpots.map((spot) {
                  final isSelected = _selectedSpot?.id == spot.id;
                  return Marker(
                    point: LatLng(spot.lat, spot.lng),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    child: GestureDetector(
                      onTap: () => _selectSpot(spot),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getSpotColor(spot.type)
                              : _getSpotColor(spot.type).withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.black26,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _getSpotColor(spot.type).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _getSpotIcon(spot.type),
                          color: Colors.white,
                          size: isSelected ? 28 : 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Risk badge at top
          if (_currentRiskLevel != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRiskColor(_currentRiskLevel!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Ticket Risk: $_currentRiskLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Legend
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kCitySmartCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: Colors.blue, icon: Icons.local_parking, label: 'Garage'),
                  const SizedBox(height: 4),
                  _LegendItem(color: Colors.green, icon: Icons.square_outlined, label: 'Lot'),
                  const SizedBox(height: 4),
                  _LegendItem(color: kCitySmartYellow, icon: Icons.attach_money, label: 'Street'),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_loadingLocation || _loadingSpots)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),

          // Error message
          if (_error != null)
            Positioned(
              top: 50,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),

          // Spot list at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _selectedSpot != null
                ? _SpotDetailCard(
                    spot: _selectedSpot!,
                    distance: _distanceBetween(
                      _currentLocation,
                      LatLng(_selectedSpot!.lat, _selectedSpot!.lng),
                    ),
                    onDirections: () => _openDirections(_selectedSpot!),
                    onClose: () => setState(() => _selectedSpot = null),
                    spotColor: _getSpotColor(_selectedSpot!.type),
                  )
                : _SpotListPreview(
                    spots: _parkingSpots.take(3).toList(),
                    currentLocation: _currentLocation,
                    onSelect: _selectSpot,
                    getColor: _getSpotColor,
                    getIcon: _getSpotIcon,
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'very high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

enum ParkingType { garage, lot, street }

class _ParkingSpot {
  final String id;
  final String name;
  final ParkingType type;
  final double lat;
  final double lng;
  final String address;
  final String rates;
  final String hours;
  final int spaces;

  const _ParkingSpot({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.address,
    required this.rates,
    required this.hours,
    required this.spaces,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: kCitySmartText, fontSize: 11)),
      ],
    );
  }
}

class _SpotDetailCard extends StatelessWidget {
  final _ParkingSpot spot;
  final double distance;
  final VoidCallback onDirections;
  final VoidCallback onClose;
  final Color spotColor;

  const _SpotDetailCard({
    required this.spot,
    required this.distance,
    required this.onDirections,
    required this.onClose,
    required this.spotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCitySmartCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: spotColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: spotColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  spot.type == ParkingType.garage
                      ? Icons.local_parking
                      : spot.type == ParkingType.lot
                          ? Icons.square_outlined
                          : Icons.attach_money,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: const TextStyle(
                        color: kCitySmartText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      spot.address,
                      style: const TextStyle(color: kCitySmartMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: kCitySmartMuted),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.directions_walk, label: '${distance.toStringAsFixed(1)} mi'),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.attach_money, label: spot.rates),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.access_time, label: spot.hours),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(icon: Icons.local_parking, label: '${spot.spaces} spaces'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Get directions'),
              style: FilledButton.styleFrom(
                backgroundColor: spotColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kCitySmartGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kCitySmartYellow),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: kCitySmartText, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotListPreview extends StatelessWidget {
  final List<_ParkingSpot> spots;
  final LatLng currentLocation;
  final void Function(_ParkingSpot) onSelect;
  final Color Function(ParkingType) getColor;
  final IconData Function(ParkingType) getIcon;

  const _SpotListPreview({
    required this.spots,
    required this.currentLocation,
    required this.onSelect,
    required this.getColor,
    required this.getIcon,
  });

  double _distance(_ParkingSpot spot) {
    const distance = Distance();
    return distance.as(LengthUnit.Mile, currentLocation, LatLng(spot.lat, spot.lng));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCitySmartCard.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kCitySmartMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text(
                  'Nearby parking',
                  style: TextStyle(
                    color: kCitySmartText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${spots.length} closest',
                  style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          ...spots.map((spot) {
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: getColor(spot.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(getIcon(spot.type), color: Colors.white, size: 18),
              ),
              title: Text(
                spot.name,
                style: const TextStyle(color: kCitySmartText, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${spot.rates} • ${_distance(spot).toStringAsFixed(1)} mi',
                style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, color: kCitySmartMuted),
              onTap: () => onSelect(spot),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
