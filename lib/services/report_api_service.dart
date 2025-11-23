import 'dart:developer';

import '../models/maintenance_report.dart';
import '../models/sighting_report.dart';
import 'api_client.dart';

class ReportApiService {
  ReportApiService(this._client);

  final ApiClient _client;

  Future<void> sendSighting(SightingReport report) async {
    try {
      await _client.post(
        '/reports/sightings',
        jsonBody: {
          'type': report.type.name,
          'location': report.location,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'notes': report.notes,
          'reportedAt': report.reportedAt.toIso8601String(),
          'occurrences': report.occurrences,
        },
      );
    } catch (e) {
      log('Failed to sync sighting: $e');
    }
  }

  Future<void> sendMaintenance(MaintenanceReport report) async {
    try {
      await _client.post(
        '/reports/maintenance',
        jsonBody: {
          'category': report.category.name,
          'description': report.description,
          'location': report.location,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'photoPath': report.photoPath,
          'department': report.department,
          'createdAt': report.createdAt.toIso8601String(),
        },
      );
    } catch (e) {
      log('Failed to sync maintenance: $e');
    }
  }
}
