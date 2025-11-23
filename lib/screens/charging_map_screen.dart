import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/ev_stations.dart';
import '../models/ev_station.dart';

class ChargingMapScreen extends StatefulWidget {
  const ChargingMapScreen({super.key});

  @override
  State<ChargingMapScreen> createState() => _ChargingMapScreenState();
}

class _ChargingMapScreenState extends State<ChargingMapScreen> {
  bool _showFastOnly = false;
  bool _showAvailableOnly = true;
  EVStation? _selected;

  List<EVStation> get _stations {
    return mockEvStations.where((station) {
      if (_showFastOnly && !station.hasFastCharging) return false;
      if (_showAvailableOnly && !station.hasAvailability) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const center = LatLng(43.0389, -87.9065); // Milwaukee
    final stations = _stations;
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV charging map'),
        actions: [
          IconButton(
            onPressed: () => _openDetails(context),
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'View station list',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  selected: _showAvailableOnly,
                  label: const Text('Only available'),
                  avatar: const Icon(Icons.ev_station, size: 18),
                  onSelected: (value) =>
                      setState(() => _showAvailableOnly = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _showFastOnly,
                  label: const Text('50kW+'),
                  avatar: const Icon(Icons.flash_on, size: 18),
                  onSelected: (value) => setState(() => _showFastOnly = value),
                ),
                const Spacer(),
                Text(
                  '${stations.length} spots',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
                  userAgentPackageName: 'com.mkeparkapp.app',
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
              ],
            ),
          ),
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
                style: Theme.of(context).textTheme.titleMedium,
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

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.station, required this.isSelected});

  final EVStation station;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = station.hasAvailability ? Colors.green : Colors.orange;
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
