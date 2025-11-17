import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../screens/welcome_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/parking_screen.dart';
import '../screens/permit_screen.dart';
import '../screens/street_sweeping_screen.dart';
import '../screens/history_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/notifications_screen.dart';
import '../citysmart/branding_preview.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/parking_provider.dart';
import '../models/parking_spot.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => LandingScreen(),
      ),
      GoRoute(
        path: '/parking',
        name: 'parking',
        builder: (context, state) => const ParkingScreen(),
        routes: [
          GoRoute(
            path: 'search',
            name: 'parking-search',
            builder: (context, state) => const ParkingSearchScreen(),
          ),
          GoRoute(
            path: 'map',
            name: 'parking-map',
            builder: (context, state) => const ParkingMapScreen(),
          ),
          GoRoute(
            path: 'spot/:spotId',
            name: 'parking-spot-details',
            builder: (context, state) {
              final spotId = state.pathParameters['spotId']!;
              return ParkingSpotDetailScreen(spotId: spotId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/permits',
        name: 'permits',
        builder: (context, state) => const PermitScreen(),
        routes: [
          GoRoute(
            path: 'active',
            name: 'active-permits',
            builder: (context, state) => const ActivePermitsScreen(),
          ),
          GoRoute(
            path: 'renew/:permitId',
            name: 'renew-permit',
            builder: (context, state) {
              final permitId = state.pathParameters['permitId']!;
              return PermitRenewalScreen(permitId: permitId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/street-sweeping',
        name: 'street-sweeping',
        builder: (context, state) => const StreetSweepingScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => HistoryScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/branding',
        name: 'branding',
        builder: (context, state) => const BrandingPreviewPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Placeholder screens that need to be implemented
class ParkingSearchScreen extends StatefulWidget {
  const ParkingSearchScreen({super.key});

  @override
  State<ParkingSearchScreen> createState() => _ParkingSearchScreenState();
}

class _ParkingSearchScreenState extends State<ParkingSearchScreen> {
  final _searchController = TextEditingController();
  SpotType? _selectedSpotType;
  double _maxRate = 10.0;
  double _searchRadius = 1.0;
  bool _availableOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Parking'),
        backgroundColor: const Color(0xFF003E29),
      ),
      body: Consumer2<LocationProvider, ParkingProvider>(
        builder: (context, locationProvider, parkingProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by address or landmark...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (value) =>
                      _performSearch(locationProvider, parkingProvider),
                ),

                const SizedBox(height: 24),

                // Filters Section
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Spot Type Filter
                _buildFilterCard(
                  'Parking Type',
                  DropdownButtonFormField<SpotType>(
                    value: _selectedSpotType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    hint: const Text('Any type'),
                    items: SpotType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getSpotTypeName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpotType = value;
                      });
                    },
                  ),
                ),

                // Max Rate Filter
                _buildFilterCard(
                  'Max Hourly Rate: \$${_maxRate.toStringAsFixed(2)}',
                  Slider(
                    value: _maxRate,
                    min: 0,
                    max: 20,
                    divisions: 40,
                    activeColor: const Color(0xFFFFC107),
                    onChanged: (value) {
                      setState(() {
                        _maxRate = value;
                      });
                    },
                  ),
                ),

                // Search Radius Filter
                _buildFilterCard(
                  'Search Radius: ${_searchRadius.toStringAsFixed(1)} miles',
                  Slider(
                    value: _searchRadius,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    activeColor: const Color(0xFFFFC107),
                    onChanged: (value) {
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                  ),
                ),

                // Available Only Filter
                _buildFilterCard(
                  'Show Only Available',
                  Switch(
                    value: _availableOnly,
                    activeColor: const Color(0xFFFFC107),
                    onChanged: (value) {
                      setState(() {
                        _availableOnly = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: parkingProvider.isLoading
                        ? null
                        : () =>
                              _performSearch(locationProvider, parkingProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: parkingProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Search Parking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Search Results
                if (parkingProvider.parkingSpots.isNotEmpty) ...[
                  const Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...parkingProvider.parkingSpots.map(
                    (spot) => _buildSearchResultCard(spot),
                  ),
                ] else if (parkingProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parkingProvider.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(ParkingSpot spot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          _getSpotTypeIcon(spot.type),
          color: spot.status == SpotStatus.available
              ? Colors.green
              : Colors.red,
        ),
        title: Text(
          spot.address,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(spot.distance * 0.000621371).toStringAsFixed(1)} miles • ${_getSpotTypeName(spot.type)}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (spot.hourlyRate != null)
              Text(
                '\$${spot.hourlyRate!.toStringAsFixed(2)}/hour',
                style: const TextStyle(color: Color(0xFFFFC107)),
              ),
            Text(
              spot.status == SpotStatus.available ? 'Available' : 'Occupied',
              style: TextStyle(
                color: spot.status == SpotStatus.available
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () => context.go('/parking/spot/${spot.id}'),
      ),
    );
  }

  void _performSearch(
    LocationProvider locationProvider,
    ParkingProvider parkingProvider,
  ) {
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location not available. Please enable location services.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    parkingProvider.searchParkingSpots(
      latitude: locationProvider.currentPosition!.latitude,
      longitude: locationProvider.currentPosition!.longitude,
      radius: _searchRadius,
      spotType: _selectedSpotType,
      maxHourlyRate: _maxRate,
    );
  }

  String _getSpotTypeName(SpotType type) {
    switch (type) {
      case SpotType.street:
        return 'Street Parking';
      case SpotType.lot:
        return 'Parking Lot';
      case SpotType.garage:
        return 'Parking Garage';
      case SpotType.metered:
        return 'Metered';
      case SpotType.permit:
        return 'Permit Only';
      case SpotType.handicap:
        return 'Handicap';
      case SpotType.loading:
        return 'Loading Zone';
      case SpotType.motorcycle:
        return 'Motorcycle';
    }
  }

  IconData _getSpotTypeIcon(SpotType type) {
    switch (type) {
      case SpotType.street:
        return Icons.local_parking;
      case SpotType.lot:
        return Icons.local_parking;
      case SpotType.garage:
        return Icons.garage;
      case SpotType.metered:
        return Icons.timer;
      case SpotType.permit:
        return Icons.credit_card;
      case SpotType.handicap:
        return Icons.accessible;
      case SpotType.loading:
        return Icons.local_shipping;
      case SpotType.motorcycle:
        return Icons.motorcycle;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen> {
  GoogleMapController? _mapController;
  static const CameraPosition _milwaukee = CameraPosition(
    target: LatLng(43.0389, -87.9065),
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Map'),
        backgroundColor: const Color(0xFF003E29),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
        ],
      ),
      body: Consumer2<LocationProvider, ParkingProvider>(
        builder: (context, locationProvider, parkingProvider, child) {
          final currentLocation = locationProvider.currentPosition;
          final parkingSpots = parkingProvider.parkingSpots;

          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _milwaukee,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (currentLocation != null) {
                _goToLocation(
                  currentLocation.latitude,
                  currentLocation.longitude,
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _buildMarkers(parkingSpots, currentLocation),
            onTap: (LatLng location) {
              // Search for parking at tapped location
              parkingProvider.searchParkingSpots(
                latitude: location.latitude,
                longitude: location.longitude,
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            onPressed: () {
              final locationProvider = context.read<LocationProvider>();
              final parkingProvider = context.read<ParkingProvider>();
              if (locationProvider.currentPosition != null) {
                parkingProvider.searchParkingSpots(
                  latitude: locationProvider.currentPosition!.latitude,
                  longitude: locationProvider.currentPosition!.longitude,
                );
              }
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location',
            backgroundColor: const Color(0xFF006A3B),
            foregroundColor: Colors.white,
            onPressed: _goToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(
    List<ParkingSpot> spots,
    Position? currentLocation,
  ) {
    Set<Marker> markers = {};

    // Add parking spot markers
    for (final spot in spots) {
      markers.add(
        Marker(
          markerId: MarkerId(spot.id),
          position: LatLng(spot.latitude, spot.longitude),
          infoWindow: InfoWindow(
            title: spot.address,
            snippet: spot.hourlyRate != null
                ? '\$${spot.hourlyRate!.toStringAsFixed(2)}/hour'
                : 'Free parking',
            onTap: () => context.go('/parking/spot/${spot.id}'),
          ),
          icon: _getMarkerIcon(spot.type, spot.status),
        ),
      );
    }

    return markers;
  }

  BitmapDescriptor _getMarkerIcon(SpotType type, SpotStatus status) {
    // In a real app, you'd use custom marker icons
    // For now, we'll use the default marker
    return BitmapDescriptor.defaultMarkerWithHue(
      status == SpotStatus.available
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueRed,
    );
  }

  void _goToCurrentLocation() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      _goToLocation(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
    }
  }

  void _goToLocation(double latitude, double longitude) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  }
}

class ParkingSpotDetailScreen extends StatefulWidget {
  final String spotId;

  const ParkingSpotDetailScreen({super.key, required this.spotId});

  @override
  State<ParkingSpotDetailScreen> createState() =>
      _ParkingSpotDetailScreenState();
}

class _ParkingSpotDetailScreenState extends State<ParkingSpotDetailScreen> {
  DateTime _selectedStartTime = DateTime.now();
  Duration _selectedDuration = const Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().selectParkingSpot(widget.spotId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Details'),
        backgroundColor: const Color(0xFF003E29),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.go('/parking/map'),
          ),
        ],
      ),
      body: Consumer2<ParkingProvider, UserProvider>(
        builder: (context, parkingProvider, userProvider, child) {
          if (parkingProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          final spot = parkingProvider.selectedSpot;
          if (spot == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Parking spot not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spot Status Card
                _buildStatusCard(spot),

                const SizedBox(height: 16),

                // Spot Information Card
                _buildInfoCard(spot),

                const SizedBox(height: 16),

                // Pricing Information
                if (spot.hourlyRate != null) _buildPricingCard(spot),

                const SizedBox(height: 16),

                // Reservation Section
                if (spot.status == SpotStatus.available)
                  _buildReservationCard(spot, userProvider),

                const SizedBox(height: 16),

                // Directions Button
                _buildDirectionsCard(spot),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ParkingSpot spot) {
    final isAvailable = spot.status == SpotStatus.available;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAvailable ? const Color(0xFF006A3B) : Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            isAvailable ? 'Available Now' : 'Currently Occupied',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (spot.availableUntil != null)
            Text(
              'Available until ${_formatTime(spot.availableUntil!)}',
              style: const TextStyle(color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ParkingSpot spot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spot Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.location_on, 'Address', spot.address),
          _buildInfoRow(
            Icons.local_parking,
            'Type',
            _getSpotTypeName(spot.type),
          ),
          _buildInfoRow(
            Icons.route,
            'Distance',
            '${(spot.distance * 0.000621371).toStringAsFixed(1)} miles away',
          ),

          if (spot.maxDuration != null)
            _buildInfoRow(
              Icons.timer,
              'Max Duration',
              '${spot.maxDuration!.toStringAsFixed(0)} hours',
            ),

          if (spot.restrictions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Restrictions:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...spot.restrictions.map(
              (restriction) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFFFFC107), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        restriction,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingCard(ParkingSpot spot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hourly Rate:', style: TextStyle(color: Colors.white)),
              Text(
                '\$${spot.hourlyRate!.toStringAsFixed(2)}/hour',
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'For ${_selectedDuration.inMinutes > 60 ? '${(_selectedDuration.inMinutes / 60).toStringAsFixed(1)} hours' : '${_selectedDuration.inMinutes} minutes'}:',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '\$${(_calculateCost(spot.hourlyRate!, _selectedDuration)).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(ParkingSpot spot, UserProvider userProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserve This Spot',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Duration Selection
          const Text(
            'Parking Duration:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: [
              _buildDurationChip(const Duration(minutes: 30)),
              _buildDurationChip(const Duration(hours: 1)),
              _buildDurationChip(const Duration(hours: 2)),
              _buildDurationChip(const Duration(hours: 4)),
              _buildDurationChip(const Duration(hours: 8)),
            ],
          ),

          const SizedBox(height: 16),

          // Reserve Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _reserveSpot(spot, userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                spot.hourlyRate != null
                    ? 'Reserve for \$${_calculateCost(spot.hourlyRate!, _selectedDuration).toStringAsFixed(2)}'
                    : 'Reserve Spot',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsCard(ParkingSpot spot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Get Directions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _openDirections(spot),
            icon: const Icon(Icons.navigation),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(Duration duration) {
    final isSelected = _selectedDuration == duration;
    final label = duration.inMinutes > 60
        ? '${(duration.inMinutes / 60).toStringAsFixed(1)}h'
        : '${duration.inMinutes}m';

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDuration = duration;
          });
        }
      },
      selectedColor: const Color(0xFFFFC107),
      backgroundColor: Colors.white24,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  double _calculateCost(double hourlyRate, Duration duration) {
    final hours = duration.inMinutes / 60.0;
    return hourlyRate * hours;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _getSpotTypeName(SpotType type) {
    switch (type) {
      case SpotType.street:
        return 'Street Parking';
      case SpotType.lot:
        return 'Parking Lot';
      case SpotType.garage:
        return 'Parking Garage';
      case SpotType.metered:
        return 'Metered Parking';
      case SpotType.permit:
        return 'Permit Only';
      case SpotType.handicap:
        return 'Handicap Accessible';
      case SpotType.loading:
        return 'Loading Zone';
      case SpotType.motorcycle:
        return 'Motorcycle Parking';
    }
  }

  Future<void> _reserveSpot(ParkingSpot spot, UserProvider userProvider) async {
    final vehicle = userProvider.getDefaultVehicle();
    if (vehicle == null) {
      _showSnackBar('Please add a vehicle to your profile first', Colors.red);
      return;
    }

    final startTime = _selectedStartTime;
    final endTime = startTime.add(_selectedDuration);

    final parkingProvider = context.read<ParkingProvider>();
    final success = await parkingProvider.reserveSpot(
      spotId: spot.id,
      vehicleId: vehicle.id,
      startTime: startTime,
      endTime: endTime,
    );

    if (success) {
      _showSnackBar('Parking spot reserved successfully!', Colors.green);
      context.go('/parking');
    } else {
      _showSnackBar('Failed to reserve parking spot', Colors.red);
    }
  }

  void _openDirections(ParkingSpot spot) {
    // In a real app, you would open the device's maps app
    _showSnackBar('Opening directions to ${spot.address}', Colors.blue);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class ActivePermitsScreen extends StatelessWidget {
  const ActivePermitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Permits')),
      body: const Center(child: Text('Active Permits Screen')),
    );
  }
}

class PermitRenewalScreen extends StatelessWidget {
  final String permitId;

  const PermitRenewalScreen({super.key, required this.permitId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renew Permit')),
      body: Center(child: Text('Renew Permit: $permitId')),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('User Profile Screen')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings Screen')),
    );
  }
}
