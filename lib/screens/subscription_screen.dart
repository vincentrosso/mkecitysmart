import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final adPrefs = provider.adPreferences;
        final tier = provider.tier;
        final plans = _plans;
        return Scaffold(
          appBar: AppBar(title: const Text('Ads & subscriptions')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Choose your plan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...plans.map(
                (plan) => _PlanCard(
                  plan: plan,
                  selected: tier == plan.tier,
                  onSelect: () => provider.updateSubscriptionTier(plan.tier),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Ad categories', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Parking & mobility'),
                        value: adPrefs.showParkingAds,
                        onChanged: (value) =>
                            provider.updateAdPreferences(adPrefs.copyWith(showParkingAds: value)),
                      ),
                      SwitchListTile(
                        title: const Text('Insurance'),
                        value: adPrefs.showInsuranceAds,
                        onChanged: (value) =>
                            provider.updateAdPreferences(adPrefs.copyWith(showInsuranceAds: value)),
                      ),
                      SwitchListTile(
                        title: const Text('Maintenance & service'),
                        value: adPrefs.showMaintenanceAds,
                        onChanged: (value) =>
                            provider.updateAdPreferences(adPrefs.copyWith(showMaintenanceAds: value)),
                      ),
                      SwitchListTile(
                        title: const Text('Local deals'),
                        value: adPrefs.showLocalDeals,
                        onChanged: (value) =>
                            provider.updateAdPreferences(adPrefs.copyWith(showLocalDeals: value)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final borderColor = selected ? kCitySmartYellow : const Color(0xFF1F3A34);
    final chipBg = kCitySmartGreen.withValues(alpha: 0.4);
    final chipText = kCitySmartText;
    return Card(
      color: kCitySmartCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  plan.monthlyPrice == 0
                      ? 'Free'
                      : '\$${plan.monthlyPrice.toStringAsFixed(2)}/mo',
                  style: const TextStyle(
                    color: kCitySmartText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  backgroundColor: chipBg,
                  avatar: const Icon(Icons.place, size: 16, color: kCitySmartYellow),
                  label: Text(
                    '${plan.maxAlertRadiusMiles.toStringAsFixed(0)} mi radius',
                    style: TextStyle(color: chipText),
                  ),
                ),
                Chip(
                  backgroundColor: chipBg,
                  avatar: const Icon(Icons.notifications, size: 16, color: kCitySmartYellow),
                  label: Text(
                    '${plan.alertVolumePerDay} alerts/day',
                    style: TextStyle(color: chipText),
                  ),
                ),
                if (plan.zeroProcessingFee)
                  Chip(
                    backgroundColor: chipBg,
                    avatar:
                        const Icon(Icons.money_off, size: 16, color: kCitySmartYellow),
                    label: Text(
                      'Zero processing fees',
                      style: TextStyle(color: chipText),
                    ),
                  ),
                if (plan.prioritySupport)
                  Chip(
                    backgroundColor: chipBg,
                    avatar: const Icon(Icons.support_agent, size: 16, color: kCitySmartYellow),
                    label: Text(
                      'Priority support',
                      style: TextStyle(color: chipText),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: selected ? null : onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: kCitySmartYellow,
                foregroundColor: kCitySmartGreen,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(selected ? 'Current plan' : 'Select ${plan.label}'),
            ),
          ],
        ),
      ),
    );
  }
}

const _plans = [
  SubscriptionPlan(
    tier: SubscriptionTier.free,
    maxAlertRadiusMiles: 3,
    alertVolumePerDay: 3,
    zeroProcessingFee: false,
    prioritySupport: false,
    monthlyPrice: 0,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.plus,
    maxAlertRadiusMiles: 8,
    alertVolumePerDay: 10,
    zeroProcessingFee: true,
    prioritySupport: false,
    monthlyPrice: 3.99,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.pro,
    maxAlertRadiusMiles: 15,
    alertVolumePerDay: 25,
    zeroProcessingFee: true,
    prioritySupport: true,
    monthlyPrice: 4.99,
  ),
];
