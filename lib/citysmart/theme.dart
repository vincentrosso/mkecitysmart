import 'package:flutter/material.dart';

class CSTheme {
  // Brand Colors
  static const primary = Color(0xFF5E8A45);
  static const secondary = Color(0xFF7CA726);
  static const accent = Color(0xFFE0B000);
  
  // Neutral Colors
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const text = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textLight = Color(0xFF718096);
  static const border = Color(0xFFE2E8F0);
  
  // Semantic Colors
  static const success = Color(0xFF48BB78);
  static const warning = Color(0xFFED8936);
  static const error = Color(0xFFF56565);
  static const info = Color(0xFF4299E1);
  
  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: background,
    
    // Card styling
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // AppBar styling
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: text,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    
    // Text styling
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: text,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: text,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textLight,
      ),
    ),
    
    // Chip styling
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE8F5E9),
      labelStyle: const TextStyle(
        color: Color(0xFF2E7D32),
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // FAB styling
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Input styling
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    fontFamily: 'Inter',
  );
}
