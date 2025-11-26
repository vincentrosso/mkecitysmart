import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CSTheme {
  static const primary = kCitySmartYellow;
  static const secondary = kCitySmartCard;
  static const accent = kCitySmartYellow;
  static const background = kCitySmartGreen;
  static const surface = kCitySmartCard;
  static const text = kCitySmartText;
  static const textMuted = kCitySmartMuted;
  static const border = Color(0xFF29332E);

  static ThemeData theme() => buildCitySmartTheme();
}
