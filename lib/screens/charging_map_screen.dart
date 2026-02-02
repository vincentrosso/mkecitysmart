import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/ev_stations.dart';
import '../models/ev_station.dart';
import '../models/parking_prediction.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../services/prediction_api_service.dart';
import '../widgets/citysmart_scaffold.dart';
import '../services/location_service.dart';
import '../services/open_charge_map_service.dart';
import '../services/weather_service.dart';
import '../models/sighting_report.dart';

class ChargingMapScreen extends StatefulWidget {
  const ChargingMapScreen({super.key});

  @override
  State<ChargingMapScreen> createState() => _ChargingMapScreenState();
}

class _ChargingMapScreenState extends State<ChargingMapScreen> {
  final _ocm = OpenChargeMapService();
  final _weather = WeatherService();
  bool _showFastOnly = false;
  bool _showAvailableOnly = false;
  bool _loadingStations = true;
  String? _stationError;
  List<EVStation> _stations = mockEvStations;
  EVStation? _selected;
  List<ParkingPrediction> _predictions = const [];
  bool _loadingPredictions = false;
  final bool _includeEvents = true;
  final bool _includeWeather = true;
  final _PredictionMode _mode = _PredictionMode.heatmap;
  WeatherSummary? _weatherSummary;
  List<WeatherAlert> _weatherAlerts = const [];
  double _currentLat = 43.0389;
  double _currentLng = -87.9065;
  bool _showSightings = true;
  bool _showFilters = false;

  List<EVStation> _filterStations() {
    return _stations.where((station) {
      if (_showFastOnly && !station.hasFastCharging) return false;
      if (_showAvailableOnly && !station.hasAvailability) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStations());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPredictions());
  }

