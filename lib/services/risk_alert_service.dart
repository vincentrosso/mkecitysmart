import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';

import '../models/ticket.dart';
import '../providers/user_provider.dart';
import 'location_service.dart';
import 'notification_service.dart';
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
        log('High tow risk detected ($score). Triggering local alert.');
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
      final riskScore = _ticketRisk.predictRisk(
        when: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
        eventLoad: eventLoad,
        historicalDensity: ticketDensity,
      );
      if (riskScore >= 0.7) {
        final now = DateTime.now();
        if (_lastTicketAlert == null ||
            now.difference(_lastTicketAlert!).inMinutes >= 90) {
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
      log('Ticket risk check skipped: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }
}
