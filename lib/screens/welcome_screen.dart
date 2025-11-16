import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Initialize location and user providers
    final locationProvider = context.read<LocationProvider>();
    final userProvider = context.read<UserProvider>();

    await Future.wait([
      locationProvider.initializeLocation(),
      userProvider.initializeUser(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_parking,
                size: 100,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to CitySmart Parking App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Monitor parking regulations in your area',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Consumer2<LocationProvider, UserProvider>(
                builder: (context, locationProvider, userProvider, child) {
                  final isLoading =
                      locationProvider.isLoading || userProvider.isLoading;

                  return Column(
                    children: [
                      if (isLoading)
                        const CircularProgressIndicator(
                          color: Color(0xFFFFC107),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            context.go('/landing');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (locationProvider.errorMessage != null)
                        Text(
                          'Location: ${locationProvider.errorMessage}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      if (userProvider.errorMessage != null)
                        Text(
                          'User: ${userProvider.errorMessage}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
