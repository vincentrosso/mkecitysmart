class TicketRiskPredictionService {
  /// Predicts risk of getting a ticket (0-1).
  ///
  /// Factors:
  /// - Day/time (rush hours heavier).
  /// - Weekend vs weekday.
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
    final hourFactor = _hourPenalty(when.hour);
    final dayFactor = _dayPenalty(when.weekday);
    final eventFactor = eventLoad.clamp(0, 1) * 0.25;
    final historyFactor = historicalDensity.clamp(0, 1) * 0.25;
    final monthFactor = monthlyFactor.clamp(0, 1) * 0.15;
    final cityFactor = cityHotspotDensity.clamp(0, 1) * 0.15;
    final noise = _locationNoise(latitude, longitude) * 0.05;

    final score = hourFactor +
        dayFactor +
        eventFactor +
        historyFactor +
        monthFactor +
        cityFactor +
        noise;
    return score.clamp(0.0, 1.0);
  }

  String riskMessage(double score) {
    if (score >= 0.85) {
      return 'Very high ticket risk right now. Move soon or verify signage.';
    } else if (score >= 0.7) {
      return 'High ticket risk detected in this area. Check rules and move if needed.';
    } else if (score >= 0.5) {
      return 'Moderate ticket risk. Keep an eye on sweeps and meters.';
    }
    return 'Low ticket risk currently.';
  }

  double _hourPenalty(int hour) {
    // Rush hours and late-night enforcement.
    if (hour >= 7 && hour <= 9) return 0.35; // morning rush
    if (hour >= 16 && hour <= 19) return 0.35; // evening rush
    if (hour >= 22 || hour <= 2) return 0.25; // late night sweeps
    if (hour >= 11 && hour <= 13) return 0.2; // mid-day checks
    return 0.15;
  }

  double _dayPenalty(int weekday) {
    // Weekdays higher; weekends lower.
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return 0.15;
    }
    return 0.25;
  }

  double _locationNoise(double lat, double lng) {
    final hash = (lat * 10000).round() ^ (lng * 10000).round();
    return (hash % 100) / 100.0; // 0-0.99
  }
}
