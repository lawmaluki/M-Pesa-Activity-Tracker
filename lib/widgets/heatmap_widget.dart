import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/heatmap_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/heatmap_theme.dart';

/// GitHub-style contribution heatmap for M-Pesa transaction activity.
///
/// Renders a 53-week grid (columns = weeks, rows = Mon–Sun).
/// Each cell is coloured by [intensityFor] — 0 = no activity, 4 = very high.
/// Color theme, cell size, and cell shape all come from
/// [HeatmapSettingsProvider] so changes in the customize sheet apply live.
class HeatmapWidget extends StatelessWidget {
  final int year;
  final Map<String, int> dailyCounts;

  /// Called when the user taps a day cell.
  final void Function(DateTime date, int count)? onDayTap;

  const HeatmapWidget({
    super.key,
    required this.year,
    required this.dailyCounts,
    this.onDayTap,
  });

  static const _dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final weeks = buildHeatmapWeeks(year);
    final settings = context.watch<HeatmapSettingsProvider>();
    final cellSize = settings.cellSize.cellSize;
    final gap = settings.cellSize.gap;
    final unit = cellSize + gap;
    final shape = settings.cellShape;
    final totalWidth = weeks.length * unit;
    final colours = resolveHeatmapColours(context, settings.colorTheme);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthRow(weeks: weeks, unit: unit),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayLabelColumn(labels: _dayLabels, unit: unit),
              const SizedBox(width: 4),
              SizedBox(
                width: totalWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weeks.map((week) => _WeekColumn(
                    week: week,
                    dailyCounts: dailyCounts,
                    colours: colours,
                    cellSize: cellSize,
                    gap: gap,
                    shape: shape,
                    onDayTap: onDayTap,
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Legend(colours: colours, cellSize: cellSize, shape: shape),
        ],
      ),
    );
  }

}

/// Builds a list of weeks (each week = list of up to 7 days) for [year].
/// Week starts on Monday. Pads the first and last week with nulls.
/// Top-level (rather than a method on [HeatmapWidget]) so the compact
/// heatmap on the share card can reuse the exact same week grid.
List<List<DateTime?>> buildHeatmapWeeks(int year) {
  final jan1 = DateTime(year, 1, 1);
  final dec31 = DateTime(year, 12, 31);

  // Pad start so week begins on Monday (weekday 1)
  final startPadding = (jan1.weekday - 1) % 7;
  // Pad end so final column is complete
  final endPadding = (7 - dec31.weekday) % 7;

  final allDays = <DateTime?>[
    ...List.filled(startPadding, null),
    ...List.generate(
      dec31.difference(jan1).inDays + 1,
      (i) => jan1.add(Duration(days: i)),
    ),
    ...List.filled(endPadding, null),
  ];

  final weeks = <List<DateTime?>>[];
  for (int i = 0; i < allDays.length; i += 7) {
    weeks.add(allDays.sublist(i, i + 7));
  }
  return weeks;
}

/// Level 0 (no activity) stays a neutral surface-matched tone from the app
/// theme; levels 1–4 come from the user's chosen [HeatmapColorTheme].
/// Shared by the grid, its legend, and the day-detail intensity dot so they
/// always agree on color.
List<Color> resolveHeatmapColours(BuildContext context, HeatmapColorTheme theme) {
  final emptyColor = context.colors.heatmapLevels[0];
  final brightness = Theme.of(context).brightness;
  return [emptyColor, ...theme.ramp(brightness)];
}

class _WeekColumn extends StatelessWidget {
  final List<DateTime?> week;
  final Map<String, int> dailyCounts;
  final List<Color> colours;
  final double cellSize;
  final double gap;
  final HeatmapCellShape shape;
  final void Function(DateTime, int)? onDayTap;

  const _WeekColumn({
    required this.week,
    required this.dailyCounts,
    required this.colours,
    required this.cellSize,
    required this.gap,
    required this.shape,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: Column(
        children: week.map((day) => _DayCell(
          day: day,
          count: day != null ? (dailyCounts[_key(day)] ?? 0) : 0,
          colours: colours,
          cellSize: cellSize,
          gap: gap,
          shape: shape,
          onTap: onDayTap,
        )).toList(),
      ),
    );
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _DayCell extends StatelessWidget {
  final DateTime? day;
  final int count;
  final List<Color> colours;
  final double cellSize;
  final double gap;
  final HeatmapCellShape shape;
  final void Function(DateTime, int)? onTap;

  const _DayCell({
    required this.day,
    required this.count,
    required this.colours,
    required this.cellSize,
    required this.gap,
    required this.shape,
    required this.onTap,
  });

  // Built once for the whole grid rather than per cell — a year's heatmap
  // is 365+ cells, each of which would otherwise construct this twice on
  // every rebuild.
  static final _tooltipDateFmt = DateFormat('MMM d, yyyy');

  int get _intensity {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 10) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return SizedBox(width: cellSize, height: cellSize + gap);
    }

    final colors = context.colors;
    final isFuture = _isFuture(day!);
    final isToday = _isToday(day!);
    final color = isFuture ? Colors.transparent : colours[_intensity];
    final isCircle = shape == HeatmapCellShape.circle;

    return GestureDetector(
      onTap: isFuture ? null : () => onTap?.call(day!, count),
      child: Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: Tooltip(
          message: isFuture
              ? _tooltipDateFmt.format(day!)
              : '${_tooltipDateFmt.format(day!)}: $count transaction${count == 1 ? '' : 's'}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(2),
              border: isFuture
                  ? Border.all(color: colors.heatmapFutureBorder, width: 1)
                  : (isToday
                      ? Border.all(color: colors.heatmapTodayBorder, width: 1)
                      : null),
            ),
          ),
        ),
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool _isFuture(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.isAfter(today);
  }
}

class _MonthRow extends StatelessWidget {
  final List<List<DateTime?>> weeks;
  final double unit;

  const _MonthRow({required this.weeks, required this.unit});

  @override
  Widget build(BuildContext context) {
    final labelColor = context.colors.textTertiary;

    // Place a month label at the first week that starts in that month
    final labels = <Widget>[];
    int? lastMonth;

    for (final week in weeks) {
      final firstDay = week.firstWhere((d) => d != null, orElse: () => null);
      if (firstDay != null && firstDay.month != lastMonth) {
        lastMonth = firstDay.month;
        labels.add(SizedBox(
          width: unit,
          child: Text(
            _monthNames[firstDay.month - 1],
            style: TextStyle(
              fontSize: 9,
              color: labelColor,
            ),
          ),
        ));
      } else {
        labels.add(SizedBox(width: unit));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 30), // align with day grid
      child: Row(children: labels),
    );
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _DayLabelColumn extends StatelessWidget {
  final List<String> labels;
  final double unit;

  const _DayLabelColumn({required this.labels, required this.unit});

  @override
  Widget build(BuildContext context) {
    final labelColor = context.colors.textMuted;
    return Column(
      children: labels.map((label) => SizedBox(
        height: unit,
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 9, color: labelColor),
          ),
        ),
      )).toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<Color> colours;
  final double cellSize;
  final HeatmapCellShape shape;

  const _Legend({required this.colours, required this.cellSize, required this.shape});

  @override
  Widget build(BuildContext context) {
    final labelColor = context.colors.textMuted;
    final isCircle = shape == HeatmapCellShape.circle;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Less', style: TextStyle(fontSize: 9, color: labelColor)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: colours[i],
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 4),
        Text('More', style: TextStyle(fontSize: 9, color: labelColor)),
      ],
    );
  }
}
