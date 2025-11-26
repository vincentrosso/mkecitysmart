import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../citysmart/theme.dart';
import '../providers/user_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5E8A45),
              Color(0xFF7CA726),
            ],
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Consumer<UserProvider>(
                builder: (context, provider, _) {
                  final isLoading = provider.isInitializing;
                  final isLoggedIn = provider.isLoggedIn;
                  final profile = provider.profile;
                  return Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 16,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          size: 64,
                          color: CSTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.shield_outlined,
                                          size: 18, color: CSTheme.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        'CitySmart',
                                        style: TextStyle(
                                          color: CSTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLoggedIn && profile != null)
                                  const Icon(Icons.verified_user,
                                      color: CSTheme.secondary),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Welcome to MKEPark',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: CSTheme.text,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Monitor parking rules, permits, vehicles, alerts, and city services with one calm, modern dashboard.',
                              style: TextStyle(
                                color:
                                    CSTheme.text.withOpacity(0.7),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            if (isLoggedIn && profile != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Signed in as ${profile.name}',
                                style: const TextStyle(
                                  color: CSTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                            width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.dashboard_customize),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final route =
                                            isLoggedIn ? '/landing' : '/auth';
                                        Navigator.pushReplacementNamed(
                                            context, route);
                                      },
                                label: Text(
                                  isLoggedIn
                                      ? 'Go to dashboard'
                                      : 'Get Started',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                              if (!isLoggedIn) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.person_add_alt),
                                  onPressed: isLoading
                                      ? null
                                      : () =>
                                          Navigator.pushNamed(context, '/auth'),
                                  label: const Text('Create an account'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(
                                      color: CSTheme.border,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        provider.continueAsGuest();
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/landing',
                                        );
                                      },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Continue as guest'),
                                style: TextButton.styleFrom(
                                  foregroundColor: CSTheme.text,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 12),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Preview the dashboard without an account. You can sign in anytime.',
                                style: TextStyle(
                                  color: CSTheme.textMuted,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ] else
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/profile'),
                                child: const Text('Manage profile'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
