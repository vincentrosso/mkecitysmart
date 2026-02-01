import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'citysmart/branding_preview.dart';
import 'firebase_bootstrap.dart';
import 'services/bootstrap_diagnostics.dart';
import 'services/cloud_log_service.dart';
import 'providers/user_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/charging_map_screen.dart';
import 'screens/history_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/parking_screen.dart';
import 'screens/permit_workflow_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/permit_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/report_sighting_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/ticket_workflow_screen.dart';
import 'screens/street_sweeping_screen.dart';
import 'screens/vehicle_management_screen.dart';
import 'screens/history_receipts_screen.dart';
import 'screens/maintenance_report_screen.dart';
import 'screens/garbage_schedule_screen.dart';
import 'screens/city_settings_screen.dart';
import 'screens/local_alerts_screen.dart';
import 'services/notification_service.dart';
import 'services/user_repository.dart';
import 'screens/alternate_side_parking_screen.dart';
import 'screens/parking_heatmap_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/alerts_landing_screen.dart';
import 'screens/alert_detail_screen.dart';
import 'screens/auth_diagnostics_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start UI immediately; bootstrap runs asynchronously to avoid splash hangs.
  runApp(const _BootstrapApp());
}

Future<void> ensureAuthenticated() async {
  if (FirebaseAuth.instance.currentUser != null) return;
  await FirebaseAuth.instance.signInAnonymously();
  debugPrint(
    'Signed in anonymously with UID: ${FirebaseAuth.instance.currentUser?.uid}',
  );
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  BootstrapDiagnostics? _diagnostics;
  UserRepository? _repository;
  bool _firebaseReady = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final diagnostics = BootstrapDiagnostics();
    bool firebaseReady = false;
    UserRepository? repo;

    try {
      firebaseReady = await diagnostics
          .recordFuture<bool>(
            'Firebase',
            initializeFirebaseIfAvailable,
            onSuccess: (ready, entry) {
              entry.details = ready ? 'Initialization completed.' : 'Config missing.';
            },
          )
          .timeout(const Duration(seconds: 12), onTimeout: () => false);

      // If Firebase initialized, attempt an anonymous sign-in so
      // FirebaseAuth is ready for services that expect a user.
      if (firebaseReady) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
          print('Anonymous auth UID: ${FirebaseAuth.instance.currentUser?.uid}');
        } catch (e, st) {
          print('Anonymous sign-in failed: $e');
          // Log to cloud if available; ignore failures here.
          try {
            developer.log('Anonymous sign-in failed: $e', stackTrace: st);
          } catch (_) {}
        }
      }

      if (firebaseReady) {
        // Local emulator wiring disabled for prod builds.
        // if (kDebugMode) {
        //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5003);
        //   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8085);
        //   FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        // }

        await diagnostics
            .recordFuture<void>(
              'Auth',
              ensureAuthenticated,
              onSuccess: (_, entry) =>
                  entry.details = 'Signed in (anonymous ok).',
            )
            .timeout(const Duration(seconds: 8), onTimeout: () async {});
      }

      if (!kIsWeb) {
        await diagnostics
            .recordFuture<void>(
              'NotificationService',
              () => NotificationService.instance.initialize(
                enableRemoteNotifications: true,
              ),
              onSuccess: (_, entry) =>
                  entry.details = 'Permissions/token/handlers configured.',
            )
            .timeout(const Duration(seconds: 8), onTimeout: () async {});
      }

      await diagnostics
          .recordFuture<void>(
            'CloudLogService',
            () => CloudLogService.instance.initialize(firebaseReady: firebaseReady),
          )
          .timeout(const Duration(seconds: 8), onTimeout: () async {});
    } catch (e, st) {
      debugPrint('BOOT ERROR: $e');
      debugPrint('$st');
      firebaseReady = false;
    }

    try {
      repo = await diagnostics
          .recordFuture<UserRepository>(
            'UserRepository',
            () async => UserRepository(),
            onSuccess: (_, entry) => entry.details = 'Repository ready.',
          )
          .timeout(const Duration(seconds: 8), onTimeout: () => UserRepository());
    } catch (_) {
      repo = UserRepository();
    }

    setState(() {
      _diagnostics = diagnostics;
      _repository = repo;
      _firebaseReady = firebaseReady;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_repository == null || _diagnostics == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MKEParkApp(
      userRepository: _repository!,
      diagnostics: _diagnostics!,
      firebaseReady: _firebaseReady,
    );
  }
}

