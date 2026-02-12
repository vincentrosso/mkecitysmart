import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/parking_report.dart';
import '../models/subscription_plan.dart';
import '../services/location_service.dart';
import '../services/parking_crowdsource_service.dart';
import '../services/parking_prediction_service.dart';
import '../services/parking_risk_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/crowdsource_widgets.dart';
import '../widgets/feature_gate.dart';
import '../widgets/parking_risk_badge.dart';

class ParkingHeatmapScreen extends StatefulWidget {
  const ParkingHeatmapScreen({super.key});

  @override
  State<ParkingHeatmapScreen> createState() => _ParkingHeatmapScreenState();
}

class _ParkingHeatmapScreenState extends State<ParkingHeatmapScreen> {
  final _riskService = ParkingRiskService.instance;
  final _predictionService = ParkingPredictionService.instance;
  final _crowdsourceService = ParkingCrowdsourceService.instance;
  final _mapController = MapController();

  double _centerLat = 43.0389; // Milwaukee default
  double _centerLng = -87.9065;

  List<RiskZone> _riskZones = [];
  LocationRisk? _locationRisk;
  bool _loading = true;
  String? _error;
  RiskZone? _selectedZone;
  bool _riskBannerDismissed = false;

  // Prediction data
  List<SafeParkingSpot> _safestSpots = [];
  bool _showSafestSpots = false;

  // Crowdsource data — real-time
  StreamSubscription<List<ParkingReport>>? _crowdsourceSub;
  List<ParkingReport> _nearbyReports = [];
  final bool _showCrowdsource = true;
  ParkingReport? _selectedReport;

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

