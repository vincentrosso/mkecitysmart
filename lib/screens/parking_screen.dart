import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../services/location_service.dart';
import '../services/parking_prediction_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/crowdsource_widgets.dart';

/// Platform-aware navigation launcher.
/// Uses Google Maps on Android, Apple Maps on iOS.
Future<void> launchMapsNavigation(
  BuildContext context, {
  required double latitude,
  required double longitude,
}) async {
  Uri url;

  if (Platform.isAndroid) {
    // Google Maps intent for Android - opens native app directly
    url = Uri.parse('google.navigation:q=$latitude,$longitude&mode=w');
  } else {
    // Apple Maps for iOS
    url = Uri.parse(
      'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=w',
    );
  }

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    // Fallback to Google Maps web URL
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=walking',
    );
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app')),
        );
      }
    }
  }
}

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Parking')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _AltSideCard(provider: provider),
            const SizedBox(height: 12),
            // Real-time crowdsource availability banner
            const CrowdsourceAvailabilityBanner(),
            const SizedBox(height: 12),
            const _NearbyParkingCard(),
            const SizedBox(height: 16),
            Text('Predict & Find', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            const _PredictAndFindCard(),
            const SizedBox(height: 12),
            _ActionRow(
              icon: Icons.map,
              title: 'Parking heatmap',
              subtitle: 'See citation risk zones nearby',
              onTap: () => Navigator.pushNamed(context, '/parking-heatmap'),
            ),
            // Ad banner for free tier users
            const SizedBox(height: 16),
            const AdBannerWidget(showPlaceholder: false),
          ],
        ),
      ),
    );
  }
}

class _AltSideCard extends StatefulWidget {
  const _AltSideCard({required this.provider});
  final UserProvider provider;

  @override
  State<_AltSideCard> createState() => _AltSideCardState();
}

class _AltSideCardState extends State<_AltSideCard> {
  late Future<String> _subtitle;

  @override
  void initState() {
    super.initState();
    _subtitle = _resolveSubtitle();
  }

  Future<String> _resolveSubtitle() async {
    final service = AlternateSideParkingService.instance;
    // Service only uses date-based odd/even; location is not needed here.
    final instructions = service.getTodayInstructions();
    return instructions.parkingSide == ParkingSide.odd
        ? 'Odd side today'
        : 'Even side today';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Today\'s parking side', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _subtitle,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Detecting...',
                    style: TextStyle(color: kCitySmartText),
                  );
                }
                final subtitle = snapshot.data ?? 'Unavailable';
                return Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kCitySmartYellow,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-detected from your location when available; falls back to your saved address.',
              style: TextStyle(color: kCitySmartText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: ListTile(
        leading: Icon(icon, color: kCitySmartYellow),
        title: Text(
          title,
          style: const TextStyle(
            color: kCitySmartText,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: kCitySmartText)),
        trailing: const Icon(Icons.chevron_right, color: kCitySmartMuted),
        onTap: onTap,
      ),
    );
  }
}

/// Card that shows real-time parking prediction and safest spots nearby.
class _PredictAndFindCard extends StatefulWidget {
  const _PredictAndFindCard();

  @override
  State<_PredictAndFindCard> createState() => _PredictAndFindCardState();
}

class _PredictAndFindCardState extends State<_PredictAndFindCard> {
  final _locationService = LocationService();
  final _predictionService = ParkingPredictionService.instance;
  final _destinationController = TextEditingController();

  bool _loading = false;
  bool _geocoding = false;
  String? _error;
  ParkingPrediction? _prediction;
  List<SafeParkingSpot> _safestSpots = [];
  List<RecommendedSpot> _recommendedSpots = [];
  List<String> _warnings = [];

