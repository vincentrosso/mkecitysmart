import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/citysmart_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  String? _phoneVerificationId;

  bool _registering = false;
  bool _socialLoading = false;

  @override
  void dispose() {
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _registering = true);
    final provider = context.read<UserProvider>();
    final error = await provider.register(
      name: _registerNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text.trim(),
    );
    setState(() => _registering = false);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Account created! You are now signed in.');
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
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _handlePhoneSignUp() async {
    if (kIsWeb) {
      _showMessage('Phone sign-in is not available on web.');
      return;
    }
    final phone = await _promptForPhoneNumber();
    if (phone == null || !mounted) return;
    setState(() => _socialLoading = true);
    final provider = context.read<UserProvider>();
    final result = await provider.startPhoneSignIn(phone);
    setState(() => _socialLoading = false);
    if (!mounted) return;
    if (result.error != null) {
      _showMessage(result.error!);
      return;
    }
    if (result.requiresSmsCode && result.verificationId != null) {
      _phoneVerificationId = result.verificationId;
      final code = await _promptForValue(
        title: 'Enter code',
        hint: '6-digit SMS code',
        keyboardType: TextInputType.number,
      );
      if (code == null || !mounted) return;
      setState(() => _socialLoading = true);
      final error = await provider.confirmPhoneCode(
        verificationId: _phoneVerificationId!,
        smsCode: code.trim(),
        phoneNumber: phone,
      );
      setState(() => _socialLoading = false);
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }
      _showMessage('Phone verified and account created.');
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }
    // Auto-verified path.
    _showMessage('Phone verified and account created.');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  /// Format phone number to E.164 format for Firebase
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If already has country code (11 digits starting with 1 for US)
    if (digits.length == 11 && digits.startsWith('1')) {
      return '+$digits';
    }
    // US number without country code (10 digits)
    if (digits.length == 10) {
      return '+1$digits';
    }
    // Already formatted or international
    if (phone.startsWith('+')) {
      return phone;
    }
    // Default: assume US and add +1
    return '+1$digits';
  }

  Future<String?> _promptForPhoneNumber() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Verify phone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '(414) 555-1234',
                  labelText: 'Phone number',
                  prefixText: '+1 ',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'US numbers only. We\'ll send a verification code.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final formatted = _formatPhoneNumber(controller.text.trim());
                Navigator.pop(ctx, formatted);
              },
              child: const Text('Send Code'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
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
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _promptForValue({
    required String title,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return CitySmartScaffold(
      title: 'Create Account',
      body: _AuthForm(
        formKey: _registerFormKey,
        isSubmitting: _registering,
        submitLabel: 'Create with email',
        onSubmit: _handleRegister,
        children: [
          Text(
            'Create your MKE CitySmart account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use email, phone, or a social account to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Email & password',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _registerNameController,
                    decoration:
                        const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value != null && value.isNotEmpty
                            ? null
                            : 'Introduce yourself with a name',
                  ),
                  TextFormField(
                    controller: _registerEmailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value != null && value.contains('@')
                            ? null
                            : 'Enter a valid email',
                  ),
                  TextFormField(
                    controller: _registerPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value != null && value.length >= 6
                            ? null
                            : 'Password must be 6+ characters',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.phone_iphone),
              title: const Text('Verify with phone'),
              subtitle: const Text('Get a text code to create your account'),
              trailing: SizedBox(
                width: 116,
                child: ElevatedButton(
                  onPressed: _socialLoading ? null : _handlePhoneSignUp,
                  child: _socialLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send code'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Or continue with',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _registering || _socialLoading
                ? null
                : _handleGoogle,
            icon: const Icon(Icons.login),
            label: const Text('Google'),
          ),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS))
            OutlinedButton.icon(
              onPressed:
                  _registering || _socialLoading ? null : _handleApple,
              icon: const Icon(Icons.apple),
              label: const Text('Sign in with Apple'),
            ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ...children,
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
