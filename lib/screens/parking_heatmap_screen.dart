import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../services/parking_prediction_service.dart';

class ParkingHeatmapScreen extends StatefulWidget {
  const ParkingHeatmapScreen({super.key});

  @override
  State<ParkingHeatmapScreen> createState() => _ParkingHeatmapScreenState();
}

class _ParkingHeatmapScreenState extends State<ParkingHeatmapScreen> {
  final _service = ParkingPredictionService();
  double _centerLat = 43.0389;
  double _centerLng = -87.9065;
  final _eventLoad = 0.2;
  List<PredictedPoint> _points = const [];
  bool _loading = true;
  String? _error;

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
    double lat = _centerLat;
    double lng = _centerLng;
    final userProvider = context.read<UserProvider>();
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
      }
    } catch (e) {
      _error = 'Location unavailable; showing defaults.';
    }
    if (!mounted) return;
    final cityBias = _cityBias(userProvider.cityId);
    _points = _service.predictNearby(
      when: DateTime.now(),
      latitude: lat,
      longitude: lng,
      eventLoad: _eventLoad,
      samples: 60,
      cityBias: cityBias,
    );
    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _loading = false;
    });
  }

  Color _scoreColor(double score) {
    // 0 -> red, 0.5 -> yellow, 1 -> green
    if (score < 0.33) {
      return Colors.redAccent.withValues(alpha: 0.6 + score * 0.2);
    } else if (score < 0.66) {
      return Colors.orangeAccent.withValues(alpha: 0.6 + (score - 0.33) * 0.2);
    }
    return Colors.greenAccent.withValues(alpha: 0.6 + (score - 0.66) * 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Heatmap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Predicted availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Map coords to a simple grid for demo purposes.
                  final minLat = _centerLat - 0.002;
                  final maxLat = _centerLat + 0.002;
                  final minLng = _centerLng - 0.002;
                  final maxLng = _centerLng + 0.002;

                  double toX(double lng) =>
                      ((lng - minLng) / (maxLng - minLng)) *
                      constraints.maxWidth;
                  double toY(double lat) =>
                      constraints.maxHeight -
                      ((lat - minLat) / (maxLat - minLat)) *
                          constraints.maxHeight;

                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      ..._points.map((p) {
                        final x = toX(p.longitude);
                        final y = toY(p.latitude);
                        return Positioned(
                          left: x - 10,
                          top: y - 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _scoreColor(p.score),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            _LegendDot(color: Colors.greenAccent, label: 'High chance'),
                            SizedBox(height: 6),
                            _LegendDot(color: Colors.orangeAccent, label: 'Medium'),
                            SizedBox(height: 6),
                            _LegendDot(color: Colors.redAccent, label: 'Lower'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

double _cityBias(String cityId) {
  switch (cityId.toLowerCase()) {
    case 'milwaukee':
    case 'milwaukee-county':
      return 0.05;
    case 'chicago':
      return 0.08;
    case 'new-york':
    case 'nyc':
      return 0.1;
    default:
      return 0.04;
  }
}
