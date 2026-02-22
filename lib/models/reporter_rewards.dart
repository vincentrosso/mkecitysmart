import 'package:cloud_firestore/cloud_firestore.dart';

/// Reward tier unlocked by the user based on weekly points.
enum RewardTier {
  none,
  activeBadge, // 20+ pts/week
  adFreeWeek, // 35+ pts/week → 7 days ad-free
  premiumWeek, // 60+ pts/week → 7 days premium predictions
}

extension RewardTierExt on RewardTier {
  String get label {
    switch (this) {
      case RewardTier.none:
        return 'No reward yet';
      case RewardTier.activeBadge:
        return 'Active Reporter 🏅';
      case RewardTier.adFreeWeek:
        return '7 Days Ad-Free 🎉';
      case RewardTier.premiumWeek:
        return '7 Days Premium ⭐';
    }
  }

  /// Points required to reach this tier
  int get requiredPoints {
    switch (this) {
      case RewardTier.none:
        return 0;
      case RewardTier.activeBadge:
        return 20;
      case RewardTier.adFreeWeek:
        return 35;
      case RewardTier.premiumWeek:
        return 60;
    }
  }
}

/// Point value for each report type.
class ReportPoints {
  static const int leavingSpot = 5;
  static const int spotAvailable = 4;
  static const int enforcementReport = 3;
  static const int parkedHere = 2;
  static const int spotTaken = 2;
  static const int confirmationBonus = 2;

  /// Weekly goal threshold for earning a monthly raffle entry.
  static const int weeklyGoalForEntry = 35;

  /// Ordered reward thresholds
  static final List<RewardTier> orderedTiers = [
    RewardTier.premiumWeek,
    RewardTier.adFreeWeek,
    RewardTier.activeBadge,
  ];
}

/// Holds the current reporter rewards state for a user.
/// Persisted under `users/{uid}/reporter_rewards/current` in Firestore.
class ReporterRewards {
  const ReporterRewards({
    this.weeklyPoints = 0,
    this.weekOfYear = 0,
    this.weekYear = 0,
    this.streakWeeks = 0,
    this.totalReportsAllTime = 0,
    this.monthlyEntries = 0,
    this.monthKey = '',
    this.adFreeUntil,
    this.premiumUntil,
    this.lastReportAt,
    this.badges = const [],
  });

  /// Points earned in the current ISO week.
  final int weeklyPoints;

  /// ISO week number of the current tracking period (1–53).
  final int weekOfYear;

  /// Year component of the ISO week (to disambiguate Jan weeks).
  final int weekYear;

  /// Consecutive weeks where the user hit the weekly goal.
  final int streakWeeks;

  /// Total reports ever submitted by this user.
  final int totalReportsAllTime;

  /// Raffle entries accumulated this calendar month.
  final int monthlyEntries;

  /// 'YYYY-MM' key for the current month's entries.
  final String monthKey;

  /// If set, user has ad-free access until this date.
  final DateTime? adFreeUntil;

  /// If set, user has premium predictions until this date.
  final DateTime? premiumUntil;

  /// Timestamp of the last report submitted.
  final DateTime? lastReportAt;

  /// Earned badge labels (e.g. ['activeBadge', '4weekStreak']).
  final List<String> badges;

  // ── Derived ────────────────────────────────────────────────────────────

  bool get isAdFreeActive =>
      adFreeUntil != null && adFreeUntil!.isAfter(DateTime.now());

  bool get isPremiumActive =>
      premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  /// Highest reward tier the user has hit this week.
  RewardTier get currentTier {
    for (final tier in ReportPoints.orderedTiers) {
      if (weeklyPoints >= tier.requiredPoints) return tier;
    }
    return RewardTier.none;
  }

  /// Points needed to reach the next tier (0 if already at top).
  int get pointsToNextTier {
    for (final tier in ReportPoints.orderedTiers.reversed) {
      if (weeklyPoints < tier.requiredPoints) {
        return tier.requiredPoints - weeklyPoints;
      }
    }
    return 0;
  }

  /// Next tier label the user is working toward.
  String get nextTierLabel {
    for (final tier in ReportPoints.orderedTiers.reversed) {
      if (weeklyPoints < tier.requiredPoints) return tier.label;
    }
    return 'Top tier reached! 🏆';
  }

  /// Whether the user has already hit the weekly goal for a raffle entry.
  bool get weeklyGoalHit => weeklyPoints >= ReportPoints.weeklyGoalForEntry;

  // ── Serialisation ───────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
    'weeklyPoints': weeklyPoints,
    'weekOfYear': weekOfYear,
    'weekYear': weekYear,
    'streakWeeks': streakWeeks,
    'totalReportsAllTime': totalReportsAllTime,
    'monthlyEntries': monthlyEntries,
    'monthKey': monthKey,
    'adFreeUntil': adFreeUntil != null
        ? Timestamp.fromDate(adFreeUntil!)
        : null,
    'premiumUntil': premiumUntil != null
        ? Timestamp.fromDate(premiumUntil!)
        : null,
    'lastReportAt': lastReportAt != null
        ? Timestamp.fromDate(lastReportAt!)
        : null,
    'badges': badges,
  };

  factory ReporterRewards.fromFirestore(Map<String, dynamic> d) =>
      ReporterRewards(
        weeklyPoints: (d['weeklyPoints'] as num?)?.toInt() ?? 0,
        weekOfYear: (d['weekOfYear'] as num?)?.toInt() ?? 0,
        weekYear: (d['weekYear'] as num?)?.toInt() ?? 0,
        streakWeeks: (d['streakWeeks'] as num?)?.toInt() ?? 0,
        totalReportsAllTime: (d['totalReportsAllTime'] as num?)?.toInt() ?? 0,
        monthlyEntries: (d['monthlyEntries'] as num?)?.toInt() ?? 0,
        monthKey: d['monthKey'] as String? ?? '',
        adFreeUntil: (d['adFreeUntil'] as Timestamp?)?.toDate(),
        premiumUntil: (d['premiumUntil'] as Timestamp?)?.toDate(),
        lastReportAt: (d['lastReportAt'] as Timestamp?)?.toDate(),
        badges: (d['badges'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  ReporterRewards copyWith({
    int? weeklyPoints,
    int? weekOfYear,
    int? weekYear,
    int? streakWeeks,
    int? totalReportsAllTime,
    int? monthlyEntries,
    String? monthKey,
    DateTime? adFreeUntil,
    DateTime? premiumUntil,
    DateTime? lastReportAt,
    List<String>? badges,
  }) => ReporterRewards(
    weeklyPoints: weeklyPoints ?? this.weeklyPoints,
    weekOfYear: weekOfYear ?? this.weekOfYear,
    weekYear: weekYear ?? this.weekYear,
    streakWeeks: streakWeeks ?? this.streakWeeks,
    totalReportsAllTime: totalReportsAllTime ?? this.totalReportsAllTime,
    monthlyEntries: monthlyEntries ?? this.monthlyEntries,
    monthKey: monthKey ?? this.monthKey,
    adFreeUntil: adFreeUntil ?? this.adFreeUntil,
    premiumUntil: premiumUntil ?? this.premiumUntil,
    lastReportAt: lastReportAt ?? this.lastReportAt,
    badges: badges ?? this.badges,
  );
}
