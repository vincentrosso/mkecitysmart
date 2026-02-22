import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/parking_report.dart';
import '../models/reporter_rewards.dart';

/// Firestore path: `users/{uid}/reporter_rewards/current`
class ReporterRewardsService {
  ReporterRewardsService._();
  static final ReporterRewardsService instance = ReporterRewardsService._();

  static const String _docId = 'current';

  DocumentReference<Map<String, dynamic>> _ref(String uid) => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('reporter_rewards')
      .doc(_docId);

  // ── Read ────────────────────────────────────────────────────────────────

  /// Returns a live stream of the user's rewards doc, applying a weekly
  /// reset check on every emission.
  Stream<ReporterRewards> stream(String uid) {
    return _ref(uid).snapshots().map((snap) {
      final rewards = snap.exists
          ? ReporterRewards.fromFirestore(snap.data()!)
          : const ReporterRewards();
      return _applyWeeklyReset(rewards, uid);
    });
  }

  /// One-shot fetch with weekly reset check.
  Future<ReporterRewards> get(String uid) async {
    final snap = await _ref(uid).get();
    final rewards = snap.exists
        ? ReporterRewards.fromFirestore(snap.data()!)
        : const ReporterRewards();
    return _applyWeeklyReset(rewards, uid);
  }

  // ── Write ───────────────────────────────────────────────────────────────

  /// Awards points for a submitted report and handles tier + monthly entry
  /// logic. Returns the updated [ReporterRewards].
  Future<ReporterRewards> addReportPoints(
    String uid,
    ReportType reportType, {
    bool confirmedByOthers = false,
  }) async {
    final current = await get(uid);
    final now = DateTime.now();

    int pts = _pointsFor(reportType);
    if (confirmedByOthers) pts += ReportPoints.confirmationBonus;

    final newWeeklyPoints = current.weeklyPoints + pts;
    final newTotal = current.totalReportsAllTime + 1;
    bool justHitGoal =
        !current.weeklyGoalHit &&
        newWeeklyPoints >= ReportPoints.weeklyGoalForEntry;

    // Determine new ad-free / premium unlock
    DateTime? adFreeUntil = current.adFreeUntil;
    DateTime? premiumUntil = current.premiumUntil;
    List<String> badges = List<String>.from(current.badges);

    if (newWeeklyPoints >= RewardTier.premiumWeek.requiredPoints) {
      final base = (premiumUntil != null && premiumUntil.isAfter(now))
          ? premiumUntil
          : now;
      premiumUntil = base.add(const Duration(days: 7));
      if (!badges.contains('premiumWeek')) badges.add('premiumWeek');
    } else if (newWeeklyPoints >= RewardTier.adFreeWeek.requiredPoints) {
      final base = (adFreeUntil != null && adFreeUntil.isAfter(now))
          ? adFreeUntil
          : now;
      adFreeUntil = base.add(const Duration(days: 7));
      if (!badges.contains('adFreeWeek')) badges.add('adFreeWeek');
    }

    if (newWeeklyPoints >= RewardTier.activeBadge.requiredPoints &&
        !badges.contains('activeBadge')) {
      badges.add('activeBadge');
    }

    // Monthly raffle entry
    final currentMonthKey = _monthKey(now);
    int monthlyEntries = current.monthKey == currentMonthKey
        ? current.monthlyEntries
        : 0; // new month, reset
    if (justHitGoal) monthlyEntries += 1;

    final updated = current.copyWith(
      weeklyPoints: newWeeklyPoints,
      totalReportsAllTime: newTotal,
      monthlyEntries: monthlyEntries,
      monthKey: currentMonthKey,
      adFreeUntil: adFreeUntil,
      premiumUntil: premiumUntil,
      lastReportAt: now,
      badges: badges,
    );

    await _ref(uid).set(updated.toFirestore(), SetOptions(merge: true));
    debugPrint(
      'ReporterRewards: +$pts pts (total this week: ${updated.weeklyPoints})',
    );
    return updated;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Checks if the stored week differs from the current ISO week and resets
  /// weekly points if so, persisting the change back to Firestore.
  ReporterRewards _applyWeeklyReset(ReporterRewards r, String uid) {
    final now = DateTime.now();
    final (week, year) = _isoWeek(now);
    if (r.weekOfYear == week && r.weekYear == year) return r;

    // New week — reset
    final hitGoalLastWeek = r.weeklyGoalHit;
    final newStreak = hitGoalLastWeek ? r.streakWeeks + 1 : 0;

    // Month roll-over
    final currentMonthKey = _monthKey(now);
    final monthlyEntries = r.monthKey == currentMonthKey ? r.monthlyEntries : 0;

    final reset = r.copyWith(
      weeklyPoints: 0,
      weekOfYear: week,
      weekYear: year,
      streakWeeks: newStreak,
      monthlyEntries: monthlyEntries,
      monthKey: currentMonthKey,
    );

    // Fire-and-forget persist
    _ref(uid)
        .set(reset.toFirestore(), SetOptions(merge: true))
        .catchError((e) => debugPrint('ReporterRewards reset error: $e'));

    return reset;
  }

  static int _pointsFor(ReportType type) {
    switch (type) {
      case ReportType.leavingSpot:
        return ReportPoints.leavingSpot;
      case ReportType.spotAvailable:
        return ReportPoints.spotAvailable;
      case ReportType.enforcementSpotted:
      case ReportType.towTruckSpotted:
      case ReportType.streetSweepingActive:
      case ReportType.parkingBlocked:
        return ReportPoints.enforcementReport;
      case ReportType.parkedHere:
        return ReportPoints.parkedHere;
      case ReportType.spotTaken:
        return ReportPoints.spotTaken;
    }
  }

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Returns (isoWeek, isoWeekYear).
  static (int, int) _isoWeek(DateTime d) {
    // Jan 4 is always in week 1 of its year (ISO 8601)
    final jan4 = DateTime(d.year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    if (d.isBefore(startOfWeek1)) {
      // d belongs to last year's last week
      final jan4Prev = DateTime(d.year - 1, 1, 4);
      final startPrev = jan4Prev.subtract(Duration(days: jan4Prev.weekday - 1));
      final week = d.difference(startPrev).inDays ~/ 7 + 1;
      return (week, d.year - 1);
    }
    final week = d.difference(startOfWeek1).inDays ~/ 7 + 1;
    return (week, d.year);
  }
}
