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
      icon: Icons.warning_amber_rounded,
      title: 'Avoid Parking Tickets',
      description:
          'Get real-time risk alerts based on 466,000+ citation records. Know where tickets happen most.',
      color: const Color(0xFFE53935),
    ),
    _OnboardingPage(
      icon: Icons.swap_horiz,
      title: 'Alternate Side Parking',
      description:
          'Never forget which side to park on. Get daily reminders before the rules change at midnight.',
      color: const Color(0xFF4FC3F7),
    ),
    _OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Smart Notifications',
      description:
          'Receive alerts for street sweeping, garbage day, high-risk zones, and more.',
      color: const Color(0xFF66BB6A),
    ),
    _OnboardingPage(
      icon: Icons.person_add,
      title: 'Create Your Account',
      description:
          'Sign up to save your preferences, track tickets, and get personalized alerts.',
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 70, color: page.color),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kCitySmartText,
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: kCitySmartMuted,
              height: 1.5,
            ),
          ),
        ],
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

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isLastPage = false,
  });
}
