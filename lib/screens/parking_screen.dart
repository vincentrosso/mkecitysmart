import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/parking_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/app_drawer.dart';
import '../models/parking_spot.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  @override
  void initState() {
    super.initState();
    _searchNearbyParking();
  }

  Future<void> _searchNearbyParking() async {
    final locationProvider = context.read<LocationProvider>();
    final parkingProvider = context.read<ParkingProvider>();

    if (locationProvider.currentPosition != null) {
      await parkingProvider.searchParkingSpots(
        latitude: locationProvider.currentPosition!.latitude,
        longitude: locationProvider.currentPosition!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text(
          'Find Parking',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.go('/parking/map'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/parking/search'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer2<ParkingProvider, LocationProvider>(
        builder: (context, parkingProvider, locationProvider, child) {
          if (parkingProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            );
          }

          if (parkingProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    parkingProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _searchNearbyParking,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with current date and parking guidance
                  _buildParkingGuidance(),

                  const SizedBox(height: 24),

                  // Quick actions
                  _buildQuickActions(),

                  const SizedBox(height: 24),

                  // Nearby parking spots
                  if (parkingProvider.parkingSpots.isNotEmpty) ...[
                    const Text(
                      'Nearby Parking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...parkingProvider.parkingSpots
                        .take(5)
                        .map((spot) => _buildParkingSpotCard(spot)),
                  ] else ...[
                    _buildNoParkingSpotsMessage(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        onPressed: _searchNearbyParking,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildParkingGuidance() {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final dayName = dayNames[now.weekday - 1];
    final monthName = monthNames[now.month - 1];

    // Simple parking rule based on day
    final parkingGuidance = now.weekday % 2 == 1
        ? 'Park on the odd-numbered side'
        : 'Park on the even-numbered side';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$dayName, ${monthName} ${now.day}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parkingGuidance,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.map,
            label: 'Map View',
            onPressed: () => context.go('/parking/map'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.search,
            label: 'Search',
            onPressed: () => context.go('/parking/search'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.access_time,
            label: 'Reserve',
            onPressed: () {
              // TODO: Implement reservation flow
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingSpotCard(ParkingSpot spot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF006A3B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(_getSpotTypeIcon(spot.type), color: Colors.white),
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
              '${(spot.distance * 0.000621371).toStringAsFixed(1)} miles away',
              style: const TextStyle(color: Colors.white70),
            ),
            if (spot.hourlyRate != null)
              Text(
                '\$${spot.hourlyRate!.toStringAsFixed(2)}/hour',
                style: const TextStyle(color: Color(0xFFFFC107)),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () => context.go('/parking/spot/${spot.id}'),
      ),
    );
  }

  Widget _buildNoParkingSpotsMessage() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.location_off, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No parking spots found nearby',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try expanding your search radius or check your location',
            style: TextStyle(color: Colors.white54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
}
