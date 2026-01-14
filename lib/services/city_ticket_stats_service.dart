class CityTicketStats {
  const CityTicketStats({
    required this.monthlyFactor,
    required this.hotspotDensity,
  });

  /// 0-1 multiplier for the current month (higher = more tickets).
  final double monthlyFactor;

  /// 0-1 density for this geo bucket from city heatmaps/analytics.
  final double hotspotDensity;
}

/// Placeholder city stats service. Replace with real backend lookups
/// (e.g., per-city ticket heatmaps and monthly trends).
class CityTicketStatsService {
  CityTicketStats lookup({
    required String cityId,
    required DateTime when,
    required double latitude,
    required double longitude,
  }) {
    final monthFactor = _monthSeasonality(when.month);
    final hotspot = _hotspotNoise(latitude, longitude);
    // Simple city modifier: different base per cityId.
    final cityBias = _cityBias(cityId);
    return CityTicketStats(
      monthlyFactor: (monthFactor + cityBias).clamp(0.0, 1.0),
      hotspotDensity: (hotspot + cityBias * 0.2).clamp(0.0, 1.0),
    );
  }

  double _monthSeasonality(int month) {
    // Rough seasonality: winter > fall > spring > summer.
    if (month == 12 || month <= 2) return 0.7;
    if (month >= 9 && month <= 11) return 0.55;
    if (month >= 6 && month <= 8) return 0.35;
    return 0.45;
  }

  double _hotspotNoise(double lat, double lng) {
    final hash = (lat * 10000).round() ^ (lng * 10000).round();
    return (hash % 100) / 100.0; // 0-0.99
  }

  double _cityBias(String cityId) {
    // Stub biases by city; replace with real analytics.
    switch (cityId) {
      case 'nyc':
        return 0.15;
      case 'sf':
        return 0.1;
      case 'chi':
        return 0.12;
      default:
        return 0.05;
    }
  }
}
