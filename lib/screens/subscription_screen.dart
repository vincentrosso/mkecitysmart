import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paywall_widget.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final adPrefs = provider.adPreferences;
        final currentTier = provider.tier;
        final currentPlan = SubscriptionService.getPlanForTier(currentTier);

        return Scaffold(
          appBar: AppBar(title: const Text('Subscription & Ads')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current plan status
              _CurrentPlanCard(plan: currentPlan),

              const SizedBox(height: 24),

              // Plan comparison
              Text(
                'Available Plans',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              ..._plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    selected: currentTier == plan.tier,
                    onSelect: () => _handlePlanSelect(context, plan),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Restore purchases button
              OutlinedButton.icon(
                onPressed: _restoring ? null : _handleRestore,
                icon: _restoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: const Text('Restore Purchases'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 24),

              // Ad preferences (only for non-premium users)
              if (!currentPlan.adFree) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.ads_click,
                              color: kCitySmartYellow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ad Preferences',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose which types of ads you see',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: kCitySmartText.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Parking & mobility'),
                          subtitle: const Text('Parking apps, ride services'),
                          value: adPrefs.showParkingAds,
                          onChanged: (value) => provider.updateAdPreferences(
                            adPrefs.copyWith(showParkingAds: value),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Insurance'),
                          subtitle: const Text('Auto insurance offers'),
                          value: adPrefs.showInsuranceAds,
                          onChanged: (value) => provider.updateAdPreferences(
                            adPrefs.copyWith(showInsuranceAds: value),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Maintenance & service'),
                          subtitle: const Text('Auto shops, car washes'),
                          value: adPrefs.showMaintenanceAds,
                          onChanged: (value) => provider.updateAdPreferences(
                            adPrefs.copyWith(showMaintenanceAds: value),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Local deals'),
                          subtitle: const Text('Milwaukee area businesses'),
                          value: adPrefs.showLocalDeals,
                          onChanged: (value) => provider.updateAdPreferences(
                            adPrefs.copyWith(showLocalDeals: value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Upgrade prompt
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kCitySmartYellow.withValues(alpha: 0.15),
                        kCitySmartGreen.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kCitySmartYellow.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: kCitySmartYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Want an ad-free experience?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Upgrade to Plus or Pro',
                              style: TextStyle(
                                color: kCitySmartText.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => PaywallScreen.show(
                          context,
                          feature: PremiumFeature.adFree,
                        ),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Premium user - show ad-free badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ad-Free Experience',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'You\'re enjoying an ad-free experience with your premium subscription.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Manage Subscription button
                OutlinedButton.icon(
                  onPressed: _handleManageSubscription,
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Subscription'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Feature list
              _FeatureComparisonSection(),
            ],
          ),
        );
      },
    );
  }

  void _handlePlanSelect(BuildContext context, SubscriptionPlan plan) async {
    if (plan.tier == SubscriptionTier.free) {
      // Can't downgrade via this UI - would need to cancel in App Store/Play Store
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'To downgrade, cancel your subscription in App Store or Google Play settings.',
          ),
        ),
      );
      return;
    }

    // Show RevenueCat's native paywall for upgrade
    final purchased = await SubscriptionService.instance.presentPaywall();

    if (!mounted) return;

    if (purchased) {
      // Update the user provider with new subscription tier
      context.read<UserProvider>().updateSubscriptionTier(
        SubscriptionService.instance.currentTier,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to Premium!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Open RevenueCat Customer Center for subscription management
  Future<void> _handleManageSubscription() async {
    await SubscriptionService.instance.presentCustomerCenter();

    if (!mounted) return;

    // Refresh subscription status after returning from customer center
    context.read<UserProvider>().updateSubscriptionTier(
      SubscriptionService.instance.currentTier,
    );
  }

  Future<void> _handleRestore() async {
    setState(() => _restoring = true);

    final result = await SubscriptionService.instance.restorePurchases();

    if (!mounted) return;
    setState(() => _restoring = false);

    if (result.success && SubscriptionService.instance.isPremium) {
      final provider = context.read<UserProvider>();
      provider.updateSubscriptionTier(SubscriptionService.instance.currentTier);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? result.error ?? 'No purchases found'),
        ),
      );
    }
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.tier != SubscriptionTier.free;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  kCitySmartYellow.withValues(alpha: 0.3),
                  kCitySmartGreen.withValues(alpha: 0.3),
                ]
              : [kCitySmartCard, kCitySmartCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? kCitySmartYellow.withValues(alpha: 0.5)
              : kCitySmartText.withValues(alpha: 0.2),
          width: isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.person_outline,
                color: isPremium ? kCitySmartYellow : kCitySmartText,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Plan',
                    style: TextStyle(
                      color: kCitySmartText.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    plan.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPremium ? kCitySmartYellow : kCitySmartText,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kCitySmartYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: kCitySmartGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PlanChip(
                icon: Icons.place,
                label:
                    '${plan.maxAlertRadiusMiles.toStringAsFixed(0)} mi radius',
              ),
              _PlanChip(
                icon: Icons.notifications,
                label: plan.alertVolumePerDay < 0
                    ? 'Unlimited alerts'
                    : '${plan.alertVolumePerDay} alerts/day',
              ),
              _PlanChip(
                icon: Icons.history,
                label: '${plan.historyDays} days history',
              ),
              if (plan.adFree)
                const _PlanChip(
                  icon: Icons.block,
                  label: 'Ad-free',
                  highlight: true,
                ),
              if (plan.heatmapAccess)
                const _PlanChip(
                  icon: Icons.map,
                  label: 'Heatmaps',
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? kCitySmartYellow.withValues(alpha: 0.2)
            : kCitySmartGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: highlight
            ? Border.all(color: kCitySmartYellow.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight ? kCitySmartYellow : kCitySmartText,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: highlight ? kCitySmartYellow : kCitySmartText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isPro = plan.tier == SubscriptionTier.pro;
    final borderColor = selected
        ? kCitySmartYellow
        : isPro
        ? kCitySmartYellow.withValues(alpha: 0.5)
        : kCitySmartText.withValues(alpha: 0.2);

    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Stack(
        children: [
          if (isPro && !selected)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: kCitySmartYellow,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: kCitySmartGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      plan.tier == SubscriptionTier.free
                          ? Icons.person_outline
                          : Icons.workspace_premium,
                      color: selected ? kCitySmartYellow : kCitySmartText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: selected ? kCitySmartYellow : kCitySmartText,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.monthlyPrice == 0
                              ? 'Free'
                              : '\$${plan.monthlyPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: selected ? kCitySmartYellow : kCitySmartText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (plan.monthlyPrice > 0)
                          Text(
                            '/month',
                            style: TextStyle(
                              color: kCitySmartText.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (plan.yearlyPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'or \$${plan.yearlyPrice!.toStringAsFixed(2)}/year (save 40%)',
                    style: TextStyle(
                      color: Colors.green.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Feature list
                ...plan.features
                    .take(5)
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: selected ? kCitySmartYellow : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kCitySmartText.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: selected ? null : onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: selected
                        ? kCitySmartText.withValues(alpha: 0.3)
                        : kCitySmartYellow,
                    foregroundColor: selected
                        ? kCitySmartText
                        : kCitySmartGreen,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selected
                        ? 'Current Plan'
                        : plan.tier == SubscriptionTier.free
                        ? 'Downgrade'
                        : 'Upgrade to ${plan.label}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureComparisonSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feature Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _FeatureRow(
              feature: 'Alert radius',
              free: '3 miles',
              plus: '8 miles',
              pro: '15 miles',
            ),
            _FeatureRow(
              feature: 'Daily alerts',
              free: '3',
              plus: '15',
              pro: 'Unlimited',
            ),
            _FeatureRow(
              feature: 'History',
              free: '7 days',
              plus: '30 days',
              pro: '1 year',
            ),
            _FeatureRow(
              feature: 'Citation heatmaps',
              free: '–',
              plus: '✓',
              pro: '✓',
              plusHighlight: true,
              proHighlight: true,
            ),
            _FeatureRow(
              feature: 'Smart alerts',
              free: '–',
              plus: '✓',
              pro: '✓',
              plusHighlight: true,
              proHighlight: true,
            ),
            _FeatureRow(
              feature: 'Ad-free',
              free: '–',
              plus: '✓',
              pro: '✓',
              plusHighlight: true,
              proHighlight: true,
            ),
            _FeatureRow(
              feature: 'Priority support',
              free: '–',
              plus: '–',
              pro: '✓',
              proHighlight: true,
            ),
            _FeatureRow(
              feature: 'Processing fees',
              free: 'Standard',
              plus: 'Zero',
              pro: 'Zero',
              plusHighlight: true,
              proHighlight: true,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.free,
    required this.plus,
    required this.pro,
    this.plusHighlight = false,
    this.proHighlight = false,
    this.isLast = false,
  });

  final String feature;
  final String free;
  final String plus;
  final String pro;
  final bool plusHighlight;
  final bool proHighlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: kCitySmartText.withValues(alpha: 0.1),
                ),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              free,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: kCitySmartText.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              plus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: plusHighlight ? Colors.green : kCitySmartText,
                fontWeight: plusHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: proHighlight ? kCitySmartYellow : kCitySmartText,
                fontWeight: proHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Use the centralized plans from SubscriptionService
final _plans = [
  SubscriptionService.getPlanForTier(SubscriptionTier.free),
  SubscriptionService.getPlanForTier(SubscriptionTier.pro),
];
