import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:provider/provider.dart';

import '../models/sighting_report.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../services/street_segment_service.dart';

class ReportSightingScreen extends StatefulWidget {
  const ReportSightingScreen({super.key});

  @override
  State<ReportSightingScreen> createState() => _ReportSightingScreenState();
}

class _ReportSightingScreenState extends State<ReportSightingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  SightingType _type = SightingType.parkingEnforcer;
  bool _submitting = false;
  bool _locating = false;
  Position? _lastPosition;
  final _locationService = LocationService();
  final _streetService = StreetSegmentService();
  String? _resolvedAddress;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<UserProvider>();
    final message = await provider.reportSighting(
      type: _type,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      latitude: _lastPosition?.latitude,
      longitude: _lastPosition?.longitude,
    );
    setState(() => _submitting = false);
    if (!mounted) return;
    _locationController.clear();
    _notesController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Thanks! Sighting reported.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final reports = provider.sightings;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Report enforcement / tow'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Report a sighting',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<SightingType>(
                              segments: const [
                                ButtonSegment(
                                  value: SightingType.parkingEnforcer,
                                  label: Text('Parking enforcer'),
                                  icon: Icon(Icons.shield_moon_outlined),
                                ),
                                ButtonSegment(
                                  value: SightingType.towTruck,
                                  label: Text('Tow truck'),
                                  icon: Icon(Icons.local_shipping_outlined),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged: (values) =>
                                  setState(() => _type = values.first),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location or cross-streets',
                                hintText: 'e.g., Brady & Humboldt',
                              ),
                              validator: (value) =>
                                  value != null && value.trim().isNotEmpty
                                      ? null
                                      : 'Add a location',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _locating ? null : _useMyLocation,
                                  icon: _locating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.my_location),
                                  label: const Text('Use my location'),
                                ),
                                if (_resolvedAddress != null) ...[
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      _resolvedAddress!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ] else if (_lastPosition != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatCoords(_lastPosition!),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'License plate, direction, etc.',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Submit report'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent reports (${reports.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reports.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No sightings yet. Be the first to report.'),
                      ),
                    )
                  else
                    ...reports.map(
                      (report) => Card(
                        child: ListTile(
                          leading: Icon(
                            report.type == SightingType.towTruck
                                ? Icons.local_shipping_outlined
                                : Icons.shield_moon_outlined,
                            color: report.type == SightingType.towTruck
                                ? Colors.redAccent
                                : Colors.blueGrey,
                          ),
                          title: Text(report.location),
                          subtitle: Text(
                            '${report.type == SightingType.towTruck ? 'Tow truck' : 'Parking enforcer'} • ${_formatTime(report.reportedAt)}',
                          ),
                          trailing: report.notes.isNotEmpty
                              ? const Icon(Icons.notes_outlined)
                              : null,
                          onTap: report.notes.isEmpty
                              ? null
                              : () => _showNotes(report.notes),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  String _formatCoords(Position pos) {
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final position = await _locationService.getCurrentPosition();
    setState(() => _locating = false);
    if (!mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable. Check permissions.')),
      );
      return;
    }
    final segment = await _streetService.fetchByPoint(
      lat: position.latitude,
      lng: position.longitude,
    );
    final address = segment?.display() ?? await _reverseGeocode(position);
    if (!mounted) return;
    setState(() {
      _lastPosition = position;
      _resolvedAddress = address;
      _locationController.text = address ??
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          address == null
              ? 'Location added (coords).'
              : 'Location added: $address',
        ),
      ),
    );
  }

  Future<String?> _reverseGeocode(Position pos) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  void _showNotes(String notes) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notes'),
        content: Text(notes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