  /// Resolved destination coordinates (null = search near current location)
  double? _destLat;
  double? _destLng;
  String? _destLabel;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  /// Geocode the destination address entered by the user.
  Future<bool> _resolveDestination() async {
    final query = _destinationController.text.trim();
    if (query.isEmpty) {
      // No destination — search near current location
      _destLat = null;
      _destLng = null;
      _destLabel = null;
      return true;
    }

    setState(() => _geocoding = true);
    try {
      // Bias toward Milwaukee area by appending if no city is specified
      final searchQuery = query.contains(',') ||
              query.toLowerCase().contains('milwaukee') ||
              query.toLowerCase().contains('mke')
          ? query
          : '$query, Milwaukee, WI';

      final locations = await geocoding.locationFromAddress(searchQuery);
      if (locations.isEmpty) {
        setState(() {
          _error = 'Could not find that address. Try a more specific location.';
          _geocoding = false;
        });
        return false;
      }

      final loc = locations.first;
      _destLat = loc.latitude;
      _destLng = loc.longitude;
      _destLabel = query;

      setState(() => _geocoding = false);
      return true;
    } catch (e) {
      setState(() {
        _error = 'Could not look up address. Check your input and try again.';
        _geocoding = false;
      });
      return false;
    }
  }

  Future<void> _findSafestSpot() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Resolve destination if one was entered
      if (!await _resolveDestination()) {
        setState(() => _loading = false);
        return;
      }

