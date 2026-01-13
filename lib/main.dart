import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'services/notification_service.dart';
import 'services/user_repository.dart';
import 'screens/alternate_side_parking_screen.dart';
import 'screens/parking_heatmap_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/alerts_landing_screen.dart';
import 'screens/alert_detail_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final diagnostics = BootstrapDiagnostics();

  bool firebaseReady = false;

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

    await diagnostics
        .recordFuture<void>(
          'NotificationService',
          () => NotificationService.instance.initialize(
            enableRemoteNotifications: true,
          ),
        )
        .timeout(const Duration(seconds: 8), onTimeout: () async {});
  } catch (e, st) {
    debugPrint('BOOT ERROR: $e');
    debugPrint('$st');
    firebaseReady = false;
  }

  UserRepository? repo;
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

  runApp(
    MKEParkApp(
      userRepository: repo!,
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
        title: 'MKE CitySmart',
        theme: buildCitySmartTheme(),
        initialRoute: '/dashboard',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/landing': (context) => const LandingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/register': (context) => const RegisterScreen(),
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
