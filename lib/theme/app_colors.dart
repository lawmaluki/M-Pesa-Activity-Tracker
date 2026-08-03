import 'package:flutter/material.dart';

/// Every semantic color the app uses, so screens never hardcode a hex value
/// — they read `context.colors.xxx` instead. One instance for dark, one for
/// light; [MaterialApp] picks between them via `theme` / `darkTheme`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Base surfaces
  final Color background;
  final Color surface; // cards, dialogs
  final Color surfaceAlt; // snackbar, popup menu, elevated surface
  final Color border; // subtle 1px card/input borders

  // Text tiers
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color textFaint;

  // Brand
  final Color brandGreen; // solid brand fills (logo badge, buttons)
  final Color accentGreen; // green used as text/icon/link on top of surface

  // Tinted badges (bg + icon) — stat card icons & transaction type icons
  final Color greenTintBg;
  final Color greenTintIcon;
  final Color redTintBg;
  final Color redTintIcon;
  final Color amberTintBg;
  final Color amberTintIcon;
  final Color blueTintBg;
  final Color blueTintIcon;
  final Color purpleTintBg;
  final Color purpleTintIcon;
  final Color yellowTintBg;
  final Color yellowTintIcon;
  final Color neutralTintBg;
  final Color neutralTintIcon;
  final Color reversalTintBg;
  final Color reversalTintIcon;

  // Heatmap
  final List<Color> heatmapLevels;
  final Color heatmapFutureBorder;
  final Color heatmapTodayBorder;

  // Status banners / dialogs
  final Color successBg;
  final Color successAccent;
  final Color warningBg;
  final Color warningAccent;
  final Color dangerBg;
  final Color dangerAccent;
  final Color dangerText;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textFaint,
    required this.brandGreen,
    required this.accentGreen,
    required this.greenTintBg,
    required this.greenTintIcon,
    required this.redTintBg,
    required this.redTintIcon,
    required this.amberTintBg,
    required this.amberTintIcon,
    required this.blueTintBg,
    required this.blueTintIcon,
    required this.purpleTintBg,
    required this.purpleTintIcon,
    required this.yellowTintBg,
    required this.yellowTintIcon,
    required this.neutralTintBg,
    required this.neutralTintIcon,
    required this.reversalTintBg,
    required this.reversalTintIcon,
    required this.heatmapLevels,
    required this.heatmapFutureBorder,
    required this.heatmapTodayBorder,
    required this.successBg,
    required this.successAccent,
    required this.warningBg,
    required this.warningAccent,
    required this.dangerBg,
    required this.dangerAccent,
    required this.dangerText,
  });

  // ── Dark (the app's original palette, unchanged) ──────────────────────
  static const dark = AppColors(
    background: Colors.black,
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2C2C2E),
    border: Colors.white12,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white54,
    textMuted: Colors.white38,
    textFaint: Colors.white24,
    brandGreen: Color(0xFF25A244),
    accentGreen: Color(0xFF4CD964),
    greenTintBg: Color(0xFF1C3B28),
    greenTintIcon: Color(0xFF4CD964),
    redTintBg: Color(0xFF3B1F1C),
    redTintIcon: Color(0xFFFF6B5E),
    amberTintBg: Color(0xFF3A2C1A),
    amberTintIcon: Colors.white,
    blueTintBg: Color(0xFF1A2D4D),
    blueTintIcon: Colors.white,
    purpleTintBg: Color(0xFF2D1A4D),
    purpleTintIcon: Colors.white,
    yellowTintBg: Color(0xFF2D2D1A),
    yellowTintIcon: Colors.white,
    neutralTintBg: Color(0xFF3A3A3C),
    neutralTintIcon: Colors.white,
    reversalTintBg: Color(0xFF4D1A1A),
    reversalTintIcon: Colors.white,
    heatmapLevels: [
      Color(0xFF1C1C1E),
      Color(0xFF0A3D1F),
      Color(0xFF1A6B38),
      Color(0xFF25A244),
      Color(0xFF4CD964),
    ],
    heatmapFutureBorder: Color(0x0FFFFFFF),
    heatmapTodayBorder: Colors.white54,
    successBg: Color(0xFF1A4D2E),
    successAccent: Color(0xFF4CD964),
    warningBg: Color(0xFF4D3A1A),
    warningAccent: Color(0xFFFFB74D),
    dangerBg: Color(0xFF4D1A1A),
    dangerAccent: Colors.red,
    dangerText: Color(0xFFE57373),
  );

  // ── Light ───────────────────────────────────────────────────────────
  static const light = AppColors(
    background: Color(0xFFF6F8F7),
    surface: Colors.white,
    surfaceAlt: Color(0xFFEFF1F0),
    border: Color(0xFFE2E5E3),
    textPrimary: Color(0xFF15171A),
    textSecondary: Color(0xFF4B4F54),
    textTertiary: Color(0xFF6E7378),
    textMuted: Color(0xFF9AA0A6),
    textFaint: Color(0xFFC3C7CB),
    brandGreen: Color(0xFF25A244),
    accentGreen: Color(0xFF1B8A3A),
    greenTintBg: Color(0xFFDFF3E4),
    greenTintIcon: Color(0xFF1B8A3A),
    redTintBg: Color(0xFFFBE4E1),
    redTintIcon: Color(0xFFC2453A),
    amberTintBg: Color(0xFFF5E6D0),
    amberTintIcon: Color(0xFF8A5A1E),
    blueTintBg: Color(0xFFDCE8FB),
    blueTintIcon: Color(0xFF2255A0),
    purpleTintBg: Color(0xFFE9DFFB),
    purpleTintIcon: Color(0xFF6A3FA0),
    yellowTintBg: Color(0xFFF5F0CE),
    yellowTintIcon: Color(0xFF7A6A16),
    neutralTintBg: Color(0xFFE7E8EA),
    neutralTintIcon: Color(0xFF55575C),
    reversalTintBg: Color(0xFFFBDEDE),
    reversalTintIcon: Color(0xFFA02828),
    heatmapLevels: [
      Color(0xFFE9ECEA),
      Color(0xFFBFE6CB),
      Color(0xFF7FCB98),
      Color(0xFF34AE5C),
      Color(0xFF1B8A3A),
    ],
    heatmapFutureBorder: Color(0x0F000000),
    heatmapTodayBorder: Color(0x8A000000),
    successBg: Color(0xFFE3F6E9),
    successAccent: Color(0xFF1B8A3A),
    warningBg: Color(0xFFFFF3DF),
    warningAccent: Color(0xFFB8720A),
    dangerBg: Color(0xFFFDE4E1),
    dangerAccent: Color(0xFFD32F2F),
    dangerText: Color(0xFFB71C1C),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textMuted,
    Color? textFaint,
    Color? brandGreen,
    Color? accentGreen,
    Color? greenTintBg,
    Color? greenTintIcon,
    Color? redTintBg,
    Color? redTintIcon,
    Color? amberTintBg,
    Color? amberTintIcon,
    Color? blueTintBg,
    Color? blueTintIcon,
    Color? purpleTintBg,
    Color? purpleTintIcon,
    Color? yellowTintBg,
    Color? yellowTintIcon,
    Color? neutralTintBg,
    Color? neutralTintIcon,
    Color? reversalTintBg,
    Color? reversalTintIcon,
    List<Color>? heatmapLevels,
    Color? heatmapFutureBorder,
    Color? heatmapTodayBorder,
    Color? successBg,
    Color? successAccent,
    Color? warningBg,
    Color? warningAccent,
    Color? dangerBg,
    Color? dangerAccent,
    Color? dangerText,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      brandGreen: brandGreen ?? this.brandGreen,
      accentGreen: accentGreen ?? this.accentGreen,
      greenTintBg: greenTintBg ?? this.greenTintBg,
      greenTintIcon: greenTintIcon ?? this.greenTintIcon,
      redTintBg: redTintBg ?? this.redTintBg,
      redTintIcon: redTintIcon ?? this.redTintIcon,
      amberTintBg: amberTintBg ?? this.amberTintBg,
      amberTintIcon: amberTintIcon ?? this.amberTintIcon,
      blueTintBg: blueTintBg ?? this.blueTintBg,
      blueTintIcon: blueTintIcon ?? this.blueTintIcon,
      purpleTintBg: purpleTintBg ?? this.purpleTintBg,
      purpleTintIcon: purpleTintIcon ?? this.purpleTintIcon,
      yellowTintBg: yellowTintBg ?? this.yellowTintBg,
      yellowTintIcon: yellowTintIcon ?? this.yellowTintIcon,
      neutralTintBg: neutralTintBg ?? this.neutralTintBg,
      neutralTintIcon: neutralTintIcon ?? this.neutralTintIcon,
      reversalTintBg: reversalTintBg ?? this.reversalTintBg,
      reversalTintIcon: reversalTintIcon ?? this.reversalTintIcon,
      heatmapLevels: heatmapLevels ?? this.heatmapLevels,
      heatmapFutureBorder: heatmapFutureBorder ?? this.heatmapFutureBorder,
      heatmapTodayBorder: heatmapTodayBorder ?? this.heatmapTodayBorder,
      successBg: successBg ?? this.successBg,
      successAccent: successAccent ?? this.successAccent,
      warningBg: warningBg ?? this.warningBg,
      warningAccent: warningAccent ?? this.warningAccent,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerAccent: dangerAccent ?? this.dangerAccent,
      dangerText: dangerText ?? this.dangerText,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    // A straight crossfade across ~30 fields isn't worth the noise here —
    // the app only ever switches wholesale between the two palettes, so a
    // simple midpoint switch is visually indistinguishable in practice.
    return t < 0.5 ? this : other;
  }
}

/// Shorthand: `context.colors.textPrimary` instead of
/// `Theme.of(context).extension<AppColors>()!.textPrimary`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
