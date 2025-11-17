import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/app_router.dart';
import 'providers/parking_provider.dart';
import 'providers/location_provider.dart';
import 'providers/user_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(const CitySmartParkingApp());
}

class CitySmartParkingApp extends StatelessWidget {
  const CitySmartParkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ParkingProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp.router(
        title: 'CitySmart Parking App',
        theme: ThemeData(
          primaryColor: const Color(0xFF003E29),
          scaffoldBackgroundColor: const Color(0xFF003E29),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF003E29),
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0xFF003E29),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF006A3B),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
