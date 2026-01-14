import 'package:flutter/material.dart';

// Palette
const Color kCitySmartGreen = Color(0xFF081D19); // main background
const Color kCitySmartCard = Color(0xFF0C241F); // tiles / cards
const Color kCitySmartYellow = Color(0xFFE0C164); // accent / buttons
const Color kCitySmartText = Color(0xFFFDF7EC); // primary text
const Color kCitySmartMuted = Color(0xFF9BA59C); // secondary text

ThemeData buildCitySmartTheme() {
  final base = ThemeData.dark();

  return base.copyWith(
    scaffoldBackgroundColor: kCitySmartGreen,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: kCitySmartYellow,
      onPrimary: kCitySmartGreen,
      surface: kCitySmartCard,
      onSurface: kCitySmartText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCitySmartGreen,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: kCitySmartYellow,
      ),
      iconTheme: IconThemeData(color: kCitySmartYellow),
    ),
    cardTheme: CardThemeData(
      color: kCitySmartCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kCitySmartYellow,
        foregroundColor: kCitySmartGreen,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kCitySmartYellow,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: kCitySmartText,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kCitySmartText,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: kCitySmartText,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kCitySmartText,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: kCitySmartText,
        letterSpacing: 0.6,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kCitySmartGreen,
      selectedItemColor: kCitySmartYellow,
      unselectedItemColor: kCitySmartMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: kCitySmartCard,
      iconColor: kCitySmartYellow,
      textColor: kCitySmartText,
    ),
    dividerColor: const Color(0xFF29332E),
  );
}
