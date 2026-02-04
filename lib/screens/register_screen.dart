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

    // Show welcome dialog
    await _showWelcomeDialog();
    if (!mounted) return;

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

    if (!mounted) return;

    if (result.error != null) {
      setState(() => _socialLoading = false);
      _showMessage(result.error!);
      return;
    }

    if (result.requiresSmsCode && result.verificationId != null) {
      _phoneVerificationId = result.verificationId;
      setState(() => _socialLoading = false);

      // Wait for the widget tree to settle before showing the dialog
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final code = await _promptForSmsCode(phone);
      if (code == null || !mounted) return;

      setState(() => _socialLoading = true);
      final error = await provider.confirmPhoneCode(
        verificationId: _phoneVerificationId!,
        smsCode: code.trim(),
        phoneNumber: phone,
      );

      if (!mounted) return;
      setState(() => _socialLoading = false);
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }
      _showMessage('✓ Phone verified! Welcome to MKE CitySmart.');
      Navigator.pushReplacementNamed(context, '/dashboard');
      return;
    }
    // Auto-verified path (rare on iOS, common on Android with SMS Retriever).
    setState(() => _socialLoading = false);
    _showMessage('✓ Phone auto-verified! Welcome to MKE CitySmart.');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<String?> _promptForSmsCode(String phoneNumber) async {
    String? result;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _SmsCodeDialog(
          phoneNumber: phoneNumber,
          onCodeEntered: (code) {
            result = code;
            Navigator.pop(ctx);
          },
          onCancel: () => Navigator.pop(ctx),
        );
      },
    );
    return result;
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
    String? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return _PhoneNumberDialog(
          onPhoneEntered: (phone) {
            result = _formatPhoneNumber(phone);
            Navigator.pop(ctx);
          },
          onCancel: () => Navigator.pop(ctx),
        );
      },
    );
    if (result == null || result!.isEmpty) return null;
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
    _showMessage('✓ Signed in with Apple! Welcome to MKE CitySmart.');
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showWelcomeDialog() async {
    final email = _registerEmailController.text.trim();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 28)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Welcome to the Team!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thanks for joining MKE CitySmart!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Text(
                "Together, we're building a community that helps Milwaukee drivers avoid tickets and stay informed.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('🚗', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('One sighting at a time.'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('📋', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('One report at a time.'),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('🤝', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('Protecting each other.'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Check $email to verify your account.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Let's Go!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
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
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value != null && value.isNotEmpty
                        ? null
                        : 'Introduce yourself with a name',
                  ),
                  TextFormField(
                    controller: _registerEmailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@')
                        ? null
                        : 'Enter a valid email',
                  ),
                  TextFormField(
                    controller: _registerPasswordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => value != null && value.length >= 6
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
            onPressed: _registering || _socialLoading ? null : _handleGoogle,
            icon: const Icon(Icons.login),
            label: const Text('Google'),
          ),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS))
            OutlinedButton.icon(
              onPressed: _registering || _socialLoading ? null : _handleApple,
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

/// A stateful dialog widget that manages its own TextEditingController
/// to avoid disposal issues when the parent widget rebuilds.
class _SmsCodeDialog extends StatefulWidget {
  const _SmsCodeDialog({
    required this.phoneNumber,
    required this.onCodeEntered,
    required this.onCancel,
  });

  final String phoneNumber;
  final void Function(String code) onCodeEntered;
  final VoidCallback onCancel;

  @override
  State<_SmsCodeDialog> createState() => _SmsCodeDialogState();
}

class _SmsCodeDialogState extends State<_SmsCodeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter verification code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We sent a 6-digit code to ${widget.phoneNumber}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (value) {
              if (value.length == 6) {
                widget.onCodeEntered(value);
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Didn\'t receive the code? Check your spam folder or try again in a few minutes.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().length == 6) {
              widget.onCodeEntered(_controller.text.trim());
            }
          },
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

/// A stateful dialog widget for phone number input that manages its own controller.
class _PhoneNumberDialog extends StatefulWidget {
  const _PhoneNumberDialog({
    required this.onPhoneEntered,
    required this.onCancel,
  });

  final void Function(String phone) onPhoneEntered;
  final VoidCallback onCancel;

  @override
  State<_PhoneNumberDialog> createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<_PhoneNumberDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify phone'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '(414) 555-1234',
              labelText: 'Phone number',
              prefixText: '+1 ',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            'US numbers only. We\'ll send a verification code.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final phone = _controller.text.trim();
            if (phone.isNotEmpty) {
              widget.onPhoneEntered(phone);
            }
          },
          child: const Text('Send Code'),
        ),
      ],
    );
  }
}
