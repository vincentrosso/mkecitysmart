import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../providers/user_provider.dart';
import '../services/push_diagnostics_service.dart';
import '../widgets/citysmart_scaffold.dart';

class AuthDiagnosticsScreen extends StatelessWidget {
  const AuthDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final pushDiag = PushDiagnosticsService.instance;

    final providerIds = user?.providerData.map((e) => e.providerId).toList();
    final perm = pushDiag.lastPermission;
    final locationDiag = pushDiag.lastLocationDiagnostics;
    String locationValue(String key, {String fallback = '(unknown)'}) {
      return locationDiag == null
          ? fallback
          : (locationDiag[key]?.toString() ?? fallback);
    }

    String permLabel(NotificationSettings? s) {
      if (s == null) return '(unknown - tap Refresh)';
      return '${s.authorizationStatus.name} (alert=${s.alert.name}, badge=${s.badge.name}, sound=${s.sound.name})';
    }

    return CitySmartScaffold(
      title: 'Diagnostics',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _kv('Firebase enabled', provider.firebaseEnabled ? 'yes' : 'no'),
          _kv('Initializing', provider.isInitializing ? 'yes' : 'no'),
          _kv('Guest mode', provider.isGuest ? 'yes' : 'no'),
          _kv('Logged in', provider.isLoggedIn ? 'yes' : 'no'),
          const Divider(height: 32),
          _kv('FirebaseAuth user', user == null ? 'null' : 'present'),
          if (user != null) ...[
            _kv('uid', user.uid),
            _kv('isAnonymous', user.isAnonymous ? 'yes' : 'no'),
            _kv('email', user.email ?? '(none)'),
            _kv('phone', user.phoneNumber ?? '(none)'),
            _kv('providerIds', providerIds?.join(', ') ?? '(none)'),
          ],
          const Divider(height: 32),
          _kv('Last auth error', provider.lastAuthError ?? '(none)'),

          const Divider(height: 32),
          _kv('Push permission', permLabel(perm)),
          _kv('FCM token', PushDiagnosticsService.redactToken(pushDiag.lastFcmToken)),
          _kv('FCM token time', pushDiag.lastFcmTokenTime?.toIso8601String() ?? '(none)'),
          _kv('Device register last', pushDiag.lastRegisterAttemptTime?.toIso8601String() ?? '(none)'),
          _kv('Device register OK', pushDiag.lastRegisterSuccess == null ? '(none)' : (pushDiag.lastRegisterSuccess! ? 'yes' : 'no')),
          _kv('Register error', pushDiag.lastRegisterError?.toString() ?? '(none)'),
          _kv('Location service', locationValue('locationServiceEnabled')),
          _kv('Location permission before', locationValue('locationPermissionBefore')),
          _kv('Location permission after', locationValue('locationPermissionAfter')),
          _kv('Location error', locationValue('locationError', fallback: '(none)')),

          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await pushDiag.refreshLocalSnapshot();
                  // This screen is stateless; we use a dialog as a lightweight refresh signal.
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshed push diagnostics')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh push'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final resp = await pushDiag.sendTestPushToSelf(
                      title: 'CitySmart TestFlight',
                      body: 'Push self-test',
                    );
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('testPushToSelf OK'),
                        content: SingleChildScrollView(child: Text(resp.toString())),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('testPushToSelf failed'),
                        content: SingleChildScrollView(child: Text(e.toString())),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notification_add),
                label: const Text('Test push to self'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Default to Milwaukee coordinates for nearby warning test
                    const defaultLat = 43.0389;
                    const defaultLng = -87.9065;
                    
                    final resp = await pushDiag.simulateNearbyWarning(
                      latitude: defaultLat,
                      longitude: defaultLng,
                      radiusMiles: 10, // Wide radius to ensure we catch registered devices
                    );
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Nearby Warning Sent'),
                        content: SingleChildScrollView(
                          child: Text(
                            'Result: ${resp.toString()}\n\n'
                            'You should receive a push notification shortly if your device is registered within 10 miles of Milwaukee.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Nearby Warning Failed'),
                        content: SingleChildScrollView(child: Text(e.toString())),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.warning_amber),
                label: const Text('Simulate nearby'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              final text = [
                'firebaseEnabled=${provider.firebaseEnabled}',
                'initializing=${provider.isInitializing}',
                'isGuest=${provider.isGuest}',
                'isLoggedIn=${provider.isLoggedIn}',
                'uid=${user?.uid}',
                'isAnonymous=${user?.isAnonymous}',
                'email=${user?.email}',
                'phone=${user?.phoneNumber}',
                'providerIds=${providerIds?.join(', ')}',
                'lastAuthError=${provider.lastAuthError}',
                'pushPermission=${perm?.authorizationStatus.name}',
                'fcmToken=${PushDiagnosticsService.redactToken(pushDiag.lastFcmToken)}',
                'fcmTokenTime=${pushDiag.lastFcmTokenTime?.toIso8601String()}',
                'deviceRegisterTime=${pushDiag.lastRegisterAttemptTime?.toIso8601String()}',
                'deviceRegisterOK=${pushDiag.lastRegisterSuccess}',
                'deviceRegisterErr=${pushDiag.lastRegisterError}',
                'locationServiceEnabled=${locationValue('locationServiceEnabled')}',
                'locationPermissionBefore=${locationValue('locationPermissionBefore')}',
                'locationPermissionAfter=${locationValue('locationPermissionAfter')}',
                'locationError=${locationValue('locationError', fallback: '(none)')}',
              ].join('\n');
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Diagnostics'),
                  content: SingleChildScrollView(child: Text(text)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.copy_all),
            label: const Text('View summary'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