      // Get current location
      final pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        setState(() {
          _error = 'Location unavailable. Enable location services.';
          _loading = false;
        });
        return;
      }

      if (!mounted) return;

      // Determine which location to predict for (destination or current)
      final predictLat = _destLat ?? pos.latitude;
      final predictLng = _destLng ?? pos.longitude;

      // Get prediction for the target location
      final prediction = await _predictionService.predict(
        when: DateTime.now(),
        latitude: predictLat,
        longitude: predictLng,
      );

      // Find best open spots — destination-aware if destination was entered
      final recommendedSpots = await _predictionService.findBestOpenSpots(
        latitude: pos.latitude,
        longitude: pos.longitude,
        radiusKm: _destLat != null ? 2.5 : 2.0,
        maxResults: 5,
        destinationLatitude: _destLat,
        destinationLongitude: _destLng,
      );

      // Fall back to safest spots if no recommended spots found
      List<SafeParkingSpot> safestSpots = [];
      if (recommendedSpots.isEmpty) {
        safestSpots = await _predictionService.findSafestSpotsNearby(
          latitude: predictLat,
          longitude: predictLng,
          radiusKm: _destLat != null ? 2.5 : 2.0,
          maxResults: 3,
        );
      }

      // Get violation warnings
      final warnings = _predictionService.getViolationWarnings();

      if (!mounted) return;

      setState(() {
        _prediction = prediction;
        _safestSpots = safestSpots;
        _recommendedSpots = recommendedSpots;
        _warnings = warnings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to get prediction: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: kCitySmartYellow),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Find Safest Parking',
                    style: TextStyle(
                      color: kCitySmartText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Uses 466K+ Milwaukee citations to find the safest spot near you.',
              style: TextStyle(color: kCitySmartMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Destination input
            TextField(
              controller: _destinationController,
              style: const TextStyle(color: kCitySmartText),
              decoration: InputDecoration(
                hintText: 'Where are you heading? (optional)',
                hintStyle: TextStyle(
                  color: kCitySmartMuted.withValues(alpha: 0.6),
                ),
                prefixIcon: const Icon(
                  Icons.place_outlined,
                  color: kCitySmartYellow,
                  size: 20,
                ),
                suffixIcon: _destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: kCitySmartMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _destinationController.clear();
                          setState(() {
                            _destLat = null;
                            _destLng = null;
                            _destLabel = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: kCitySmartCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F3A34)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F3A34)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kCitySmartYellow),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _findSafestSpot(),
            ),

            // Destination resolved badge
            if (_destLabel != null && _destLat != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Finding parking near $_destLabel',
                      style: const TextStyle(
                        color: Color(0xFF81C784),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Find button
            if (_prediction == null && !_loading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _geocoding ? null : _findSafestSpot,
                  icon: _geocoding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          _destinationController.text.trim().isNotEmpty
                              ? Icons.search
                              : Icons.my_location,
                        ),
                  label: Text(
                    _destinationController.text.trim().isNotEmpty
                        ? 'Find Parking Near Destination'
                        : 'Find Safest Spot Near Me',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCitySmartYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                ),
              ),
            ],

            // Current location prediction
            if (_prediction != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(_prediction!.colorValue).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(
                      _prediction!.colorValue,
                    ).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _prediction!.safetyScore >= 0.7
                              ? Icons.check_circle
                              : _prediction!.safetyScore >= 0.4
                              ? Icons.warning
                              : Icons.dangerous,
                          color: Color(_prediction!.colorValue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Here: ${_prediction!.safetyLabel}',
                          style: TextStyle(
                            color: Color(_prediction!.colorValue),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_prediction!.safetyScore * 100).round()}% safe',
                          style: TextStyle(
                            color: Color(_prediction!.colorValue),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_prediction!.isPeakHour) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Peak enforcement hour - extra caution!',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Violation warnings
            if (_warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...(_warnings
                  .take(2)
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        w,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )),
            ],

            // Safest spots nearby
            if (_recommendedSpots.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Best spots for you:',
                    style: TextStyle(
                      color: kCitySmartText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to navigate',
                    style: TextStyle(
                      color: kCitySmartMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Highlight the #1 recommended spot
              _TopRecommendedSpotCard(spot: _recommendedSpots.first),
              const SizedBox(height: 4),
              // Show remaining recommended spots
              if (_recommendedSpots.length > 1)
                ...(_recommendedSpots
                    .skip(1)
                    .take(3)
                    .map((spot) => _RecommendedSpotTile(spot: spot))),
            ] else if (_safestSpots.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Safest spots nearby:',
                    style: TextStyle(
                      color: kCitySmartText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to navigate',
                    style: TextStyle(
                      color: kCitySmartMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Highlight the safest spot with a prominent navigate button
              _TopSafeSpotCard(spot: _safestSpots.first),
              const SizedBox(height: 4),
              // Show remaining spots
              if (_safestSpots.length > 1)
                ...(_safestSpots
                    .skip(1)
                    .map((spot) => _SafeSpotTile(spot: spot))),
            ],

            // Refresh button if results shown
            if (_prediction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _findSafestSpot,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kCitySmartYellow,
                    side: const BorderSide(color: kCitySmartYellow),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafeSpotTile extends StatelessWidget {
  const _SafeSpotTile({required this.spot});
  final SafeParkingSpot spot;

  Future<void> _navigateToSpot(BuildContext context) async {
    await launchMapsNavigation(
      context,
      latitude: spot.latitude,
      longitude: spot.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToSpot(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E28),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(spot.label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              spot.distanceLabel,
              style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${spot.walkingMinutes} min walk',
              style: const TextStyle(color: kCitySmartText, fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.directions_walk,
              color: kCitySmartYellow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent card for the #1 safest spot with big navigate button
class _TopSafeSpotCard extends StatelessWidget {
  const _TopSafeSpotCard({required this.spot});
  final SafeParkingSpot spot;

  Future<void> _navigateToSpot(BuildContext context) async {
    await launchMapsNavigation(
      context,
      latitude: spot.latitude,
      longitude: spot.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7D32).withValues(alpha: 0.3),
            const Color(0xFF1B5E20).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAFEST SPOT',
                      style: TextStyle(
                        color: Color(0xFF81C784),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(spot.safetyScore * 100).round()}% safe • ${spot.distanceLabel}',
                      style: const TextStyle(
                        color: kCitySmartText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${spot.walkingMinutes} min',
                style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToSpot(context),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Navigate to Safe Spot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prominent card for the #1 recommended open spot with navigation
class _TopRecommendedSpotCard extends StatelessWidget {
  const _TopRecommendedSpotCard({required this.spot});
  final RecommendedSpot spot;

  Future<void> _navigateToSpot(BuildContext context) async {
    await launchMapsNavigation(
      context,
      latitude: spot.latitude,
      longitude: spot.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotColor = Color(spot.colorValue);
    final safetyPct = spot.safetyScore != null
        ? '${(spot.safetyScore! * 100).round()}% safe'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            spotColor.withValues(alpha: 0.3),
            spotColor.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: spotColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: spotColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(spot.source.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: spotColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spot.sourceBadge.toUpperCase(),
                            style: TextStyle(
                              color: spotColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (safetyPct.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            safetyPct,
                            style: const TextStyle(
                              color: kCitySmartMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.reason,
                      style: const TextStyle(
                        color: kCitySmartText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    spot.distanceLabel,
                    style: const TextStyle(
                      color: kCitySmartMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${spot.walkingMinutes} min',
                    style: const TextStyle(
                      color: kCitySmartMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToSpot(context),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Navigate to Open Spot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: spotColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile for additional recommended spots (below the #1 card)
class _RecommendedSpotTile extends StatelessWidget {
  const _RecommendedSpotTile({required this.spot});
  final RecommendedSpot spot;

  Future<void> _navigateToSpot(BuildContext context) async {
    await launchMapsNavigation(
      context,
      latitude: spot.latitude,
      longitude: spot.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotColor = Color(spot.colorValue);

    return InkWell(
      onTap: () => _navigateToSpot(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E28),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(spot.source.icon, color: spotColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.reason,
                    style: const TextStyle(color: kCitySmartText, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spot.sourceBadge,
                    style: TextStyle(
                      color: spotColor.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              spot.distanceLabel,
              style: const TextStyle(color: kCitySmartMuted, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              '${spot.walkingMinutes} min',
              style: const TextStyle(color: kCitySmartText, fontSize: 12),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.directions_walk,
              color: kCitySmartYellow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyParkingCard extends StatefulWidget {
  const _NearbyParkingCard();

  @override
  State<_NearbyParkingCard> createState() => _NearbyParkingCardState();
}

class _NearbyParkingCardState extends State<_NearbyParkingCard> {
  final _locationService = LocationService();
  bool _loading = true;
  String? _error;
  Position? _pos;

  static final _spots = <_ParkingSpot>[
    _ParkingSpot('Metered – Water St', 'Metered', 43.0389, -87.9069),
    _ParkingSpot('Garage – 2nd & Michigan', 'Garage', 43.0380, -87.9115),
    _ParkingSpot('Lot – Brady & Humboldt', 'Lot', 43.0543, -87.8906),
    _ParkingSpot('Garage – Public Market', 'Garage', 43.0338, -87.9074),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _pos = pos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Location unavailable; showing default picks.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _spots
      ..sort((a, b) => a.distanceTo(_pos).compareTo(b.distanceTo(_pos)));
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1F3A34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nearby parking',
                  style: TextStyle(
                    color: kCitySmartText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
            ],
            const SizedBox(height: 8),
            ...sorted
                .take(3)
                .map(
                  (spot) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      spot.type == 'Garage'
                          ? Icons.local_parking
                          : spot.type == 'Metered'
                          ? Icons.attach_money
                          : Icons.place,
                      color: kCitySmartYellow,
                    ),
                    title: Text(
                      spot.name,
                      style: const TextStyle(
                        color: kCitySmartText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${spot.type} • ${spot.distanceTo(_pos).toStringAsFixed(1)} mi away',
                      style: const TextStyle(color: kCitySmartText),
                    ),
                    trailing: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/parking-heatmap'),
                      child: const Text('Predictive'),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ParkingSpot {
  _ParkingSpot(this.name, this.type, this.lat, this.lng);
  final String name;
  final String type;
  final double lat;
  final double lng;

  double distanceTo(Position? pos) {
    if (pos == null) return 0.5;
    final meters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      lat,
      lng,
    );
    return meters / 1609.34;
  }
}
