import 'package:flutter/material.dart';

/// Color families a user can pick for the activity heatmap. Level 0 (no
/// activity) always comes from [AppColors.heatmapLevels] so it stays a
/// neutral tone matching the app's surface — only levels 1–4 (increasing
/// activity) vary by theme.
enum HeatmapColorTheme {
  green,
  blue,
  purple,
  amber,
  maroon,
  babyPink;

  String get label {
    switch (this) {
      case HeatmapColorTheme.green:
        return 'Green';
      case HeatmapColorTheme.blue:
        return 'Blue';
      case HeatmapColorTheme.purple:
        return 'Purple';
      case HeatmapColorTheme.amber:
        return 'Amber';
      case HeatmapColorTheme.maroon:
        return 'Maroon';
      case HeatmapColorTheme.babyPink:
        return 'Baby Pink';
    }
  }

  /// Four colors, level 1 (lightest activity) through level 4 (heaviest),
  /// tuned separately for dark and light app themes.
  List<Color> ramp(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (this) {
      case HeatmapColorTheme.green:
        return isDark
            ? const [
                Color(0xFF0A3D1F),
                Color(0xFF1A6B38),
                Color(0xFF25A244),
                Color(0xFF4CD964),
              ]
            : const [
                Color(0xFFBFE6CB),
                Color(0xFF7FCB98),
                Color(0xFF34AE5C),
                Color(0xFF1B8A3A),
              ];
      case HeatmapColorTheme.blue:
        return isDark
            ? const [
                Color(0xFF0A2C4D),
                Color(0xFF15477A),
                Color(0xFF2166B0),
                Color(0xFF4C9CE0),
              ]
            : const [
                Color(0xFFCFE3F7),
                Color(0xFF8FC0EC),
                Color(0xFF3E86D0),
                Color(0xFF1A5A9E),
              ];
      case HeatmapColorTheme.purple:
        return isDark
            ? const [
                Color(0xFF2A0A4D),
                Color(0xFF47157A),
                Color(0xFF6621B0),
                Color(0xFF9C4CE0),
              ]
            : const [
                Color(0xFFE3CFF7),
                Color(0xFFC08FEC),
                Color(0xFF863ED0),
                Color(0xFF5A1A9E),
              ];
      case HeatmapColorTheme.amber:
        return isDark
            ? const [
                Color(0xFF4D3A0A),
                Color(0xFF7A5C15),
                Color(0xFFB08321),
                Color(0xFFE0B44C),
              ]
            : const [
                Color(0xFFF7EACF),
                Color(0xFFECCE8F),
                Color(0xFFD0983E),
                Color(0xFF9E6E1A),
              ];
      case HeatmapColorTheme.maroon:
        return isDark
            ? const [
                Color(0xFF4D0A16),
                Color(0xFF7A1526),
                Color(0xFFB0212F),
                Color(0xFFE04C56),
              ]
            : const [
                Color(0xFFF7CFD3),
                Color(0xFFECA0A8),
                Color(0xFFD04C58),
                Color(0xFF9E1A26),
              ];
      case HeatmapColorTheme.babyPink:
        return isDark
            ? const [
                Color(0xFF4D1A2E),
                Color(0xFF7A2F47),
                Color(0xFFB0466B),
                Color(0xFFE080A0),
              ]
            : const [
                Color(0xFFF7DCE8),
                Color(0xFFECAECD),
                Color(0xFFD06B9E),
                Color(0xFF9E3A6E),
              ];
    }
  }

  /// A single representative color for pickers/swatches.
  Color swatch(Brightness brightness) => ramp(brightness)[3];
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
