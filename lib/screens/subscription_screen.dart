import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ad_preferences.dart';
import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';

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
    return Card(
      color: selected ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.label, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('\$${plan.monthlyPrice.toStringAsFixed(2)}/mo'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.place, size: 16),
                  label: Text('${plan.maxAlertRadiusMiles.toStringAsFixed(0)} mi radius'),
                ),
                Chip(
                  avatar: const Icon(Icons.notifications, size: 16),
                  label: Text('${plan.alertVolumePerDay} alerts/day'),
                ),
                Chip(
                  avatar: const Icon(Icons.money_off, size: 16),
                  label: Text('${(plan.feeWaiverPct * 100).toStringAsFixed(0)}% fee waiver'),
                ),
                if (plan.prioritySupport)
                  const Chip(
                    avatar: Icon(Icons.support_agent, size: 16),
                    label: Text('Priority support'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: selected ? null : onSelect,
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
    feeWaiverPct: 0,
    prioritySupport: false,
    monthlyPrice: 0,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.plus,
    maxAlertRadiusMiles: 8,
    alertVolumePerDay: 10,
    feeWaiverPct: 0.15,
    prioritySupport: false,
    monthlyPrice: 3.99,
  ),
  SubscriptionPlan(
    tier: SubscriptionTier.pro,
    maxAlertRadiusMiles: 15,
    alertVolumePerDay: 25,
    feeWaiverPct: 0.35,
    prioritySupport: true,
    monthlyPrice: 4.99,
  ),
];
