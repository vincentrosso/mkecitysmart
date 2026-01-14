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
import '../widgets/openchargemap_embed.dart';
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
  bool _showAvailableOnly = true;
  bool _loadingStations = true;
  String? _stationError;
  List<EVStation> _stations = mockEvStations;
  EVStation? _selected;
  List<ParkingPrediction> _predictions = const [];
  bool _loadingPredictions = false;
  bool _includeEvents = true;
  bool _includeWeather = true;
  _PredictionMode _mode = _PredictionMode.heatmap;
  WeatherSummary? _weatherSummary;
  List<WeatherAlert> _weatherAlerts = const [];
  double _currentLat = 43.0389;
  double _currentLng = -87.9065;
  bool _showSightings = true;

  bool get _hasFastStation =>
      _stations.any((s) => s.hasFastCharging && s.maxPowerKw >= 50);
  bool get _hasAvailabilityVariance =>
      _stations.any((s) => !s.hasAvailability);

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
      title: 'EV charging map',
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: _loadPredictions,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh predictions',
        ),
        IconButton(
          onPressed: () => _openDetails(context),
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: 'View station list',
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (_weatherSummary != null) ...[
                  const Icon(Icons.cloud, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_weatherSummary!.temperatureF.toStringAsFixed(0)}°F • ${_weatherSummary!.shortForecast} (${_weatherSummary!.probabilityOfPrecip}% rain)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_hasAvailabilityVariance)
                  FilterChip(
                    selected: _showAvailableOnly,
                    label: const Text('Only available'),
                    avatar: const Icon(Icons.ev_station, size: 18),
                    onSelected: (value) =>
                        setState(() => _showAvailableOnly = value),
                  )
                else
                  const Text(
                    'Live availability not provided',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(width: 8),
                if (_hasFastStation)
                  FilterChip(
                    selected: _showFastOnly,
                    label: const Text('50kW+'),
                    avatar: const Icon(Icons.flash_on, size: 18),
                    onSelected: (value) =>
                        setState(() => _showFastOnly = value),
                  )
                else
                  const Text(
                    'No fast chargers nearby',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                const Spacer(),
                Text('${stations.length} spots',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: _includeEvents,
                  label: const Text('Events on'),
                  onSelected: (v) {
                    setState(() => _includeEvents = v);
                    _loadPredictions();
                  },
                ),
                FilterChip(
                  selected: _includeWeather,
                  label: const Text('Weather on'),
                  onSelected: (v) {
                    setState(() => _includeWeather = v);
                    _loadPredictions();
                  },
                ),
                ChoiceChip(
                  selected: _mode == _PredictionMode.heatmap,
                  label: const Text('Heatmap'),
                  onSelected: (_) {
                    setState(() => _mode = _PredictionMode.heatmap);
                    _loadPredictions();
                  },
                ),
                ChoiceChip(
                  selected: _mode == _PredictionMode.points,
                  label: const Text('Points'),
                  onSelected: (_) {
                    setState(() => _mode = _PredictionMode.points);
                    _loadPredictions();
                  },
                ),
                FilterChip(
                  selected: _showSightings,
                  label: const Text('Sightings'),
                  avatar: const Icon(Icons.visibility_outlined, size: 18),
                  onSelected: (v) => setState(() => _showSightings = v),
                ),
              ],
            ),
          ),
          if (_weatherAlerts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_weatherAlerts.length} weather alert${_weatherAlerts.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._weatherAlerts.take(2).map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${a.event} • ${a.severity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (_weatherAlerts.length > 2)
                        Text(
                          '+${_weatherAlerts.length - 2} more',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // OpenChargeMap embed (web) or CTA (mobile/desktop).
          OpenChargeMapEmbed(onOpenExternal: _openExternalMap),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: center,
                initialZoom: 12.2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                if (predictions.isNotEmpty && _mode == _PredictionMode.points)
                  MarkerLayer(
                    markers: predictions
                        .map(
                          (p) => Marker(
                            point: LatLng(p.lat, p.lng),
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _scoreColor(p.score),
                                shape: BoxShape.circle,
                              ),
                            ),
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
          ),
          if (_selected != null)
            _StationDetailCard(
              station: _selected!,
              onDirections: () => _openDirections(_selected!),
              onClose: () => setState(() => _selected = null),
            ),
          if (_loadingStations)
            const LinearProgressIndicator(minHeight: 3),
          if (_stationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _stationError!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          if (_loadingPredictions)
            const LinearProgressIndicator(minHeight: 3),
          if (predictions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Availability preview'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _HeatLegend(color: _scoreColor(0.8), label: 'High'),
                      _HeatLegend(color: _scoreColor(0.5), label: 'Med'),
                      _HeatLegend(color: _scoreColor(0.2), label: 'Low'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...predictions.take(5).map(
                        (p) => ListTile(
                          dense: true,
                          leading: Icon(Icons.local_parking,
                              color: _scoreColor(p.score)),
                          title: Text('Block ${p.blockId}'),
                          subtitle: Text(
                            'Score ${(p.score * 100).round()}% • Hour ${p.hour} • D${p.dayOfWeek}',
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

class _HeatLegend extends StatelessWidget {
  const _HeatLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(label, style: TextStyle(color: color)),
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

  Future<void> _openExternalMap() async {
    final uri = Uri.parse('https://map.openchargemap.io/?mode=embedded');
    await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }
}
