import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/parking_zone.dart';
import '../models/street_sweeping.dart';
import '../models/violation_record.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({required LocationService service}) : _service = service;

  final LocationService _service;

  Position? _position;
  bool _isLoading = false;
  bool _gpsDenied = false;
  List<ParkingZone> _zones = const [];
  List<StreetSweepingSchedule> _schedules = const [];
  ParkingZone? _selectedZone;
  bool _insideGeofence = false;
  String? _emergencyMessage;
  List<String> _addressSuggestions = const [];
  List<String> _walkingDirections = const [];
  final List<ViolationRecord> _violations = [
    ViolationRecord(
      date: DateTime.now().subtract(const Duration(days: 7)),
      zoneName: 'Riverwest Sector A',
      status: 'Prevented',
      preventionReason: 'Vehicle moved after 24h reminder',
    ),
    ViolationRecord(
      date: DateTime.now().subtract(const Duration(days: 15)),
      zoneName: 'East Side Corridor',
      status: 'Ticketed',
      preventionReason: 'Stayed past posted hours',
    ),
    ViolationRecord(
      date: DateTime.now().subtract(const Duration(days: 21)),
      zoneName: 'Bay View Lakeshore',
      status: 'Prevented',
      preventionReason: 'Emergency alert triggered move',
    ),
  ];

  Timer? _ticker;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  bool get gpsDenied => _gpsDenied;
  List<ParkingZone> get zones => _zones;
  List<ParkingZone> get sortedZones {
    final list = [..._zones];
    list.sort((a, b) => a.nextSweep.compareTo(b.nextSweep));
    return list;
  }

  List<StreetSweepingSchedule> get sweepingSchedules => _schedules;
  ParkingZone? get selectedZone => _selectedZone;
  bool get insideGeofence => _insideGeofence;
  String? get emergencyMessage => _emergencyMessage;
  List<String> get addressSuggestions => _addressSuggestions;
  List<String> get walkingDirections => _walkingDirections;
  List<ViolationRecord> get violationHistory => List.unmodifiable(_violations);

  int get preventedViolations =>
      _violations.where((record) => record.status == 'Prevented').length;
  int get ticketsReceived =>
      _violations.where((record) => record.status == 'Ticketed').length;

  List<String> get cityParkingSuggestions {
    final set = <String>{};
    for (final schedule in _schedules) {
      set.addAll(schedule.alternativeParking);
    }
    return set.toList();
  }

  Future<void> initialize() async {
    _zones = _service.loadDefaultZones();
    _schedules = _seedSweepingSchedules();
    await refreshLocation();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _evaluateEmergencyAlerts(),
    );
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();
    final result = await _service.getCurrentPosition();
    _isLoading = false;
    if (result == null) {
      _gpsDenied = true;
      notifyListeners();
      return;
    }
    _gpsDenied = false;
    _position = result;
    _evaluateGeofence();
    _evaluateEmergencyAlerts();
    notifyListeners();
  }

  void selectZone(ParkingZone zone) {
    _selectedZone = zone;
    if (_position != null) {
      _walkingDirections = _service.buildWalkingDirections(
        start: _position!,
        destination: zone,
      );
    }
    notifyListeners();
  }

  void searchAddress(String query) {
    _addressSuggestions = _service.searchAddresses(query);
    notifyListeners();
  }

  void acknowledgeEmergency() {
    _emergencyMessage = null;
    notifyListeners();
  }

  Future<void> updateSweepingNotifications(
    String id, {
    bool? gpsMonitoring,
    bool? advance24h,
    bool? final2h,
    int? customMinutes,
  }) async {
    _schedules = _schedules
        .map(
          (sweep) => sweep.id == id
              ? sweep.copyWith(
                  gpsMonitoring: gpsMonitoring,
                  advance24h: advance24h,
                  final2h: final2h,
                  customMinutes: customMinutes,
                )
              : sweep,
        )
        .toList();
    notifyListeners();
  }

  Future<void> logVehicleMoved(String id) async {
    _schedules = _schedules
        .map(
          (sweep) => sweep.id == id
              ? sweep.copyWith(
                  cleanStreakDays: sweep.cleanStreakDays + 1,
                  violationsPrevented: sweep.violationsPrevented + 1,
                )
              : sweep,
        )
        .toList();
    notifyListeners();
  }

  void _evaluateGeofence() {
    if (_position == null) return;
    final insideZone = _zones.firstWhere(
      (zone) => _distanceToZoneMeters(zone) < zone.radiusMeters,
      orElse: () => _zones.first,
    );
    _insideGeofence =
        _distanceToZoneMeters(insideZone) < insideZone.radiusMeters;
    _selectedZone ??= insideZone;
  }

  void _evaluateEmergencyAlerts() {
    final now = DateTime.now();
    final urgent = _schedules.firstWhere(
      (schedule) => schedule.nextSweep.difference(now).inHours <= 6,
      orElse: () => _schedules.first,
    );
    if (urgent.nextSweep.difference(now).inHours <= 6) {
      _emergencyMessage =
          '${urgent.zone} sweep within 6 hours. Park on ${urgent.side}.';
    } else {
      _emergencyMessage = null;
    }
    notifyListeners();
  }

  double _distanceToZoneMeters(ParkingZone zone) {
    if (_position == null) return double.infinity;
    final km = _service.calculateDistanceKm(
      startLat: _position!.latitude,
      startLng: _position!.longitude,
      endLat: zone.latitude,
      endLng: zone.longitude,
    );
    return km * 1000;
  }

  List<StreetSweepingSchedule> _seedSweepingSchedules() {
    final now = DateTime.now();
    return [
      StreetSweepingSchedule(
        id: 'sweep-1',
        zone: 'Riverwest Sector A',
        side: 'Odd side',
        nextSweep: now.add(const Duration(days: 2, hours: 3)),
        gpsMonitoring: true,
        advance24h: true,
        final2h: true,
        customMinutes: 90,
        alternativeParking: const [
          'Booth St lot – 0.2 mi',
          'Holton & Center ramp',
        ],
        cleanStreakDays: 21,
        violationsPrevented: 4,
      ),
      StreetSweepingSchedule(
        id: 'sweep-2',
        zone: 'East Side Corridor',
        side: 'Even side',
        nextSweep: now.add(const Duration(days: 1, hours: 6)),
        gpsMonitoring: true,
        advance24h: true,
        final2h: true,
        customMinutes: 60,
        alternativeParking: const ['Market St garage', 'Broadway public lot'],
        cleanStreakDays: 12,
        violationsPrevented: 2,
      ),
      StreetSweepingSchedule(
        id: 'sweep-3',
        zone: 'Bay View Lakeshore',
        side: 'All curb space',
        nextSweep: now.add(const Duration(hours: 18)),
        gpsMonitoring: false,
        advance24h: true,
        final2h: true,
        customMinutes: 45,
        alternativeParking: const [
          'KK Ave park & ride',
          'Shore Dr overflow lot',
        ],
        cleanStreakDays: 5,
        violationsPrevented: 1,
      ),
    ];
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
