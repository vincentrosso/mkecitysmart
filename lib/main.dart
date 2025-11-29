import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'citysmart/branding_preview.dart';
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
import 'services/user_repository.dart';
import 'screens/history_receipts_screen.dart';
import 'screens/maintenance_report_screen.dart';
import 'screens/garbage_schedule_screen.dart';
import 'screens/city_settings_screen.dart';
import 'services/notification_service.dart';
import 'screens/alternate_side_parking_screen.dart';
import 'screens/parking_heatmap_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await AdService.instance
        .initialize(appId: 'ca-app-pub-2009498889741048~9019853313');
  }
  await NotificationService.instance.initialize();
  final repository = await UserRepository.create();
  runApp(MKEParkApp(userRepository: repository));
}

class MKEParkApp extends StatelessWidget {
  const MKEParkApp({super.key, required this.userRepository});

  final UserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(userRepository: userRepository)..initialize(),
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
          '/alerts': (context) => const PreferencesScreen(),
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
          '/parking-heatmap': (context) =>
              const ParkingHeatmapScreen(),
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
    final pages = const [
      DashboardScreen(),
      MapScreen(),
      FeedScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
