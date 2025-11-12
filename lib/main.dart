import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/parking_screen.dart';
import 'screens/permit_screen.dart';
import 'screens/street_sweeping_screen.dart';
import 'screens/history_screen.dart';
import 'screens/landing_screen.dart';
import 'citysmart/branding_preview.dart';

void main() {
  runApp(const MKEParkApp());
}

class MKEParkApp extends StatelessWidget {
  const MKEParkApp({super.key});

  Widget withDrawer(Widget child) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
        title: const Text('MKEPark'),
        iconTheme: const IconThemeData(color: Colors.white), // ← sets hamburger AND back arrow
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF003E29),
        child: Builder(
          builder: (context) => ListView(
            padding: EdgeInsets.zero,
            children: const [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF003E29)),
                child: Text('Milwaukee, WI', style: TextStyle(color: Colors.white, fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MKEPark',
      theme: ThemeData(
        primaryColor: const Color(0xFF003E29),
        scaffoldBackgroundColor: const Color(0xFF003E29),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/parking': (context) => const ParkingScreen(),
        '/permit': (context) => const PermitScreen(),
        '/sweeping': (context) => const StreetSweepingScreen(),
        '/history': (context) => HistoryScreen(),
        '/landing': (context) => LandingScreen(),
        '/branding': (context) => const BrandingPreviewPage(),
      },
    );
  }
}
