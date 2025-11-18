import 'package:flutter/material.dart';
class CSTheme {
  static const primary = Color(0xFF7CA726);
  static const secondary = Color(0xFF5E8A45);
  static const accent = Color(0xFFE0B000);
  static ThemeData theme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary),
    fontFamily: 'Inter',
  );
}
