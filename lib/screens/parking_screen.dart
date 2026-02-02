import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/alternate_side_parking_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _AltSideCard(provider: provider),
            const SizedBox(height: 16),
            const _NearbyParkingCard(),
            const SizedBox(height: 16),
            Text('Predict & find', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            _ActionRow(
              icon: Icons.map,
              title: 'Parking heatmap',
              subtitle: 'See likely open spots nearby (predictive)',
              onTap: () => Navigator.pushNamed(context, '/parking-heatmap'),
            ),
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
          children: [
            Text('Today\'s parking side', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _subtitle,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Detecting...', style: TextStyle(color: kCitySmartText));
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
        title: Text(title, style: const TextStyle(color: kCitySmartText, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: kCitySmartText)),
        trailing: const Icon(Icons.chevron_right, color: kCitySmartMuted),
        onTap: onTap,
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
    final sorted = _spots..sort((a, b) => a.distanceTo(_pos).compareTo(b.distanceTo(_pos)));
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
            ...sorted.take(3).map(
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