    // Start the crowdsource real-time stream once we know the location
    _startCrowdsourceStream(lat, lng);
  }

  void _startCrowdsourceStream(double lat, double lng) {
    _crowdsourceSub?.cancel();
    _crowdsourceSub = _crowdsourceService
        .nearbyReportsStream(latitude: lat, longitude: lng)
        .listen(
          (reports) {
            if (!mounted) return;
            setState(() => _nearbyReports = reports);
          },
          onError: (e) {
            debugPrint('[HeatmapCrowdsource] Stream error: $e');
          },
        );
  }

  @override
  void dispose() {
    _crowdsourceSub?.cancel();
    super.dispose();
  }

  Future<void> _findSafestSpots() async {
    final spots = await _predictionService.findSafestSpotsNearby(
      latitude: _centerLat,
      longitude: _centerLng,
      radiusKm: 3.0,
      maxResults: 5,
    );

    setState(() {
      _safestSpots = spots;
      _showSafestSpots = true;
    });

    // If we have a safest spot, zoom to it
    if (spots.isNotEmpty) {
      final safest = spots.first;
      _mapController.move(LatLng(safest.latitude, safest.longitude), 14.0);
    }
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
      floatingActionButton: hasAccess && !_loading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Report parking info FAB
                FloatingActionButton.small(
                  heroTag: 'reportFab',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final report = await showReportSheet(context);
                    if (report != null && mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ ${report.reportType.displayName} reported!',
                          ),
                          backgroundColor: const Color(0xFF4CAF50),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor: kCitySmartYellow,
                  child: const Icon(Icons.campaign, color: Colors.black),
                ),
                const SizedBox(height: 10),
                // Find Safest FAB
                FloatingActionButton.extended(
                  heroTag: 'findSafestFab',
                  onPressed: _findSafestSpots,
                  backgroundColor: const Color(0xFF4CAF50),
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Find Safest'),
                ),
              ],
            )
          : null,
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

                // Risk badge at top with dismiss button
                if (_locationRisk != null && !_riskBannerDismissed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Color(
                      _locationRisk!.colorValue,
                    ).withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Expanded(child: ParkingRiskBadge(risk: _locationRisk!)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              setState(() => _riskBannerDismissed = true),
                          tooltip: 'Dismiss',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
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
                          onTap: (tapPosition, point) {
                            setState(() {
                              _selectedZone = null;
                              _selectedReport = null;
                            });
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
                                color: color.withValues(alpha: 0.3),
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
                                                color: color.withValues(
                                                  alpha: 0.5,
                                                ),
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

                          // Safest spots markers (green checkmarks)
                          if (_showSafestSpots && _safestSpots.isNotEmpty)
                            MarkerLayer(
                              markers: _safestSpots.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final spot = entry.value;
                                final isFirst = index == 0;
                                return Marker(
                                  point: LatLng(spot.latitude, spot.longitude),
                                  width: isFirst ? 50 : 40,
                                  height: isFirst ? 50 : 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isFirst
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFF81C784),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: isFirst ? 4 : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: isFirst ? 12 : 6,
                                          spreadRadius: isFirst ? 3 : 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: isFirst
                                          ? const Icon(
                                              Icons.verified,
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          // Crowdsource report markers (real-time)
                          if (_showCrowdsource && _nearbyReports.isNotEmpty)
                            MarkerLayer(
                              markers: _nearbyReports.map((report) {
                                final isSelected = _selectedReport == report;
                                final color = report.reportType.isPositiveSignal
                                    ? const Color(0xFF4CAF50)
                                    : report.reportType ==
                                              ReportType.enforcementSpotted ||
                                          report.reportType ==
                                              ReportType.towTruckSpotted
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFFF9800);
                                return Marker(
                                  point: LatLng(
                                    report.latitude,
                                    report.longitude,
                                  ),
                                  width: isSelected ? 44 : 34,
                                  height: isSelected ? 44 : 34,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedZone = null;
                                        _selectedReport = report;
                                      });
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
                                                  color: color.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          report.reportType.icon,
                                          color: Colors.white,
                                          size: isSelected ? 22 : 16,
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
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
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
                                color: Colors.black.withValues(alpha: 0.15),
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
                              if (_nearbyReports.isNotEmpty) ...[
                                const Divider(height: 16),
                                const Text(
                                  'Live Reports',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _LegendItem(
                                  color: const Color(0xFF4CAF50),
                                  label: 'Spot available',
                                  textColor: Colors.black87,
                                ),
                                const SizedBox(height: 4),
                                _LegendItem(
                                  color: const Color(0xFFFF9800),
                                  label: 'Spot taken',
                                  textColor: Colors.black87,
                                ),
                                const SizedBox(height: 4),
                                _LegendItem(
                                  color: const Color(0xFFE53935),
                                  label: 'Enforcement',
                                  textColor: Colors.black87,
                                ),
                              ],
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
                                color: Colors.black.withValues(alpha: 0.15),
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

                      // Selected crowdsource report card
                      if (_selectedReport != null && _selectedZone == null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 50,
                          child: _ReportDetailCard(
                            report: _selectedReport!,
                            onClose: () =>
                                setState(() => _selectedReport = null),
                            onUpvote: () {
                              _crowdsourceService.upvote(_selectedReport!.id);
                            },
                            onDownvote: () {
                              _crowdsourceService.downvote(_selectedReport!.id);
                            },
                          ),
                        ),

                      // Safest spots results card
                      if (_showSafestSpots &&
                          _safestSpots.isNotEmpty &&
                          _selectedZone == null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 50,
                          child: _SafestSpotsCard(
                            spots: _safestSpots,
                            onClose: () =>
                                setState(() => _showSafestSpots = false),
                            onSpotTap: (spot) {
                              _mapController.move(
                                LatLng(spot.latitude, spot.longitude),
                                15.0,
                              );
                            },
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

                      // Data source attribution (Google Play policy)
                      Positioned(
                        right: 12,
                        bottom: 50,
                        child: GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://milwaukeemaps.milwaukee.gov/arcgis/rest/services/',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Source: Milwaukee Maps (ArcGIS)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Ad banner for free tier users
                const SafeArea(
                  top: false,
                  child: AdBannerWidget(showPlaceholder: false),
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
                color: color.withValues(alpha: 0.4),
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

/// Card showing safest parking spots found by prediction service
class _SafestSpotsCard extends StatefulWidget {
  const _SafestSpotsCard({
    required this.spots,
    required this.onClose,
    required this.onSpotTap,
  });

  final List<SafeParkingSpot> spots;
  final VoidCallback onClose;
  final void Function(SafeParkingSpot) onSpotTap;

  @override
  State<_SafestSpotsCard> createState() => _SafestSpotsCardState();
}

class _SafestSpotsCardState extends State<_SafestSpotsCard> {
  bool _minimized = false;

  Future<void> _navigateToSpot(SafeParkingSpot spot) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    // Prefer Google Maps on Android, Apple Maps on iOS
    final Uri primaryUrl;
    final Uri fallbackUrl;

    if (isIOS) {
      primaryUrl = Uri.parse(
        'https://maps.apple.com/?daddr=${spot.latitude},${spot.longitude}&dirflg=w',
      );
      fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}&travelmode=walking',
      );
    } else {
      primaryUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}&travelmode=walking',
      );
      fallbackUrl = Uri.parse(
        'https://maps.apple.com/?daddr=${spot.latitude},${spot.longitude}&dirflg=w',
      );
    }

    if (await canLaunchUrl(primaryUrl)) {
      await launchUrl(primaryUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallbackUrl)) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safest = widget.spots.first;

    // Minimized view - just a small bar
    if (_minimized) {
      return Card(
        elevation: 4,
        child: InkWell(
          onTap: () => setState(() => _minimized = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Safest: ${(safest.safetyScore * 100).round()}% safe',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.expand_less, color: Colors.grey),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full view
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
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'SAFEST SPOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Minimize button
                IconButton(
                  icon: const Icon(Icons.expand_more, size: 20),
                  onPressed: () => setState(() => _minimized = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Minimize',
                ),
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Top recommendation
            InkWell(
              onTap: () => widget.onSpotTap(safest),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(safest.safetyScore * 100).round()}% Safe',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${safest.distanceLabel} • ${safest.walkingMinutes} min walk',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.directions_walk,
                        color: Color(0xFF4CAF50),
                      ),
                      onPressed: () => _navigateToSpot(safest),
                      tooltip: 'Navigate',
                    ),
                  ],
                ),
              ),
            ),

            // Navigate button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSpot(safest),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Navigate to Safe Spot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            // Other spots
            if (widget.spots.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                'Other safe options:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.spots
                  .skip(1)
                  .take(3)
                  .map(
                    (spot) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => widget.onSpotTap(spot),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF81C784),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.spots.indexOf(spot) + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(spot.safetyScore * 100).round()}% safe',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const Spacer(),
                            Text(
                              spot.distanceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _navigateToSpot(spot),
                              child: const Icon(
                                Icons.directions_walk,
                                size: 18,
                                color: Color(0xFF81C784),
                              ),
                            ),
                          ],
                        ),
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

/// Card showing details of a tapped crowdsource report on the map.
class _ReportDetailCard extends StatelessWidget {
  const _ReportDetailCard({
    required this.report,
    required this.onClose,
    required this.onUpvote,
    required this.onDownvote,
  });

  final ParkingReport report;
  final VoidCallback onClose;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  Color get _color {
    if (report.reportType.isPositiveSignal) return const Color(0xFF4CAF50);
    if (report.reportType == ReportType.enforcementSpotted ||
        report.reportType == ReportType.towTruckSpotted) {
      return const Color(0xFFE53935);
    }
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    final age = report.ageMinutes;
    final ageLabel = age < 1
        ? 'Just now'
        : age < 60
        ? '${age}m ago'
        : '${age ~/ 60}h ago';

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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        report.reportType.icon,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.reportType.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ageLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (report.note != null && report.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(report.note!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // Upvote
                _VoteChip(
                  icon: Icons.thumb_up_outlined,
                  count: report.upvotes,
                  onTap: onUpvote,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                // Downvote
                _VoteChip(
                  icon: Icons.thumb_down_outlined,
                  count: report.downvotes,
                  onTap: onDownvote,
                  color: Colors.redAccent,
                ),
                const Spacer(),
                // TTL indicator
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Expires in ${report.reportType.ttlMinutes - age}m',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({
    required this.icon,
    required this.count,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final int count;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
