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

/// Lightweight in-app risk watcher. In background, this should be replaced by
/// a push-based solution (FCM/APNs) driven by the backend.
class RiskAlertService {
  RiskAlertService._();

  static final RiskAlertService instance = RiskAlertService._();

  Timer? _timer;
  bool _running = false;
  DateTime? _lastHighAlert;
  DateTime? _lastTicketAlert;
  final _ticketRisk = TicketRiskPredictionService();
  Position? _lastPosition;
  final _cityStats = CityTicketStatsService();

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
    final score = provider.towRiskIndex;
    if (score >= 70) {
      final now = DateTime.now();
      if (_lastHighAlert == null ||
          now.difference(_lastHighAlert!).inMinutes >= 60) {
        _lastHighAlert = now;
        dev.log('High tow risk detected ($score). Triggering local alert.');
        NotificationService.instance.showLocal(
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
      final position = await LocationService().getCurrentPosition();
      if (position == null) return;
      final ticketDensity =
          provider.tickets.where((t) => t.status == TicketStatus.open).length /
              10;
      final eventLoad = provider.sightings.isNotEmpty ? 0.3 : 0.0;
      final isNewArea = _isNewArea(position);
      _lastPosition = position;
      final stats = _cityStats.lookup(
        cityId: provider.cityId,
        when: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final riskScore = _ticketRisk.predictRiskWithCityStats(
        when: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        eventLoad: eventLoad,
        historicalDensity: ticketDensity,
        monthlyFactor: stats.monthlyFactor,
        cityHotspotDensity: stats.hotspotDensity,
      );
      if (riskScore >= 0.7) {
        final now = DateTime.now();
        final coolDown = isNewArea ? 30 : 90;
        if (_lastTicketAlert == null ||
            now.difference(_lastTicketAlert!).inMinutes >= coolDown) {
          _lastTicketAlert = now;
          final msg = _ticketRisk.riskMessage(riskScore);
          NotificationService.instance.showLocal(
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