class MKEParkApp extends StatelessWidget {
  const MKEParkApp({
    super.key,
    required this.userRepository,
    required this.diagnostics,
    required this.firebaseReady,
  });

  final UserRepository userRepository;
  final BootstrapDiagnostics diagnostics;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(
        userRepository: userRepository,
        firebaseReady: firebaseReady,
      )..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MKE CitySmart',
        theme: buildCitySmartTheme(),
        initialRoute: '/',
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        ),
        routes: {
          '/': (context) => const _InitialRouteDecider(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/landing': (context) => LandingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/register': (context) => const RegisterScreen(),
          '/auth-diagnostics': (context) => const AuthDiagnosticsScreen(),
          '/parking': (context) => const ParkingScreen(),
          '/permit': (context) => const PermitScreen(),
          '/permit-workflow': (context) => const PermitWorkflowScreen(),
          '/sweeping': (context) => const StreetSweepingScreen(),
          '/history': (context) => HistoryScreen(),
          '/history/receipts': (context) => const HistoryReceiptsScreen(),
          '/branding': (context) => const BrandingPreviewPage(),
          '/profile': (context) => const ProfileScreen(),
          '/vehicles': (context) => const VehicleManagementScreen(),
          '/preferences': (context) => const PreferencesScreen(),
          '/alerts': (context) => const AlertsLandingScreen(),
          '/charging': (context) => const ChargingMapScreen(),
          '/report-sighting': (context) => const ReportSightingScreen(),
          '/tickets': (context) => const TicketWorkflowScreen(),
          '/subscriptions': (context) => const SubscriptionScreen(),
          '/maintenance': (context) => const MaintenanceReportScreen(),
          '/predictions': (context) => const ChargingMapScreen(),
          '/garbage': (context) => const GarbageScheduleScreen(),
          '/city-settings': (context) => const CitySettingsScreen(),
          '/alternate-side-parking': (context) => const AlternateSideParkingScreen(),
          '/alternate-parking': (context) => const AlternateSideParkingScreen(),
          '/parking-heatmap': (context) => const ParkingHeatmapScreen(),
          '/citysmart-dashboard': (context) => const DashboardScreen(),
          '/citysmart-map': (context) => const MapScreen(),
          '/citysmart-feed': (context) => const FeedScreen(),
          '/feed': (context) => const FeedScreen(),
          '/alert-detail': (context) {
            final alertId = ModalRoute.of(context)?.settings.arguments as String?;
            if (alertId == null) {
              return const Scaffold(
                body: Center(child: Text('Alert ID missing')),
              );
            }
            return AlertDetailScreen(alertId: alertId);
          },
        },
      ),
    );
  }
}

/// Decides whether to show onboarding or dashboard on initial app launch.
class _InitialRouteDecider extends StatefulWidget {
  const _InitialRouteDecider();

  @override
  State<_InitialRouteDecider> createState() => _InitialRouteDeciderState();
}

class _InitialRouteDeciderState extends State<_InitialRouteDecider> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final isComplete = await OnboardingService.instance.isOnboardingComplete();
    if (mounted) {
      setState(() {
        _showOnboarding = !isComplete;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF081D19),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/brand/citysmart_icon_rounded.png',
                width: 80,
                height: 80,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.location_city,
                  size: 80,
                  color: Color(0xFFE0C164),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE0C164)),
              ),
            ],
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    return const DashboardScreen();
  }
}
