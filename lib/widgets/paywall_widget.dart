import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

/// A paywall widget that prompts users to upgrade when accessing premium features
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    required this.feature,
    this.onDismiss,
  });

  /// The feature that triggered the paywall
  final PremiumFeature feature;

  /// Callback when user dismisses without purchasing
  final VoidCallback? onDismiss;

  /// Show paywall as a modal bottom sheet
  static Future<bool> show(
    BuildContext context, {
    required PremiumFeature feature,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallScreen(feature: feature),
    );
    return result ?? false;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = false;
  bool _yearly = false;
  Package? _selectedPackage;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = SubscriptionService.instance;
    final offerings = subscriptionService.offerings;
    final currentOffering = offerings?.current;

    return Container(
      decoration: const BoxDecoration(
        color: kCitySmartGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: kCitySmartText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Feature highlight
                _FeatureHighlight(feature: widget.feature),

                const SizedBox(height: 24),

                // Plan comparison
                Text(
                  'Unlock Premium Features',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Choose the plan that works for you',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kCitySmartText.withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Billing toggle
                _BillingToggle(
                  isYearly: _yearly,
                  onChanged: (value) => setState(() => _yearly = value),
                ),

                const SizedBox(height: 16),

                // Plan cards
                if (currentOffering != null) ...[
                  _buildOfferingCards(currentOffering),
                ] else ...[
                  _buildFallbackPlanCards(),
                ],

                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 16),

                // Purchase button
                FilledButton(
                  onPressed: _loading ? null : _handlePurchase,
                  style: FilledButton.styleFrom(
                    backgroundColor: kCitySmartYellow,
                    foregroundColor: kCitySmartGreen,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kCitySmartGreen,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 12),

                // Restore purchases
                TextButton(
                  onPressed: _loading ? null : _handleRestore,
                  child: const Text('Restore Purchases'),
                ),

                // Terms
                const SizedBox(height: 8),
                Text(
                  'Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kCitySmartText.withValues(alpha: 0.5),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to privacy policy
                      },
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: kCitySmartText.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: kCitySmartText.withValues(alpha: 0.5),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to terms of service
                      },
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: kCitySmartText.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferingCards(Offering offering) {
    final packages = offering.availablePackages;
    final monthlyPackages =
        packages.where((p) => p.packageType == PackageType.monthly).toList();
    final yearlyPackages =
        packages.where((p) => p.packageType == PackageType.annual).toList();

    final displayPackages = _yearly ? yearlyPackages : monthlyPackages;

    if (displayPackages.isEmpty) {
      return _buildFallbackPlanCards();
    }

    return Column(
      children: displayPackages.map((package) {
        final isSelected = _selectedPackage == package;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PackageCard(
            package: package,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedPackage = package),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFallbackPlanCards() {
    // Show static plan cards when RevenueCat isn't configured
    final plans = [
      SubscriptionService.getPlanForTier(SubscriptionTier.plus),
      SubscriptionService.getPlanForTier(SubscriptionTier.pro),
    ];

    return Column(
      children: plans.map((plan) {
        final price = _yearly ? plan.yearlyPrice : plan.monthlyPrice;
        final period = _yearly ? '/year' : '/month';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _StaticPlanCard(
            plan: plan,
            price: price ?? plan.monthlyPrice,
            period: period,
            isRecommended: plan.tier == SubscriptionTier.plus,
            onTap: () {
              setState(() {
                _error =
                    'In-app purchases not configured. Please set up RevenueCat.';
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) {
      setState(() => _error = 'Please select a plan');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await SubscriptionService.instance.purchase(_selectedPackage!);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.success) {
      // Update user provider with new tier
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider
            .updateSubscriptionTier(SubscriptionService.instance.currentTier);
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await SubscriptionService.instance.restorePurchases();

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.success) {
      final isPremium = SubscriptionService.instance.isPremium;
      if (isPremium && mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider
            .updateSubscriptionTier(SubscriptionService.instance.currentTier);
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = result.message ?? 'No previous purchases found');
      }
    } else {
      setState(() => _error = result.error);
    }
  }
}

class _FeatureHighlight extends StatelessWidget {
  const _FeatureHighlight({required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kCitySmartYellow.withValues(alpha: 0.2),
            kCitySmartGreen.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kCitySmartYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            feature.icon,
            size: 48,
            color: kCitySmartYellow,
          ),
          const SizedBox(height: 12),
          Text(
            feature.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kCitySmartText.withValues(alpha: 0.8),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kCitySmartYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Requires ${feature.minimumTier.name.toUpperCase()} or higher',
              style: TextStyle(
                color: kCitySmartYellow,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.isYearly,
    required this.onChanged,
  });

  final bool isYearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kCitySmartCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isYearly ? kCitySmartGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isYearly ? kCitySmartYellow : kCitySmartText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isYearly ? kCitySmartGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yearly',
                      style: TextStyle(
                        color: isYearly ? kCitySmartYellow : kCitySmartText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Save 40%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCitySmartCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kCitySmartYellow : kCitySmartCard,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kCitySmartYellow : Colors.transparent,
                border: Border.all(
                  color: isSelected ? kCitySmartYellow : kCitySmartText,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: kCitySmartGreen)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: kCitySmartText.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              product.priceString,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: kCitySmartYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticPlanCard extends StatelessWidget {
  const _StaticPlanCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.isRecommended,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final double price;
  final String period;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCitySmartCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? kCitySmartYellow : kCitySmartCard,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                if (isRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kCitySmartYellow,
                      borderRadius: BorderRadius.circular(4),
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
                ],
                const Spacer(),
                Text(
                  '\$${price.toStringAsFixed(2)}$period',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: kCitySmartYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.features.take(4).map((feature) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: kCitySmartText.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
