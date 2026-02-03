import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/subscription_plan.dart';
import '../services/location_service.dart';
import '../services/parking_risk_service.dart';
import '../widgets/feature_gate.dart';
import '../widgets/parking_risk_badge.dart';

class ParkingHeatmapScreen extends StatefulWidget {
  const ParkingHeatmapScreen({super.key});

  @override
  State<ParkingHeatmapScreen> createState() => _ParkingHeatmapScreenState();
}

class _ParkingHeatmapScreenState extends State<ParkingHeatmapScreen> {
  final _riskService = ParkingRiskService.instance;
  final _mapController = MapController();

  double _centerLat = 43.0389; // Milwaukee default
  double _centerLng = -87.9065;

  List<RiskZone> _riskZones = [];
  LocationRisk? _locationRisk;
  bool _loading = true;
  String? _error;
  RiskZone? _selectedZone;

  @override
  void initState() {
    super.initState();
    // Check access before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessAndLoad();
    });
  }

  Future<void> _checkAccessAndLoad() async {
    final hasAccess = FeatureGate.hasAccess(context, PremiumFeature.heatmap);
    if (hasAccess) {
      _load();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    double lat = _centerLat;
    double lng = _centerLng;

    // Get current location
    try {
      final loc = await LocationService().getCurrentPosition();
      if (loc != null) {
        lat = loc.latitude;
        lng = loc.longitude;
      }
    } catch (e) {
      debugPrint('Location unavailable: $e');
    }

    if (!mounted) return;

    // Load citation risk data from backend
    try {
      final results = await Future.wait([
        _riskService.getRiskForLocation(lat, lng),
        _riskService.getRiskZones(forceRefresh: true),
      ]);
      _locationRisk = results[0] as LocationRisk?;
      _riskZones = results[1] as List<RiskZone>;
      debugPrint('Loaded ${_riskZones.length} risk zones');

      // If no zones loaded, show friendly fallback message
      if (_riskZones.isEmpty) {
        final fallbackMessages = [
          "Good news: No parking risk zones in your area.",
          "No risk zones found. Enjoy worry-free parking!",
        ];
        _error = (fallbackMessages..shuffle()).first;
        _locationRisk = null;
      }
    } catch (e) {
      debugPrint('Failed to load citation risk: $e');
      _error = 'Failed to load risk data: $e';
    }

    setState(() {
      _centerLat = lat;
      _centerLng = lng;
      _loading = false;
    });
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return const Color(0xFFD32F2F); // Brighter Red
      case RiskLevel.medium:
        return const Color(0xFFFF9800); // Brighter Orange
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Brighter Green
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user has premium access to heatmaps
    final hasAccess = FeatureGate.hasAccess(context, PremiumFeature.heatmap);
    final isTrialAccess = FeatureGate.isTrialAccess(
      context,
      PremiumFeature.heatmap,
    );
    final trialDaysRemaining = FeatureGate.getTrialDaysRemaining(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citation Risk Map'),
        actions: [
          if (hasAccess) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Refresh data',
            ),
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(LatLng(_centerLat, _centerLng), 12.0);
              },
              tooltip: 'My location',
            ),
          ],
        ],
      ),
      body: !hasAccess
          ? FeatureGate(
              feature: PremiumFeature.heatmap,
              child: const SizedBox.shrink(), // Won't be shown
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Free trial banner
                if (isTrialAccess)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5E8A45),
                          const Color(0xFF7CA726),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Free Trial: $trialDaysRemaining day${trialDaysRemaining == 1 ? '' : 's'} remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/subscriptions'),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(
                              color: Color(0xFF5E8A45),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Risk badge at top
                if (_locationRisk != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Color(_locationRisk!.colorValue).withOpacity(0.1),
                    child: ParkingRiskBadge(risk: _locationRisk!),
                  ),

                // Map
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_centerLat, _centerLng),
                          initialZoom: 11.5,
                          minZoom: 9,
                          maxZoom: 18,
                          onTap: (_, __) {
                            setState(() => _selectedZone = null);
                          },
                        ),
                        children: [
                          // OpenStreetMap tile layer
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.mkecitysmart.app',
                          ),

                          // Risk zone circles
                          CircleLayer(
                            circles: _riskZones.map((zone) {
                              final color = _getRiskColor(zone.riskLevel);
                              // Size based on citation count
                              final radius =
                                  400.0 +
                                  (zone.totalCitations / 100).clamp(0, 600);
                              return CircleMarker(
                                point: LatLng(zone.lat, zone.lng),
                                radius: radius,
                                useRadiusInMeter: true,
                                color: color.withOpacity(0.3),
                                borderColor: color,
                                borderStrokeWidth: 2,
                              );
                            }).toList(),
                          ),

                          // Risk zone markers (tappable)
                          MarkerLayer(
                            markers: _riskZones.map((zone) {
                              final color = _getRiskColor(zone.riskLevel);
                              final isSelected = _selectedZone == zone;
                              return Marker(
                                point: LatLng(zone.lat, zone.lng),
                                width: isSelected ? 60 : 40,
                                height: isSelected ? 60 : 40,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedZone = zone);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${zone.riskScore}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          // Current location marker
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_centerLat, _centerLng),
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Legend
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Risk Level',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _LegendItem(
                                color: const Color(0xFFD32F2F),
                                label: 'High (50%+)',
                                textColor: Colors.black87,
                              ),
                              const SizedBox(height: 6),
                              _LegendItem(
                                color: const Color(0xFFFF9800),
                                label: 'Medium (30-49%)',
                                textColor: Colors.black87,
                              ),
                              const SizedBox(height: 6),
                              _LegendItem(
                                color: const Color(0xFF4CAF50),
                                label: 'Low (<30%)',
                                textColor: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Zone stats - more visible
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 18,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_riskZones.length} risk zones',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                width: 1,
                                height: 16,
                                color: Colors.grey.shade300,
                              ),
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '466K+ citations',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Selected zone detail card
                      if (_selectedZone != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 50,
                          child: _ZoneDetailCard(
                            zone: _selectedZone!,
                            onClose: () => setState(() => _selectedZone = null),
                          ),
                        ),

                      // Error message
                      if (_error != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 80,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, this.textColor});
  final Color color;
  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ZoneDetailCard extends StatelessWidget {
  const _ZoneDetailCard({required this.zone, required this.onClose});
  final RiskZone zone;
  final VoidCallback onClose;

  Color get _color {
    switch (zone.riskLevel) {
      case RiskLevel.high:
        return const Color(0xFFE53935);
      case RiskLevel.medium:
        return const Color(0xFFFFA726);
      case RiskLevel.low:
        return const Color(0xFF66BB6A);
    }
  }

  String get _riskLabel {
    switch (zone.riskLevel) {
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _riskLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${zone.riskScore}% citation probability',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${_formatNumber(zone.totalCitations)} citations recorded',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Zone: ${zone.geohash}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getRiskAdvice(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRiskAdvice() {
    switch (zone.riskLevel) {
      case RiskLevel.high:
        return '⚠️ Be extra careful parking here. Check signs, meters, and time limits.';
      case RiskLevel.medium:
        return '⚡ Moderate risk area. Pay attention to parking restrictions.';
      case RiskLevel.low:
        return '✅ Lower risk area, but always check posted signs.';
    }
  }
}
