import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/heatmap_theme.dart';

/// User-customizable heatmap appearance — color theme, cell size, cell
/// shape. Applies live everywhere the heatmap's colors are read (the grid,
/// its legend, and the day-detail intensity dot) since those all watch this
/// provider. Choices persist across launches.
class HeatmapSettingsProvider extends ChangeNotifier {
  static const _colorKey = 'heatmap_color_theme';
  static const _sizeKey = 'heatmap_cell_size';
  static const _shapeKey = 'heatmap_cell_shape';

  HeatmapColorTheme _colorTheme = HeatmapColorTheme.green;
  HeatmapCellSize _cellSize = HeatmapCellSize.medium;
  HeatmapCellShape _cellShape = HeatmapCellShape.square;

  HeatmapColorTheme get colorTheme => _colorTheme;
  HeatmapCellSize get cellSize => _cellSize;
  HeatmapCellShape get cellShape => _cellShape;

  HeatmapSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _colorTheme = HeatmapColorTheme.values.firstWhere(
        (c) => c.name == prefs.getString(_colorKey),
        orElse: () => HeatmapColorTheme.green,
      );
      _cellSize = HeatmapCellSize.values.firstWhere(
        (s) => s.name == prefs.getString(_sizeKey),
        orElse: () => HeatmapCellSize.medium,
      );
      _cellShape = HeatmapCellShape.values.firstWhere(
        (s) => s.name == prefs.getString(_shapeKey),
        orElse: () => HeatmapCellShape.square,
      );
      notifyListeners();
    } catch (_) {
      // Fall back to defaults if prefs aren't available.
    }
  }

  Future<void> setColorTheme(HeatmapColorTheme theme) async {
    if (_colorTheme == theme) return;
    _colorTheme = theme;
    notifyListeners();
    await _persist(_colorKey, theme.name);
  }

  Future<void> setCellSize(HeatmapCellSize size) async {
    if (_cellSize == size) return;
    _cellSize = size;
    notifyListeners();
    await _persist(_sizeKey, size.name);
  }

  Future<void> setCellShape(HeatmapCellShape shape) async {
    if (_cellShape == shape) return;
    _cellShape = shape;
    notifyListeners();
    await _persist(_shapeKey, shape.name);
  }

  Future<void> _persist(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Non-fatal — the choice still applies for this session.
    }
  }
}
