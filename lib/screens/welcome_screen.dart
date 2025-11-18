import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Consumer<UserProvider>(
            builder: (context, provider, _) {
              final isLoading = provider.isInitializing;
              final isLoggedIn = provider.isLoggedIn;
              final profile = provider.profile;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_parking,
                    size: 100,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome to MKEPark',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Monitor parking regulations, permits, vehicles & alerts',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (isLoggedIn && profile != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Signed in as ${profile.name}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final route = isLoggedIn ? '/landing' : '/auth';
                            Navigator.pushReplacementNamed(context, route);
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
                    child: Text(
                      isLoggedIn ? 'Go to dashboard' : 'Get Started',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isLoggedIn)
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushNamed(context, '/auth'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Create an account'),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      child: const Text('Manage profile'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
