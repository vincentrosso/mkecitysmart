import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/subscription_plan.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/citysmart_scaffold.dart';

/// Sponsors & Partners screen - Coming Soon placeholder
/// Real partnerships will be added when agreements are in place
class SponsorsScreen extends StatelessWidget {
  const SponsorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CitySmartScaffold(
      title: 'Deals & Partners',
      currentIndex: -1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCitySmartYellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  size: 64,
                  color: kCitySmartYellow,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Deals & Partners',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kCitySmartText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kCitySmartGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'We\'re working on partnering with local Milwaukee businesses to bring you exclusive deals and discounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: kCitySmartText.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCitySmartCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kCitySmartMuted.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _FeatureItem(
                      icon: Icons.local_offer,
                      text: 'Exclusive discounts for app users',
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.store,
                      text: 'Local Milwaukee businesses',
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.directions_car,
                      text: 'Auto services, parking & more',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // While they wait for deals, offer premium trial via ad
              Consumer<UserProvider>(
                builder: (context, provider, _) {
                  if (provider.tier != SubscriptionTier.free) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      WatchAdButton(
                        rewardDescription: 'Get Premium while you wait',
                        buttonText: 'Watch Ad',
                        rewardText: '3 Days Premium',
                        onReward: () => provider.grantAdRewardTrial(days: 3),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              Text(
                'Are you a business interested in partnering with us?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kCitySmartText.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchPartnerEmail(),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Contact Us'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kCitySmartYellow,
                  side: const BorderSide(color: kCitySmartYellow),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchPartnerEmail() async {
    final uri = Uri.parse(
      'mailto:partners@mkecitysmart.com?subject=Partnership Inquiry',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kCitySmartYellow),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: kCitySmartText.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
