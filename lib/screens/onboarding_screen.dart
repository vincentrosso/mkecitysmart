import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Service to manage onboarding state
class OnboardingService {
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _onboardingVersionKey = 'onboarding_version';
  static const int _currentVersion = 1;

  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static OnboardingService get instance => _instance;

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final complete = prefs.getBool(_onboardingCompleteKey) ?? false;
    final version = prefs.getInt(_onboardingVersionKey) ?? 0;
    // Show onboarding if not complete or if we have a newer version
    return complete && version >= _currentVersion;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    await prefs.setInt(_onboardingVersionKey, _currentVersion);
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, false);
  }
}

/// Onboarding screen with multiple pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.location_city,
      title: 'Welcome to MKE CitySmart',
      description:
          'Your smart companion for navigating Milwaukee parking, city services, and avoiding tickets.',
      color: kCitySmartYellow,
    ),
    _OnboardingPage(
      icon: Icons.map_outlined,
      title: 'Your Dashboard',
      description:
          'The home screen gives you everything at a glance — parking risk level, '
          'alt-side status, garbage day, and quick access to all features.',
      color: const Color(0xFF4FC3F7),
      tips: [
        'Tap any tile to jump to that feature',
        'Your risk badge updates based on your location',
        'Scroll down to see all 16+ features',
      ],
    ),
    _OnboardingPage(
      icon: Icons.warning_amber_rounded,
      title: 'Parking Risk Heatmap',
      description:
          'See citation hotspots across Milwaukee built from 466,000+ real ticket records. '
          'Tap any zone to see the risk level and most common violations.',
      color: const Color(0xFFE53935),
      tips: [
        'Red zones = highest ticket risk',
        'Tap "Navigate to Safe Spot" for directions',
        'Uses Google Maps on Android, Apple Maps on iOS',
      ],
    ),
    _OnboardingPage(
      icon: Icons.swap_horiz,
      title: 'Alternate Side Parking',
      description:
          'Milwaukee requires parking on the odd-numbered side on odd days, '
          'and the even side on even days. The switch happens at midnight.',
      color: const Color(0xFF4FC3F7),
      tips: [
        'Today\'s side is shown right on your dashboard',
        'Enable morning & evening reminders',
        'Check street signs — some areas have exceptions',
      ],
    ),
    _OnboardingPage(
      icon: Icons.receipt_long,
      title: 'Ticket Tracking',
      description:
          'Search for tickets by license plate, track payment status, '
          'and view your complete citation history in one place.',
      color: const Color(0xFFFF9800),
      tips: [
        'Add your vehicles for automatic ticket lookups',
        'Get notified when a new ticket is written',
        'View ticket details, photos, and due dates',
      ],
    ),
    _OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Smart Notifications',
      description:
          'Set up custom alerts for street sweeping, garbage day, '
          'high-risk zones, and alternate-side parking changes.',
      color: const Color(0xFF66BB6A),
      tips: [
        'Morning reminders before the parking side changes',
        'Street sweeping alerts save you from tickets',
        'Customize timing in Preferences',
      ],
    ),
    _OnboardingPage(
      icon: Icons.star_rounded,
      title: 'Pro Tips',
      description: 'A few quick tips to get the most out of CitySmart.',
      color: kCitySmartYellow,
      tips: [
        'Save frequent spots with "Saved Places"',
        'Report parking availability for others nearby',
        'Invite friends to earn free Premium access',
        'Check "EV Chargers" for charging station locations',
      ],
    ),
    _OnboardingPage(
      icon: Icons.person_add,
      title: 'Ready to Go!',
      description:
          'Create an account to save preferences, track tickets, and get '
          'personalized alerts — or explore as a guest first.',
      color: kCitySmartYellow,
      isLastPage: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding({bool createAccount = false}) async {
    await OnboardingService.instance.setOnboardingComplete();
    if (!mounted) return;

    // If we can pop (e.g. came from "Take a Tour"), just go back
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    if (createAccount) {
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCitySmartGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _currentPage < _pages.length - 1
                    ? TextButton(
                        onPressed: _skipToEnd,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: kCitySmartMuted,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : const SizedBox(height: 48),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDot(index),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _currentPage == _pages.length - 1
                  ? _buildFinalButtons()
                  : _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 60, color: page.color),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: kCitySmartText,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: kCitySmartMuted,
                height: 1.5,
              ),
            ),

            // Tips section (if present)
            if (page.tips != null && page.tips!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: page.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: page.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: page.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: page.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...page.tips!.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: page.color.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kCitySmartText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? kCitySmartYellow
            : kCitySmartMuted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: kCitySmartYellow,
          foregroundColor: kCitySmartGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      children: [
        // Create Account button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _completeOnboarding(createAccount: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kCitySmartYellow,
              foregroundColor: kCitySmartGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Continue as Guest button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _completeOnboarding(createAccount: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: kCitySmartYellow,
              side: const BorderSide(color: kCitySmartYellow, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue as Guest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sign in link
        TextButton(
          onPressed: () async {
            await OnboardingService.instance.setOnboardingComplete();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/auth');
          },
          child: const Text(
            'Already have an account? Sign in',
            style: TextStyle(color: kCitySmartMuted, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLastPage;
  final List<String>? tips;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isLastPage = false,
    this.tips,
  });
}
