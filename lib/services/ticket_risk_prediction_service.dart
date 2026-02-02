import 'citation_hotspot_service.dart';

class TicketRiskPredictionService {
  final CitationHotspotService _hotspotService =
      CitationHotspotService.instance;

  /// Predicts risk of getting a ticket (0-1).
  ///
  /// Now powered by 466K real Milwaukee citation records!
  /// Factors:
  /// - Day/time from real citation data patterns
  /// - Event load (0-1).
  /// - Historical ticket density (0-1).
  /// - Location noise to vary nearby points.
  double predictRisk({
    required DateTime when,
    required double latitude,
    required double longitude,
    double eventLoad = 0.0, // 0=no event, 1=major event
    double historicalDensity = 0.0, // 0-1 based on analytics
  }) {
    return predictRiskWithCityStats(
      when: when,
      latitude: latitude,
      longitude: longitude,
      eventLoad: eventLoad,
      historicalDensity: historicalDensity,
      monthlyFactor: 0.0,
      cityHotspotDensity: 0.0,
    );
  }

  /// Extended version that takes city ticket stats:
  /// - [monthlyFactor]: 0-1 multiplier based on month trend (e.g., winter sweeps).
  /// - [cityHotspotDensity]: 0-1 density from city heatmaps for this geo bucket.
  double predictRiskWithCityStats({
    required DateTime when,
    required double latitude,
    required double longitude,
    double eventLoad = 0.0,
    double historicalDensity = 0.0,
    double monthlyFactor = 0.0,
    double cityHotspotDensity = 0.0,
  }) {
    // Get real citation-based risk multiplier
    final citationMultiplier = _hotspotService.getRiskMultiplier(
      when.weekday % 7, // Convert to JS day (0=Sun)
      when.hour,
    );

    // Normalize citation multiplier to 0-0.5 range (it's the main factor now)
    final citationFactor = (citationMultiplier / 5.0).clamp(0.0, 0.5);

    final eventFactor = eventLoad.clamp(0, 1) * 0.15;
    final historyFactor = historicalDensity.clamp(0, 1) * 0.15;
    final monthFactor = monthlyFactor.clamp(0, 1) * 0.10;
    final cityFactor = cityHotspotDensity.clamp(0, 1) * 0.10;
    final noise = _locationNoise(latitude, longitude) * 0.05;

    final score =
        citationFactor +
        eventFactor +
        historyFactor +
        monthFactor +
        cityFactor +
        noise;
    return score.clamp(0.0, 1.0);
  }

  String riskMessage(double score) {
    // Check if we're in night parking window
    if (_hotspotService.isNightParkingWindow()) {
      return '🚨 NIGHT PARKING ENFORCEMENT ACTIVE (2-6 AM). This is peak citation time!';
    }

    if (score >= 0.85) {
      return 'Very high ticket risk right now. Move soon or verify signage.';
    } else if (score >= 0.7) {
      return 'High ticket risk detected in this area. Check rules and move if needed.';
    } else if (score >= 0.5) {
      return 'Moderate ticket risk. Keep an eye on sweeps and meters.';
    }
    return 'Low ticket risk currently.';
  }

  /// Get enforcement summary for display
  String getEnforcementSummary() {
    return _hotspotService.getEnforcementSummary();
  }

  /// Get top violation types to warn about
  List<String> getTopViolations() {
    return _hotspotService.getTopViolations();
  }

  /// Get peak enforcement hours
  List<Map<String, dynamic>> getPeakHours() {
    return _hotspotService.getPeakHours();
  }

  double _locationNoise(double lat, double lng) {
    final hash = (lat * 10000).round() ^ (lng * 10000).round();
    return (hash % 100) / 100.0; // 0-0.99
  }
}
