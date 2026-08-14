import 'package:flutter/material.dart';

/// Color families a user can pick for the activity heatmap. Level 0 (no
/// activity) always comes from [AppColors.heatmapLevels] so it stays a
/// neutral tone matching the app's surface — only levels 1–4 (increasing
/// activity) vary by theme.
///
/// Each member is one swatch in the picker grid (a fixed hue/saturation,
/// like a color-picker dot) rather than a hand-tuned 4-color ramp — the
/// 4 activity-intensity shades are generated on the fly as a lightness
/// gradient from that swatch (see [ramp]), so the picker can offer a full
/// palette without hand-authoring a ramp per color.
enum HeatmapColorTheme {
  red,
  orange,
  yellow,
  lime,
  green,
  mint,
  teal,
  blue,
  indigo,
  purple,
  violet,
  magenta,
  pink,
  rose,
  slate,
  gray,
  steel,
  charcoal;

  String get label {
    switch (this) {
      case HeatmapColorTheme.red:
        return 'Red';
      case HeatmapColorTheme.orange:
        return 'Orange';
      case HeatmapColorTheme.yellow:
        return 'Yellow';
      case HeatmapColorTheme.lime:
        return 'Lime';
      case HeatmapColorTheme.green:
        return 'Green';
      case HeatmapColorTheme.mint:
        return 'Mint';
      case HeatmapColorTheme.teal:
        return 'Teal';
      case HeatmapColorTheme.blue:
        return 'Blue';
      case HeatmapColorTheme.indigo:
        return 'Indigo';
      case HeatmapColorTheme.purple:
        return 'Purple';
      case HeatmapColorTheme.violet:
        return 'Violet';
      case HeatmapColorTheme.magenta:
        return 'Magenta';
      case HeatmapColorTheme.pink:
        return 'Pink';
      case HeatmapColorTheme.rose:
        return 'Rose';
      case HeatmapColorTheme.slate:
        return 'Slate';
      case HeatmapColorTheme.gray:
        return 'Gray';
      case HeatmapColorTheme.steel:
        return 'Steel';
      case HeatmapColorTheme.charcoal:
        return 'Charcoal';
    }
  }

  /// The raw picker dot color — shown as-is in the customize sheet
  /// regardless of the app's light/dark theme, so the picker always
  /// matches the palette the user is choosing from.
  Color get base {
    switch (this) {
      case HeatmapColorTheme.red:
        return const Color(0xFFFF6B6B);
      case HeatmapColorTheme.orange:
        return const Color(0xFFFFA94D);
      case HeatmapColorTheme.yellow:
        return const Color(0xFFFFD43B);
      case HeatmapColorTheme.lime:
        return const Color(0xFFB2E35B);
      case HeatmapColorTheme.green:
        return const Color(0xFF69DB7C);
      case HeatmapColorTheme.mint:
        return const Color(0xFF4ECDC4);
      case HeatmapColorTheme.teal:
        return const Color(0xFF3BC9DB);
      case HeatmapColorTheme.blue:
        return const Color(0xFF4DA3E0);
      case HeatmapColorTheme.indigo:
        return const Color(0xFF7B85E8);
      case HeatmapColorTheme.purple:
        return const Color(0xFF9B6BDE);
      case HeatmapColorTheme.violet:
        return const Color(0xFFB57BE0);
      case HeatmapColorTheme.magenta:
        return const Color(0xFFDB6FC7);
      case HeatmapColorTheme.pink:
        return const Color(0xFFF2789F);
      case HeatmapColorTheme.rose:
        return const Color(0xFFE0555F);
      case HeatmapColorTheme.slate:
        return const Color(0xFFC4C9CF);
      case HeatmapColorTheme.gray:
        return const Color(0xFFADB3BA);
      case HeatmapColorTheme.steel:
        return const Color(0xFF8A9099);
      case HeatmapColorTheme.charcoal:
        return const Color(0xFF6B7280);
    }
  }

  /// Four colors, level 1 (lightest activity) through level 4 (heaviest) —
  /// a lightness gradient built from this swatch's own hue/saturation
  /// (fixed lightness stops per app brightness) rather than a hand-picked
  /// ramp, so every swatch in the picker gets a consistent, usable ramp.
  List<Color> ramp(Brightness brightness) {
    final hsl = HSLColor.fromColor(base);
    const darkStops = [0.16, 0.30, 0.45, 0.62];
    const lightStops = [0.88, 0.74, 0.58, 0.42];
    final stops = brightness == Brightness.dark ? darkStops : lightStops;
    return stops
        .map((l) => HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation, l).toColor())
        .toList();
  }

  /// A single representative color for pickers/swatches — the raw base
  /// color, unaffected by [brightness] (kept as a parameter so call sites
  /// don't need to change) since the picker itself isn't theme-dependent.
  Color swatch(Brightness brightness) => base;
}

enum HeatmapCellSize {
  small,
  medium,
  large;

  String get label {
    switch (this) {
      case HeatmapCellSize.small:
        return 'S';
      case HeatmapCellSize.medium:
        return 'M';
      case HeatmapCellSize.large:
        return 'L';
    }
  }

  double get cellSize {
    switch (this) {
      case HeatmapCellSize.small:
        return 10.0;
      case HeatmapCellSize.medium:
        return 13.0;
      case HeatmapCellSize.large:
        return 16.0;
    }
  }

  double get gap {
    switch (this) {
      case HeatmapCellSize.small:
        return 2.0;
      case HeatmapCellSize.medium:
        return 3.0;
      case HeatmapCellSize.large:
        return 4.0;
    }
  }
}

enum HeatmapCellShape {
  square,
  circle;

  String get label {
    switch (this) {
      case HeatmapCellShape.square:
        return 'Square';
      case HeatmapCellShape.circle:
        return 'Circle';
    }
  }
}
