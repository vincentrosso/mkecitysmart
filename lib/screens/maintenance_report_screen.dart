import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_report.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';
import '../widgets/publicstuff_embed.dart';

class MaintenanceReportScreen extends StatefulWidget {
  const MaintenanceReportScreen({super.key});

  @override
  State<MaintenanceReportScreen> createState() => _MaintenanceReportScreenState();
}

class _MaintenanceReportScreenState extends State<MaintenanceReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  final _locationService = LocationService();
  MaintenanceCategory _category = MaintenanceCategory.pothole;
  Position? _lastPosition;
  bool _locating = false;
  String? _photoPath;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _photoPath = picked.path);
    }
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
    setState(() => _lastPosition = position);
    _locationController.text =
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location added.')),
    );
  }

  Future<void> _submit(UserProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    await provider.submitMaintenanceReport(
      category: _category,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      latitude: _lastPosition?.latitude,
      longitude: _lastPosition?.longitude,
      photoPath: _photoPath,
    );
    if (!mounted) return;
    _descriptionController.clear();
    _photoPath = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted and routed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final reports = provider.maintenanceReports;
        return Scaffold(
          appBar: AppBar(title: const Text('City maintenance report')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Submit via City portal (PublicStuff)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const PublicStuffEmbed(),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Report an issue',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MaintenanceCategory>(
                          value: _category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: MaintenanceCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _category = value ?? MaintenanceCategory.pothole),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'What are you seeing?',
                          ),
                          maxLines: 3,
                          validator: (value) =>
                              value != null && value.trim().isNotEmpty ? null : 'Describe the issue',
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location (cross-streets or address)',
                          ),
                          validator: (value) =>
                              value != null && value.trim().isNotEmpty ? null : 'Add a location',
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
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: const Text('Use my GPS'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _pickPhoto,
                              icon: const Icon(Icons.photo_camera_back),
                              label: Text(_photoPath == null ? 'Add photo' : 'Replace photo'),
                            ),
                          ],
                        ),
                        if (_photoPath != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _photoPath!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          if (File(_photoPath!).existsSync())
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.file(File(_photoPath!), height: 120, fit: BoxFit.cover),
                            ),
                        ],
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _submit(provider),
                          icon: const Icon(Icons.send),
                          label: const Text('Submit report'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent submissions (${reports.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (reports.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No maintenance reports yet.'),
                  ),
                )
              else
                ...reports.map((r) => _ReportTile(report: r)),
            ],
          ),
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});
  final MaintenanceReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.home_repair_service),
        title: Text(report.category.name.toUpperCase()),
        subtitle: Text('${report.department} • ${report.location}'),
        trailing: Text(
          report.createdAt.toLocal().toString().split('.').first,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
