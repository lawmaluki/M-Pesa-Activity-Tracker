import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/heatmap_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/heatmap_theme.dart';

/// Bottom sheet for customizing heatmap color theme, cell size, and cell
/// shape. Every control writes straight to [HeatmapSettingsProvider], so
/// the grid on the Overview screen behind the sheet updates live as the
/// user taps — there's no separate "Apply" step.
class HeatmapCustomizeSheet extends StatelessWidget {
  const HeatmapCustomizeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const HeatmapCustomizeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = context.watch<HeatmapSettingsProvider>();
    final brightness = Theme.of(context).brightness;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Customize Heatmap',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Color theme'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: HeatmapColorTheme.values.map((theme) {
                final selected = settings.colorTheme == theme;
                final swatchColor = theme.swatch(brightness);
                final onSwatch =
                    ThemeData.estimateBrightnessForColor(swatchColor) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black;
                return GestureDetector(
                  onTap: () => context
                      .read<HeatmapSettingsProvider>()
                      .setColorTheme(theme),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: colors.textPrimary, width: 2)
                              : null,
                        ),
                        child: selected
                            ? Icon(Icons.check, color: onSwatch, size: 18)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.label,
                        style:
                            TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Cell size'),
            const SizedBox(height: 12),
            _SegmentedRow<HeatmapCellSize>(
              options: HeatmapCellSize.values,
              selected: settings.cellSize,
              labelBuilder: (s) => s.label,
              onSelected: (s) =>
                  context.read<HeatmapSettingsProvider>().setCellSize(s),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Cell shape'),
            const SizedBox(height: 12),
            _SegmentedRow<HeatmapCellShape>(
              options: HeatmapCellShape.values,
              selected: settings.cellShape,
              labelBuilder: (s) => s.label,
              onSelected: (s) =>
                  context.read<HeatmapSettingsProvider>().setCellShape(s),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  const _SegmentedRow({
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final opt in options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == options.last ? 0 : 8),
              child: GestureDetector(
                onTap: () => onSelected(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: opt == selected
                        ? colors.accentGreen.withValues(alpha: 0.15)
                        : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: opt == selected
                          ? colors.accentGreen
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    labelBuilder(opt),
                    style: TextStyle(
                      color: opt == selected
                          ? colors.accentGreen
                          : colors.textSecondary,
                      fontWeight:
                          opt == selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
