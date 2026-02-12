import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/citysmart_scaffold.dart';
import '../widgets/data_source_attribution.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProvider>().profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<UserProvider>();
    final rawAddress = _addressController.text.trim();
    String? formattedAddress;
    double? lat;
    double? lng;
    if (rawAddress.isNotEmpty) {
      try {
        final locations = await locationFromAddress(rawAddress);
        if (locations.isEmpty) {
          throw Exception('No results for that address.');
        }
        lat = locations.first.latitude;
        lng = locations.first.longitude;
        final placemarks = await placemarkFromCoordinates(lat, lng);
        formattedAddress = placemarks.isNotEmpty
            ? _formatPlacemark(placemarks.first)
            : rawAddress;
      } catch (e) {
        setState(() => _saving = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not verify address: ${e.toString()}')),
        );
        return;
      }
    }
    await provider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: rawAddress.isEmpty ? null : rawAddress,
      formattedAddress:
          formattedAddress ?? (rawAddress.isEmpty ? null : rawAddress),
      addressLatitude: lat,
      addressLongitude: lng,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  String _formatPlacemark(Placemark placemark) {
    final parts = <String>[
      if ((placemark.street ?? '').trim().isNotEmpty) placemark.street!.trim(),
      if ((placemark.locality ?? '').trim().isNotEmpty)
        placemark.locality!.trim(),
      if ((placemark.administrativeArea ?? '').trim().isNotEmpty)
        placemark.administrativeArea!.trim(),
      if ((placemark.postalCode ?? '').trim().isNotEmpty)
        placemark.postalCode!.trim(),
      if ((placemark.country ?? '').trim().isNotEmpty)
        placemark.country!.trim(),
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = provider.profile;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign in to manage your profile.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/auth'),
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            ),
          );
        }

        return CitySmartScaffold(
          title: 'Profile & Settings',
          currentIndex: 0,
          actions: [
            IconButton(
              onPressed: () async {
                await provider.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
            ),
          ],
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            profile.name.isNotEmpty
                                ? profile.name[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                        title: Text(profile.name),
                        subtitle: Text(profile.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick access to Saved Places
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.place),
                        title: const Text('Saved Places'),
                        subtitle: const Text('Home, work, and favorites'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/saved-places'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Take a Tour
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.explore_outlined),
                        title: const Text('Take a Tour'),
                        subtitle: const Text('Replay the app walkthrough'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await OnboardingService.instance.resetOnboarding();
                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/onboarding');
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) => value != null && value.isNotEmpty
                          ? null
                          : 'Name is required',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null && value.contains('@')
                          ? null
                          : 'Provide a valid email',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      keyboardType: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save profile'),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Data sources & disclaimer (required by Google Play)
                    const GovernmentDataDisclaimer(),
                    const SizedBox(height: 24),
                    // Danger zone - Delete Account
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showDeleteAccountDialog(context, provider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, UserProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Your profile information'),
            Text('• All saved tickets and citations'),
            Text('• Saved places and preferences'),
            Text('• Maintenance reports'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performAccountDeletion(context, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(
    BuildContext context,
    UserProvider provider,
  ) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          ),
        ),
      ),
    );

    final error = await provider.deleteAccount();

    if (!context.mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    } else {
      // Account deleted successfully - navigate to home
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
    }
  }
}
