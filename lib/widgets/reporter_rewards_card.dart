import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reporter_rewards.dart';
import '../providers/user_provider.dart';
import '../services/reporter_rewards_service.dart';
import '../theme/app_theme.dart';

/// Dashboard card showing the user's reporter-rewards progress.
///
/// Displays:
///   • Weekly points progress bar toward the next tier
///   • Current tier badge & streak
///   • Monthly raffle entry count
///   • Active perks (ad-free / premium) if any
///   • Quick link to submit a crowdsource report
class ReporterRewardsCard extends StatelessWidget {
  const ReporterRewardsCard({super.key, this.onReportTap});

  /// Called when the user taps "Submit a Report" — typically opens the
  /// crowdsource report bottom sheet.
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().profile?.id;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<ReporterRewards>(
      stream: ReporterRewardsService.instance.stream(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _CardShell(child: _LoadingContent());
        }
        return _CardShell(
          child: _Content(rewards: snap.data!, onReportTap: onReportTap),
        );
      },
    );
  }
}

// ── Shell ────────────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCitySmartCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCitySmartYellow.withAlpha(60), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: kCitySmartYellow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Reporter Rewards',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: kCitySmartYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
      ],
    );
  }
}

// ── Main content ─────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({required this.rewards, this.onReportTap});
  final ReporterRewards rewards;
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tier = rewards.currentTier;
    final progressGoal = _nextTierThreshold(rewards.weeklyPoints);
    final progress = progressGoal > 0
        ? (rewards.weeklyPoints / progressGoal).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: kCitySmartYellow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Reporter Rewards',
              style: textTheme.titleSmall?.copyWith(
                color: kCitySmartYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (rewards.streakWeeks > 1)
              _Chip(
                label: '🔥 ${rewards.streakWeeks}wk streak',
                color: Colors.orange.shade700,
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Points & progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${rewards.weeklyPoints} pts this week',
              style: textTheme.bodyMedium?.copyWith(color: kCitySmartText),
            ),
            Text(
              tier == RewardTier.premiumWeek
                  ? 'Top tier! 🏆'
                  : '${rewards.pointsToNextTier} pts to ${_shortLabel(rewards.nextTierLabel)}',
              style: textTheme.bodySmall?.copyWith(color: kCitySmartMuted),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: kCitySmartGreen,
            valueColor: AlwaysStoppedAnimation<Color>(
              tier == RewardTier.premiumWeek
                  ? Colors.purpleAccent
                  : tier == RewardTier.adFreeWeek
                  ? Colors.green.shade400
                  : kCitySmartYellow,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Active perks row
        if (rewards.isAdFreeActive || rewards.isPremiumActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (rewards.isPremiumActive)
                  _Chip(
                    label: 'Premium until ${_shortDate(rewards.premiumUntil!)}',
                    color: Colors.purple.shade700,
                  ),
                if (rewards.isPremiumActive && rewards.isAdFreeActive)
                  const SizedBox(width: 6),
                if (rewards.isAdFreeActive && !rewards.isPremiumActive)
                  _Chip(
                    label: 'Ad-free until ${_shortDate(rewards.adFreeUntil!)}',
                    color: Colors.teal.shade700,
                  ),
              ],
            ),
          ),

        // Raffle entry row
        Row(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 14,
              color: kCitySmartMuted,
            ),
            const SizedBox(width: 4),
            Text(
              '${rewards.monthlyEntries} raffle entr${rewards.monthlyEntries == 1 ? 'y' : 'ies'} this month',
              style: textTheme.bodySmall?.copyWith(color: kCitySmartMuted),
            ),
            const Spacer(),
            Text(
              '${rewards.totalReportsAllTime} total reports',
              style: textTheme.bodySmall?.copyWith(color: kCitySmartMuted),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // CTA
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: kCitySmartYellow.withAlpha(25),
              foregroundColor: kCitySmartYellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: kCitySmartYellow.withAlpha(80)),
              ),
            ),
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Submit a Report  +pts'),
            onPressed: onReportTap,
          ),
        ),
      ],
    );
  }

  /// Threshold for the next tier above the current point total.
  static int _nextTierThreshold(int pts) {
    for (final tier in ReportPoints.orderedTiers.reversed) {
      if (pts < tier.requiredPoints) return tier.requiredPoints;
    }
    // Already at top tier
    return RewardTier.premiumWeek.requiredPoints;
  }

  static String _shortLabel(String label) {
    // Strip emojis for the inline progress hint
    return label.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
  }

  static String _shortDate(DateTime d) => '${d.month}/${d.day}';
}

// ── Chip helper ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
