import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/citysmart_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  bool _loggingIn = false;
  bool _socialLoading = false;

  bool get _busy => _loggingIn || _socialLoading;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loggingIn = true);
    final provider = context.read<UserProvider>();
    final error = await provider.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text.trim(),
    );
    setState(() => _loggingIn = false);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('✓ Welcome back to MKE CitySmart!');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _continueAsGuest() async {
    final provider = context.read<UserProvider>();
    await provider.continueAsGuest();
    if (!mounted) return;
    _showMessage('Exploring in guest mode. Sign in anytime to save your data!');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _socialLoading = true;
    });
    final provider = context.read<UserProvider>();
    final error = await provider.signInWithGoogle();
    setState(() {
      _socialLoading = false;
    });
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('✓ Signed in with Google! Welcome to MKE CitySmart.');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _handleApple() async {
    setState(() {
      _socialLoading = true;
    });
    final provider = context.read<UserProvider>();
    final error = await provider.signInWithApple();
    setState(() {
      _socialLoading = false;
    });
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('✓ Signed in with Apple! Welcome to MKE CitySmart.');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return CitySmartScaffold(
      title: 'Account Access',
      body: SafeArea(
        child: Form(
          key: _loginFormKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              OutlinedButton.icon(
                onPressed: _loggingIn || _socialLoading ? null : _handleGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 8),
              if (!kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.macOS))
                OutlinedButton.icon(
                  onPressed:
                      _loggingIn || _socialLoading ? null : _handleApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextFormField(
                controller: _loginEmailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : 'Enter a valid email',
              ),
              TextFormField(
                controller: _loginPasswordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Password must be 6+ characters',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _handleLogin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _loggingIn
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _continueAsGuest,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Continue as guest'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/register');
                      },
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/auth-diagnostics',
                ),
                icon: const Icon(Icons.info_outline),
                label: const Text('Auth diagnostics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}