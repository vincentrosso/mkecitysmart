import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'screens/report_sighting_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/ticket_workflow_screen.dart';
import 'screens/street_sweeping_screen.dart';
import 'screens/vehicle_management_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/history_receipts_screen.dart';
import 'screens/maintenance_report_screen.dart';
import 'screens/garbage_schedule_screen.dart';
import 'screens/city_settings_screen.dart';
import 'services/notification_service.dart';
import 'services/user_repository.dart';
import 'screens/alternate_side_parking_screen.dart';
import 'screens/parking_heatmap_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/risk_reminders_screen.dart';
import 'screens/alerts_landing_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = BootstrapDiagnostics();
  diagnostics
    ..addMetadata('Platform', describeEnum(defaultTargetPlatform))
    ..addMetadata(
      'BuildMode',
      kReleaseMode
          ? 'release'
          : kProfileMode
              ? 'profile'
              : 'debug',
    );

  const skipFirebaseBootstrap =
      bool.fromEnvironment('SKIP_FIREBASE', defaultValue: false);
  diagnostics.addMetadata('SKIP_FIREBASE', skipFirebaseBootstrap);
  const enableRemoteNotifications =
      bool.fromEnvironment('ENABLE_PUSH_NOTIFICATIONS', defaultValue: false);
  diagnostics.addMetadata(
    'ENABLE_PUSH_NOTIFICATIONS',
    enableRemoteNotifications,
  );

  bool firebaseReady = false;
  if (skipFirebaseBootstrap) {
    diagnostics.recordStatus(
      'Firebase',
      BootstrapStatus.skipped,
      details: 'Skipped via SKIP_FIREBASE dart define.',
    );
  } else {
    firebaseReady = await diagnostics.recordFuture<bool>(
      'Firebase',
      initializeFirebaseIfAvailable,
      onSuccess: (ready, entry) {
        if (ready) {
          entry.details = 'Initialization completed.';
        } else {
          entry.setStatus(
            BootstrapStatus.warning,
            message:
                'Config missing. Running without Firebase (no push/logging).',
          );
        }
      },
    );
  }
  diagnostics.addMetadata('FirebaseReady', firebaseReady);

  await diagnostics.recordFuture<void>(
    'CloudLogService',
    () => CloudLogService.instance.initialize(firebaseReady: firebaseReady),
    onSuccess: (_, entry) {
      if (firebaseReady) {
        entry.details = 'Cloud logging enabled.';
      } else {
        entry.setStatus(
          BootstrapStatus.info,
          message: 'Skipped; Firebase unavailable.',
        );
      }
    },
  );

  final shouldInitNotifications =
      firebaseReady && enableRemoteNotifications;
  diagnostics.addMetadata(
    'InitPushNotifications',
    shouldInitNotifications,
  );

  await diagnostics.recordFuture<void>(
    'NotificationService',
    () => NotificationService.instance
        .initialize(enableRemoteNotifications: shouldInitNotifications),
    onSuccess: (_, entry) {
      if (shouldInitNotifications) {
        entry.details = 'Remote + local notifications ready.';
      } else {
        entry.setStatus(
          BootstrapStatus.info,
          message:
              'Remote notifications disabled/unsupported. Local notifications ready on mobile.',
        );
      }
    },
  );

  final repository = await diagnostics.recordFuture<UserRepository>(
    'UserRepository',
    UserRepository.create,
    onSuccess: (_, entry) => entry.details = 'Repository ready.',
  );

  runApp(
    MKEParkApp(
      userRepository: repository,
      diagnostics: diagnostics,
      firebaseReady: firebaseReady,
    ),
  );
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
        title: 'MKEPark',
        theme: buildCitySmartTheme(),
        home: const CitySmartShell(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/landing': (context) => LandingScreen(),
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
          '/alternate-parking': (context) =>
              const AlternateSideParkingScreen(),
          '/parking-heatmap': (context) => const ParkingHeatmapScreen(),
          '/citysmart-dashboard': (context) => const DashboardScreen(),
          '/citysmart-map': (context) => const MapScreen(),
          '/citysmart-feed': (context) => const FeedScreen(),
          '/citysmart-shell': (context) => const CitySmartShell(),
          '/feed': (context) => const FeedScreen(),
        },
      ),
    );
  }
}

/// Bottom navigation container (Dashboard / Map / Feed)
class CitySmartShell extends StatefulWidget {
  const CitySmartShell({super.key});

  @override
  State<CitySmartShell> createState() => _CitySmartShellState();
}

class _CitySmartShellState extends State<CitySmartShell> {
  int _index = 0;
  bool _quickShown = false;
  bool _tutorialDone = false;
  int _tutorialStep = 0;
  bool _welcomeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showQuickStart());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWelcome());
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [DashboardScreen(), MapScreen(), FeedScreen()];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          if (_index != i) {
            CloudLogService.instance
                .logEvent('tab_change', data: {'tab': _tabLabel(i)});
          }
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_outlined),
            label: 'Feed',
          ),
        ],
      ),
    );
  }

  void _showQuickStart() {
    if (_quickShown || _tutorialDone) return;
    _quickShown = true;
    CloudLogService.instance.logEvent('quick_start_prompt');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick start',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kCitySmartText,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _tutorialDone = true;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TutorialStepContent(step: _tutorialStep),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _tutorialStep == 0
                        ? null
                        : () => setState(() {
                            _tutorialStep--;
                          }),
                    child: const Text('Back'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_tutorialStep < 2) {
                        setState(() {
                          _tutorialStep++;
                        });
                      } else {
                        _tutorialDone = true;
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(_tutorialStep < 2 ? 'Next' : 'Done'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _maybeShowWelcome() async {
    if (_welcomeChecked) return;
    _welcomeChecked = true;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_welcome_v1') ?? false;
    if (seen || !mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: kCitySmartCard,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to CitySmart',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Start with the Dashboard tiles to explore Parking, Alt-side, Heatmap, and Alerts. You can change city/language anytime in City settings.',
                  style: TextStyle(color: kCitySmartText),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await prefs.setBool('seen_welcome_v1', true);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Get started'),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs.setBool('seen_welcome_v1', true);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _tabLabel(int index) {
    switch (index) {
      case 0:
        return 'dashboard';
      case 1:
        return 'map';
      case 2:
        return 'feed';
      default:
        return 'unknown';
    }
  }
}

class _QuickBullet extends StatelessWidget {
  const _QuickBullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: kCitySmartText,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kCitySmartText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStepContent extends StatelessWidget {
  const _TutorialStepContent({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _QuickBullet(
              'Use Dashboard tiles for Parking, Alerts, Heatmap, and Alt-side parking.',
            ),
            _QuickBullet(
              'Parking tile shows today’s side; heatmap shows likely open spots.',
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _QuickBullet(
              'Map tab shows the charging map; add parking layers as needed.',
            ),
            _QuickBullet(
              'Feed tab: alerts + sponsored items. Tap for details.',
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _QuickBullet(
              'Enable ticket/tow alerts in Preferences for automatic notifications.',
            ),
            _QuickBullet(
              'Report enforcer/tow sightings to improve risk alerts.',
            ),
          ],
        );
    }
  }
}
