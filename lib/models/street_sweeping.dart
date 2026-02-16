class StreetSweepingSchedule {
  const StreetSweepingSchedule({
    required this.id,
    required this.zone,
    required this.side,
    required this.nextSweep,
    required this.gpsMonitoring,
    required this.advance24h,
    required this.final2h,
    required this.customMinutes,
    required this.alternativeParking,
    required this.cleanStreakDays,
    required this.violationsPrevented,
    this.sweepDay,
    this.weekPattern,
  });

  final String id;
  final String zone;
  final String side;
  final DateTime nextSweep;
  final bool gpsMonitoring;
  final bool advance24h;
  final bool final2h;
  final int customMinutes;
  final List<String> alternativeParking;
  final int cleanStreakDays;
  final int violationsPrevented;

  /// Day of week for sweeping: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri (user-entered)
  final int? sweepDay;

  /// Week pattern: [1,3] = 1st & 3rd weeks; [2,4] = 2nd & 4th weeks (user-entered)
  final List<int>? weekPattern;

  /// Whether this schedule has user-entered timing data
  bool get hasUserSchedule => sweepDay != null && weekPattern != null;

  /// Human-readable day name
  String get dayName {
    if (sweepDay == null) return 'Not set';
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return sweepDay! >= 1 && sweepDay! <= 5 ? days[sweepDay!] : 'Unknown';
  }

  /// Human-readable week pattern
  String get weekPatternName {
    if (weekPattern == null || weekPattern!.isEmpty) return 'Not set';
    if (weekPattern!.contains(1) && weekPattern!.contains(3)) {
      return '1st & 3rd weeks';
    } else if (weekPattern!.contains(2) && weekPattern!.contains(4)) {
      return '2nd & 4th weeks';
    }
    return weekPattern!.map((w) => '$w${_ordinal(w)}').join(' & ');
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  StreetSweepingSchedule copyWith({
    bool? gpsMonitoring,
    bool? advance24h,
    bool? final2h,
    int? customMinutes,
    DateTime? nextSweep,
    int? cleanStreakDays,
    int? violationsPrevented,
    List<String>? alternativeParking,
    int? sweepDay,
    List<int>? weekPattern,
  }) {
    return StreetSweepingSchedule(
      id: id,
      zone: zone,
      side: side,
      nextSweep: nextSweep ?? this.nextSweep,
      gpsMonitoring: gpsMonitoring ?? this.gpsMonitoring,
      advance24h: advance24h ?? this.advance24h,
      final2h: final2h ?? this.final2h,
      customMinutes: customMinutes ?? this.customMinutes,
      alternativeParking: alternativeParking ?? this.alternativeParking,
      cleanStreakDays: cleanStreakDays ?? this.cleanStreakDays,
      violationsPrevented: violationsPrevented ?? this.violationsPrevented,
      sweepDay: sweepDay ?? this.sweepDay,
      weekPattern: weekPattern ?? this.weekPattern,
    );
  }

  factory StreetSweepingSchedule.fromJson(Map<String, dynamic> json) {
    return StreetSweepingSchedule(
      id: json['id'] as String,
      zone: json['zone'] as String,
      side: json['side'] as String,
      nextSweep: DateTime.parse(json['nextSweep'] as String),
      gpsMonitoring: json['gpsMonitoring'] as bool? ?? false,
      advance24h: json['advance24h'] as bool? ?? true,
      final2h: json['final2h'] as bool? ?? true,
      customMinutes: json['customMinutes'] as int? ?? 60,
      alternativeParking: (json['alternativeParking'] as List<dynamic>? ?? [])
          .map((value) => value as String)
          .toList(),
      cleanStreakDays: json['cleanStreakDays'] as int? ?? 0,
      violationsPrevented: json['violationsPrevented'] as int? ?? 0,
      sweepDay: json['sweepDay'] as int?,
      weekPattern: (json['weekPattern'] as List<dynamic>?)?.cast<int>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'zone': zone,
    'side': side,
    'nextSweep': nextSweep.toIso8601String(),
    'gpsMonitoring': gpsMonitoring,
    'advance24h': advance24h,
    'final2h': final2h,
    'customMinutes': customMinutes,
    'alternativeParking': alternativeParking,
    'cleanStreakDays': cleanStreakDays,
    'violationsPrevented': violationsPrevented,
    'sweepDay': sweepDay,
    'weekPattern': weekPattern,
  };
}
