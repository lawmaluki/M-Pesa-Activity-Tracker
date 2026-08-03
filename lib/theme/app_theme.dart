import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the light/dark [ThemeData] the app switches between. Each carries
/// its matching [AppColors] extension so screens can read semantic colors
/// via `context.colors` instead of hardcoding hex values.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.brandGreen,
        brightness: brightness,
        primary: colors.brandGreen,
        secondary: colors.accentGreen,
        surface: colors.surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceAlt,
        contentTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
      extensions: [colors],
    );
  }
}
