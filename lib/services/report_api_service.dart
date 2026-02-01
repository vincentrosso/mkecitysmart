import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/maintenance_report.dart';
import '../models/sighting_report.dart';
import 'api_client.dart';

class ReportApiService {
  ReportApiService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> sendSighting(SightingReport report) async {
    try {
      // Use Firebase Cloud Function for sighting submission
      // This triggers the nearby user fanout for push notifications
      final callable = FirebaseFunctions.instance.httpsCallable('submitSighting');
      final result = await callable.call({
        'location': report.location,
        'notes': report.notes,
        'isEnforcer': report.type == SightingType.parkingEnforcer,
        'latitude': report.latitude,
        'longitude': report.longitude,
      });
      
      log('Sighting submitted via Cloud Function: ${result.data}');
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      log('Failed to submit sighting via Cloud Function: $e');
      
      // Fallback to REST API if Cloud Function fails
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
      } catch (e2) {
        log('Fallback REST API also failed: $e2');
      }
      return {'success': false, 'error': e.toString()};
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
