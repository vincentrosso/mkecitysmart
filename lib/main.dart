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
import 'screens/charging_map_screen.dart';
import 'screens/garbage_schedule_screen.dart';
import 'services/notification_service.dart';

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
        title: 'MKEPark',
        theme: ThemeData(
          primaryColor: const Color(0xFF003E29),
          scaffoldBackgroundColor: const Color(0xFF003E29),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
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
        },
      ),
    );
  }
}
