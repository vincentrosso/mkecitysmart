import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/ticket.dart';
import '../providers/user_provider.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'city_ticket_stats_service.dart';
import 'ticket_risk_prediction_service.dart';
import 'parking_risk_service.dart';

/// Lightweight in-app risk watcher. In background, this should be replaced by
/// a push-based solution (FCM/APNs) driven by the backend.
class RiskAlertService {
  RiskAlertService._({
    NotificationService? notificationService,
    LocationService? locationService,
    TicketRiskPredictionService? ticketRiskPredictionService,
    CityTicketStatsService? cityStatsService,
    DateTime Function()? now,
  })  : _notification = notificationService ?? NotificationService.instance,
        _location = locationService ?? LocationService(),
        _ticketRisk = ticketRiskPredictionService ?? TicketRiskPredictionService(),
        _cityStats = cityStatsService ?? CityTicketStatsService(),
        _now = now ?? DateTime.now;

  static final RiskAlertService instance = RiskAlertService._();
  factory RiskAlertService.test({
    NotificationService? notificationService,
    LocationService? locationService,
    TicketRiskPredictionService? ticketRiskPredictionService,
    CityTicketStatsService? cityStatsService,
    DateTime Function()? now,
  }) {
    return RiskAlertService._(
      notificationService: notificationService,
      locationService: locationService,
      ticketRiskPredictionService: ticketRiskPredictionService,
      cityStatsService: cityStatsService,
      now: now,
    );
  }

  Timer? _timer;
  bool _running = false;
  DateTime? _lastHighAlert;
  DateTime? _lastTicketAlert;
  DateTime? _lastCitationAlert; // NEW: Cooldown for citation-based alerts
  Position? _lastPosition;
  final TicketRiskPredictionService _ticketRisk;
  final LocationService _location;
  final NotificationService _notification;
  final CityTicketStatsService _cityStats;
  final ParkingRiskService _parkingRisk = ParkingRiskService.instance;
  final DateTime Function() _now;

  // ABUSE PREVENTION: Track alert counts per day to prevent spam
  int _dailyAlertCount = 0;
  DateTime? _dailyAlertReset;
  static const int _maxDailyAlerts = 6; // Max 6 risk alerts per day

  void start(UserProvider provider) {
    if (_running) return;
    _running = true;
    _timer ??= Timer.periodic(const Duration(minutes: 5), (_) {
      _check(provider);
    });
    // Initial eager check
    _check(provider);
  }

  Future<void> _check(UserProvider provider) async {
    final now = _now();
    
    // Reset daily counter at midnight
    if (_dailyAlertReset == null || 
        now.day != _dailyAlertReset!.day) {
      _dailyAlertCount = 0;
      _dailyAlertReset = now;
    }
    
    final score = provider.towRiskIndex;
    if (score >= 70) {
      if (_lastHighAlert == null ||
          now.difference(_lastHighAlert!).inMinutes >= 60) {
        _lastHighAlert = now;
        dev.log('High tow risk detected ($score). Triggering local alert.');
        _notification.showLocal(
          title: 'High tow/ticket risk',
          body: 'Recent enforcers or sweeps nearby. Check parking status.',
        );
      }
    }

    // Ticket risk predictor (auto push unless turned off).
    final prefs = provider.profile?.preferences;
    final allow = prefs?.ticketRiskAlerts ?? true;
    if (!allow) return;

    try {
      final position = await _location.getCurrentPosition();
      if (position == null) return;
      
      // === NEW: Check citation-based risk from backend ===
      await _checkCitationRisk(position, now);
      
      final ticketDensity =
          provider.tickets.where((t) => t.status == TicketStatus.open).length /
              10;
      final eventLoad = provider.sightings.isNotEmpty ? 0.3 : 0.0;
      final isNewArea = _isNewArea(position);
      _lastPosition = position;
      final stats = _cityStats.lookup(
        cityId: provider.cityId,
        when: now,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final riskScore = _ticketRisk.predictRiskWithCityStats(
        when: now,
        latitude: position.latitude,
        longitude: position.longitude,
        eventLoad: eventLoad,
        historicalDensity: ticketDensity,
        monthlyFactor: stats.monthlyFactor,
        cityHotspotDensity: stats.hotspotDensity,
      );
      if (riskScore >= 0.7) {
        final coolDown = isNewArea ? 30 : 90;
        if (_lastTicketAlert == null ||
            now.difference(_lastTicketAlert!).inMinutes >= coolDown) {
          _lastTicketAlert = now;
          final msg = _ticketRisk.riskMessage(riskScore);
          _notification.showLocal(
            title: 'Ticket risk nearby',
            body: msg,
          );
        }
      }
    } on PermissionDeniedException {
      // Silently ignore; user declined location.
    } catch (e) {
      dev.log('Ticket risk check skipped: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  /// Check citation-based risk from backend and alert if high risk during peak time.
  /// 
  /// SPAM PREVENTION:
  /// - Max 1 citation alert per 2 hours per location
  /// - Max 6 alerts per day total
  /// - Only alerts for HIGH risk (70%+) during peak hours
  Future<void> _checkCitationRisk(Position position, DateTime now) async {
    // Don't spam - check daily limit first
    if (_dailyAlertCount >= _maxDailyAlerts) {
      dev.log('Citation risk check skipped: daily limit reached ($_dailyAlertCount)');
      return;
    }
    
    // Cooldown: min 2 hours between citation alerts
    if (_lastCitationAlert != null &&
        now.difference(_lastCitationAlert!).inMinutes < 120) {
      return;
    }
    
    try {
      final risk = await _parkingRisk.getRiskForLocation(
        position.latitude,
        position.longitude,
      );
      
      if (risk == null) return;
      
      // Only alert for HIGH risk areas during peak hours
      if (risk.riskLevel == RiskLevel.high && 
          risk.peakHours.contains(now.hour)) {
        _lastCitationAlert = now;
        _dailyAlertCount++;
        
        final message = '${risk.riskPercentage}% citation risk here. '
            '${risk.topViolations.isNotEmpty ? "Watch for: ${risk.topViolations.first.replaceAll('_', ' ')}" : "Check parking signs!"}';
        
        _notification.showLocal(
          title: '⚠️ High Risk Parking Zone',
          body: message,
        );
        
        dev.log('Citation risk alert sent: ${risk.riskPercentage}% at hour ${now.hour}');
      }
    } catch (e) {
      dev.log('Citation risk check failed: $e');
    }
  }

  bool _isNewArea(Position pos) {
    if (_lastPosition == null) return true;
    final dist = _haversineMeters(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );
    return dist > 150; // treat moves over ~150m as a new area
  }

  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // meters
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);
}
