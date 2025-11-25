import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CSTheme {
  static const primary = AppColors.accentTeal;
  static const secondary = AppColors.accentOrange;
  static const accent = AppColors.accentYellow;
  static const background = AppColors.background;
  static const surface = AppColors.card;
  static const text = Colors.white;
  static const textMuted = AppColors.mutedIcon;
  static const border = Color(0xFF0E5C52);

  static ThemeData theme() => buildCitySmartTheme();
}
