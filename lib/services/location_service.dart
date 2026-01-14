import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../models/parking_zone.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermission();
    if (!permission) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
      ),
    );
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission != LocationPermission.denied;
  }

  double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const earthRadius = 6371;
    final dLat = _degToRad(endLat - startLat);
    final dLng = _degToRad(endLng - startLng);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(startLat)) *
            cos(_degToRad(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  List<ParkingZone> loadDefaultZones() {
    final now = DateTime.now();
    return [
      ParkingZone(
        id: 'zone-riverwest',
        name: 'Riverwest Sector A',
        description: 'Residential blocks near Holton & Center',
        side: 'Odd numbers',
        latitude: 43.0673,
        longitude: -87.8946,
        radiusMeters: 250,
        nextSweep: now.add(const Duration(days: 2, hours: 4)),
        frequency: 'Every 2nd Monday',
        allowedSide: 'Even park only',
      ),
      ParkingZone(
        id: 'zone-eastside',
        name: 'East Side Corridor',
        description: 'Farwell Ave corridor',
        side: 'Even numbers',
        latitude: 43.0679,
        longitude: -87.8865,
        radiusMeters: 300,
        nextSweep: now.add(const Duration(days: 1, hours: 3)),
        frequency: 'Weekly Wednesday',
        allowedSide: 'Odd park only',
      ),
      ParkingZone(
        id: 'zone-bayview',
        name: 'Bay View Lakeshore',
        description: 'Kinnickinnic Ave to Shore Dr',
        side: 'All curb space',
        latitude: 42.9818,
        longitude: -87.888,
        radiusMeters: 400,
        nextSweep: now.add(const Duration(hours: 20)),
        frequency: 'Emergency deployment',
        allowedSide: 'Use posted detours',
      ),
    ];
  }

  List<String> searchAddresses(String query) {
    final sample = [
      '2469 N Holton St',
      '1204 E Brady St',
      '2200 S Kinnickinnic Ave',
      '401 W Wisconsin Ave',
      '735 N Water St',
    ];
    if (query.isEmpty) return sample.take(3).toList();
    final lower = query.toLowerCase();
    return sample
        .where((value) => value.toLowerCase().contains(lower))
        .toList();
  }

  List<String> buildWalkingDirections({
    required Position start,
    required ParkingZone destination,
  }) {
    final distance = calculateDistanceKm(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: destination.latitude,
      endLng: destination.longitude,
    );
    final minutes = (distance * 12).clamp(2, 45).round();
    return [
      'Head toward ${destination.name}',
      'Follow signage for ${destination.allowedSide}',
      'Estimated walking time: $minutes min',
    ];
  }

  double _degToRad(double deg) => deg * (pi / 180);
}
