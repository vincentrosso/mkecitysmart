import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/referral_service.dart';
import '../theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _codeController = TextEditingController();
  bool _loading = true;
  bool _applying = false;
  String? _referralCode;
  ReferralStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final referralService = ReferralService.instance;
      _referralCode = await referralService.getReferralCode();
      _stats = await referralService.getStats();
    } catch (e) {
      debugPrint('Failed to load referral data: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a referral code')),
      );
      return;
    }

    setState(() => _applying = true);

    final result = await ReferralService.instance.applyReferralCode(code);

    if (!mounted) return;
    setState(() => _applying = false);

    if (result.success) {
      _codeController.clear();
      _loadData(); // Refresh stats
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Referral code applied!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to apply code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyCode() {
    if (_referralCode == null) return;

    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    final message = ReferralService.instance.getShareMessage();
    Share.share(message, subject: 'Join me on MKE CitySmart!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero section
                  _HeroSection(
                    referralCode: _referralCode ?? 'LOADING',
                    onCopy: _copyCode,
                    onShare: _shareCode,
                  ),

                  const SizedBox(height: 24),

                  // Stats section
                  if (_stats != null) _StatsSection(stats: _stats!),

                  const SizedBox(height: 24),

                  // How it works
                  _HowItWorksSection(),

                  const SizedBox(height: 24),

                  // Apply code section
                  _ApplyCodeSection(
                    controller: _codeController,
                    applying: _applying,
                    onApply: _applyCode,
                  ),

                  // Active reward badge
                  if (_stats?.hasActiveReward == true) ...[
                    const SizedBox(height: 24),
                    _ActiveRewardBadge(
                      expiresAt: _stats!.premiumTrialEnd!,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.referralCode,
    required this.onCopy,
    required this.onShare,
  });

  final String referralCode;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kCitySmartYellow.withValues(alpha: 0.2),
            kCitySmartGreen.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kCitySmartYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.card_giftcard,
            size: 56,
            color: kCitySmartYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'Give 7 Days, Get 7 Days',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kCitySmartYellow,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Share your code with friends. When they sign up, you both get 7 days of Premium access!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kCitySmartText.withValues(alpha: 0.8),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Referral code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: kCitySmartGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: kCitySmartYellow.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  referralCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: kCitySmartYellow,
                      ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, color: kCitySmartYellow),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            label: const Text('Share with Friends'),
            style: FilledButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: kCitySmartYellow),
                const SizedBox(width: 8),
                Text(
                  'Your Referral Stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Friends Invited',
                    value: stats.totalReferrals.toString(),
                    icon: Icons.people_outline,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Successful',
                    value: stats.successfulReferrals.toString(),
                    icon: Icons.check_circle_outline,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Rewards Left',
                    value: stats.remainingRewards.toString(),
                    icon: Icons.card_giftcard,
                  ),
                ),
              ],
            ),
            if (stats.remainingRewards == 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCitySmartYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: kCitySmartYellow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ve maxed out your referral rewards! Thanks for spreading the word!',
                        style: TextStyle(
                          color: kCitySmartText.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: kCitySmartMuted, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kCitySmartMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: kCitySmartYellow),
                const SizedBox(width: 8),
                Text(
                  'How It Works',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _HowItWorksStep(
              number: '1',
              title: 'Share Your Code',
              description:
                  'Send your unique code to friends via text, email, or social media.',
            ),
            _HowItWorksStep(
              number: '2',
              title: 'Friend Signs Up',
              description:
                  'Your friend downloads the app and enters your code during signup.',
            ),
            _HowItWorksStep(
              number: '3',
              title: 'Both Get Premium',
              description:
                  'You both receive 7 days of Premium access instantly!',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  final String number;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: kCitySmartYellow,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: kCitySmartGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: kCitySmartText.withValues(alpha: 0.7),
                    fontSize: 13,
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

class _ApplyCodeSection extends StatelessWidget {
  const _ApplyCodeSection({
    required this.controller,
    required this.applying,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.input, color: kCitySmartYellow),
                const SizedBox(width: 8),
                Text(
                  'Have a Referral Code?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a friend\'s code to claim your free Premium trial.',
              style: TextStyle(
                color: kCitySmartText.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: applying ? null : onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: kCitySmartYellow,
                    foregroundColor: kCitySmartGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: applying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kCitySmartGreen,
                          ),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRewardBadge extends StatelessWidget {
  const _ActiveRewardBadge({required this.expiresAt});

  final DateTime expiresAt;

  @override
  Widget build(BuildContext context) {
    final remaining = expiresAt.difference(DateTime.now());
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;

    String timeText;
    if (days > 0) {
      timeText = '$days day${days > 1 ? 's' : ''} remaining';
    } else if (hours > 0) {
      timeText = '$hours hour${hours > 1 ? 's' : ''} remaining';
    } else {
      timeText = 'Expiring soon';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium Trial Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: TextStyle(
                    color: kCitySmartText.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