  @override
  Widget build(BuildContext context) {
    const center = LatLng(43.0389, -87.9065); // Default to Milwaukee
    final stations = _filterStations();
    final predictions = _predictions;
    final sightings = context
        .watch<UserProvider>()
        .sightings
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();
    return CitySmartScaffold(
      title: 'EV charging',
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
          tooltip: 'Filters',
        ),
        IconButton(
          onPressed: _loadStations,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        IconButton(
          onPressed: () => _openDetails(context),
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: 'Station list',
        ),
      ],
      body: Column(
        children: [
          // Compact status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF0D2924),
            child: Row(
              children: [
                Icon(
                  Icons.ev_station,
                  size: 16,
                  color: _loadingStations ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  '${stations.length} stations nearby',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (_weatherSummary != null) ...[
                  const Spacer(),
                  const Icon(Icons.cloud, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '${_weatherSummary!.temperatureF.toStringAsFixed(0)}°F',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                const Spacer(),
                if (_stationError != null)
                  const Icon(Icons.warning_amber, size: 14, color: Colors.orange)
                else if (!_loadingStations)
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
              ],
            ),
          ),
          // Collapsible filters
          if (_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: const Color(0xFF122A25),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  FilterChip(
                    selected: _showAvailableOnly,
                    label: const Text('Available', style: TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.check_circle, size: 16),
                    onSelected: (v) => setState(() => _showAvailableOnly = v),
                    visualDensity: VisualDensity.compact,
                  ),
                  FilterChip(
                    selected: _showFastOnly,
                    label: const Text('50kW+', style: TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.flash_on, size: 16),
                    onSelected: (v) => setState(() => _showFastOnly = v),
                    visualDensity: VisualDensity.compact,
                  ),
                  FilterChip(
                    selected: _showSightings,
                    label: const Text('Sightings', style: TextStyle(fontSize: 12)),
                    avatar: const Icon(Icons.visibility_outlined, size: 16),
                    onSelected: (v) => setState(() => _showSightings = v),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          // Weather alerts (compact)
          if (_weatherAlerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.red.shade900,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_weatherAlerts.length} weather alert${_weatherAlerts.length > 1 ? "s" : ""}: ${_weatherAlerts.first.event}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Map takes remaining space
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12.5,
                    onTap: (_, __) => setState(() => _selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mkecitysmart.app',
                    ),
                    if (predictions.isNotEmpty && _mode == _PredictionMode.heatmap)
                      CircleLayer(
                        circles: predictions
                            .map(
                              (p) => CircleMarker(
                                point: LatLng(p.lat, p.lng),
                                radius: (50 + (p.score * 80)).clamp(40, 120),
                                useRadiusInMeter: false,
                                color: _scoreColor(p.score).withValues(alpha: 0.35),
                                borderColor: _scoreColor(p.score),
                                borderStrokeWidth: 1.5,
                              ),
                            )
                            .toList(),
                      ),
                    MarkerLayer(
                      markers: stations
                          .map<Marker>(
                            (station) => Marker(
                              width: 42,
                              height: 42,
                              point: LatLng(station.latitude, station.longitude),
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () => setState(() => _selected = station),
                                child: _StationMarker(
                                  station: station,
                                  isSelected: _selected?.id == station.id,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (_showSightings && sightings.isNotEmpty)
                      MarkerLayer(
                        markers: sightings.map((s) {
                          final isTow = s.type == SightingType.towTruck;
                          return Marker(
                            width: 36,
                            height: 36,
                            point: LatLng(s.latitude!, s.longitude!),
                            child: Tooltip(
                              message: '${isTow ? 'Tow' : 'Enforcer'} • ${s.location}',
                              child: Icon(
                                isTow
                                    ? Icons.local_shipping_outlined
                                    : Icons.shield_moon_outlined,
                                color: isTow ? Colors.redAccent : Colors.blueGrey,
                                size: 32,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                // Loading indicator overlay
                if (_loadingStations || _loadingPredictions)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                // Legend
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendItem(color: Colors.blueAccent, label: 'Fast'),
                        _LegendItem(color: Colors.green, label: 'Available'),
                        _LegendItem(color: Colors.orange, label: 'Limited'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Station detail card at bottom
          if (_selected != null)
            _StationDetailCard(
              station: _selected!,
              onDirections: () => _openDirections(_selected!),
              onClose: () => setState(() => _selected = null),
            ),
        ],
      ),
    );
  }

  Future<void> _loadPredictions() async {
    setState(() => _loadingPredictions = true);
    final provider = context.read<UserProvider>();
    final radius = provider.profile?.preferences.geoRadiusMiles ?? 5;
    const centerLat = 43.0389;
    const centerLng = -87.9065;
    final api = PredictionApiService(ApiClient());
    List<ParkingPrediction> result;
    if (_mode == _PredictionMode.points) {
      result = await api.fetchPoints(
        lat: centerLat,
        lng: centerLng,
        radiusMiles: radius,
        includeEvents: _includeEvents,
        includeWeather: _includeWeather,
      );
    } else {
      result = await api.fetchPredictions(
        lat: centerLat,
        lng: centerLng,
        radiusMiles: radius,
        includeEvents: _includeEvents,
        includeWeather: _includeWeather,
      );
    }
    if (!mounted) return;
    setState(() {
      _predictions = result.isNotEmpty ? result : _mockPredictions();
      _loadingPredictions = false;
    });
  }

  List<ParkingPrediction> _mockPredictions() {
    final now = DateTime.now();
    final baseHour = now.hour;
    return List<ParkingPrediction>.generate(mockEvStations.length, (index) {
      final station = mockEvStations[index];
      final score = (0.6 +
              0.25 * (index % 3 == 0 ? 1 : -1) +
              0.05 * (baseHour >= 17 && baseHour <= 19 ? -1 : 1))
          .clamp(0.05, 0.95);
      return ParkingPrediction(
        id: 'pred-$index',
        blockId: 'B-${index + 1}',
        lat: station.latitude,
        lng: station.longitude,
        score: score,
        hour: baseHour,
        dayOfWeek: now.weekday,
        eventScore: 0.1,
        weatherScore: 0.05,
      );
    });
  }

  Future<void> _loadStations() async {
    setState(() {
      _loadingStations = true;
      _stationError = null;
    });

    double lat = 43.0389;
    double lng = -87.9065;

    try {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {
      // ignore and use defaults
    }
    _currentLat = lat;
    _currentLng = lng;

    try {
      final stations =
          await _ocm.fetchStations(lat: lat, lng: lng, distanceKm: 15);
      if (!mounted) return;
      setState(() {
        _stations = stations.isEmpty ? mockEvStations : stations;
        _loadingStations = false;
      });
      _loadWeather();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stationError = 'Could not load live charging stations.';
        _stations = mockEvStations;
        _loadingStations = false;
      });
    }
  }

  Future<void> _loadWeather() async {
    try {
      final summary =
          await _weather.fetchCurrent(lat: _currentLat, lng: _currentLng);
      final alerts =
          await _weather.fetchAlerts(lat: _currentLat, lng: _currentLng);
      if (!mounted) return;
      setState(() {
        _weatherSummary = summary;
        _weatherAlerts = alerts;
      });
    } catch (_) {
      // ignore and leave weather null
    }
  }

  void _openDetails(BuildContext context) {
    final stations = _stations;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nearby stations',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              ...stations.map(
                (station) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    station.hasFastCharging
                        ? Icons.flash_on
                        : Icons.ev_station,
                    color:
                        station.hasAvailability ? Colors.green : Colors.orange,
                  ),
                  title: Text(station.name),
                  subtitle: Text(
                    '${station.network} • ${station.availablePorts}/${station.totalPorts} open • ${station.maxPowerKw.toStringAsFixed(0)} kW max',
                  ),
                  onTap: () {
                    setState(() => _selected = station);
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

Color _scoreColor(double score) {
  if (score >= 0.7) return Colors.green;
  if (score >= 0.45) return Colors.orange;
  return Colors.redAccent;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

enum _PredictionMode { heatmap, points }

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.station, required this.isSelected});

  final EVStation station;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isFast = station.hasFastCharging;
    final color = isFast
        ? Colors.blueAccent
        : station.hasAvailability
            ? Colors.green
            : Colors.orange;
    return AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  offset: Offset(0, 2),
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ev_station,
              size: 16,
              color: Colors.white,
            ),
          ),
          if (isFast)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 12,
                  color: Colors.blueAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StationDetailCard extends StatelessWidget {
  const _StationDetailCard({
    required this.station,
    required this.onClose,
    required this.onDirections,
  });

  final EVStation station;
  final VoidCallback onClose;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final availability =
        '${station.availablePorts}/${station.totalPorts} open';
    final price = station.pricePerKwh.toStringAsFixed(2);
    final connectors = station.connectorTypes.join(', ');
    final chipColor =
        station.hasAvailability ? Colors.green.shade50 : Colors.orange.shade50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, -2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            station.address,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(availability),
                backgroundColor: chipColor,
              ),
              Chip(
                avatar: const Icon(Icons.flash_on, size: 18),
                label: Text('${station.maxPowerKw.toStringAsFixed(0)} kW max'),
              ),
              Chip(
                avatar: const Icon(Icons.attach_money, size: 18),
                label: Text('\$$price / kWh'),
              ),
              Chip(
                avatar: const Icon(Icons.cable_outlined, size: 18),
                label: Text(connectors),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${station.network} • ${station.status}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (station.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              station.notes!,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions),
            label: const Text('Get directions'),
          ),
        ],
      ),
    );
  }
}

extension on _ChargingMapScreenState {
  Future<void> _openDirections(EVStation station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${station.latitude},${station.longitude}',
    );
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps app.')),
      );
    }
  }
}
