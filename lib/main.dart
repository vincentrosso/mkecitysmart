import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}
