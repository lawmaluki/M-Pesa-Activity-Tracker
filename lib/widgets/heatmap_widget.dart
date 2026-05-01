import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GitHub-style contribution heatmap for M-Pesa transaction activity.
///
/// Renders a 53-week grid (columns = weeks, rows = Mon–Sun).
/// Each cell is coloured by [intensityFor] — 0 = no activity, 4 = very high.
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

  // Safaricom green palette — 5 levels (0 = empty, 1–4 = intensity)
  static const _colours = [
    Color(0xFF1C1C1E), // level 0 — empty (dark surface)
    Color(0xFF0A3D1F), // level 1 — very light green
    Color(0xFF1A6B38), // level 2
    Color(0xFF25A244), // level 3
    Color(0xFF4CD964), // level 4 — brightest
  ];

  static const _cellSize = 11.0;
  static const _gap = 2.0;
  static const _unit = _cellSize + _gap;

  static const _dayLabels = ['', 'Tue', '', 'Thu', '', 'Sat', ''];

  @override
  Widget build(BuildContext context) {
    final weeks = _buildWeeks(year);
    final totalWidth = weeks.length * _unit;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthRow(weeks: weeks, unit: _unit),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayLabelColumn(labels: _dayLabels, unit: _unit),
              const SizedBox(width: 4),
              SizedBox(
                width: totalWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: weeks.map((week) => _WeekColumn(
                    week: week,
                    dailyCounts: dailyCounts,
                    colours: _colours,
                    cellSize: _cellSize,
                    gap: _gap,
                    onDayTap: onDayTap,
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Legend(colours: _colours, cellSize: _cellSize),
        ],
      ),
    );
  }

  /// Builds a list of weeks (each week = list of up to 7 days).
  /// Week starts on Monday. Pads the first and last week with nulls.
  static List<List<DateTime?>> _buildWeeks(int year) {
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
}

class _WeekColumn extends StatelessWidget {
  final List<DateTime?> week;
  final Map<String, int> dailyCounts;
  final List<Color> colours;
  final double cellSize;
  final double gap;
  final void Function(DateTime, int)? onDayTap;

  const _WeekColumn({
    required this.week,
    required this.dailyCounts,
    required this.colours,
    required this.cellSize,
    required this.gap,
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
  final void Function(DateTime, int)? onTap;

  const _DayCell({
    required this.day,
    required this.count,
    required this.colours,
    required this.cellSize,
    required this.gap,
    required this.onTap,
  });

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

    final color = colours[_intensity];
    final isToday = _isToday(day!);

    return GestureDetector(
      onTap: () => onTap?.call(day!, count),
      child: Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: Tooltip(
          message: '${DateFormat('MMM d, yyyy').format(day!)}: $count transaction${count == 1 ? '' : 's'}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: isToday
                  ? Border.all(color: Colors.white54, width: 1)
                  : null,
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
}

class _MonthRow extends StatelessWidget {
  final List<List<DateTime?>> weeks;
  final double unit;

  const _MonthRow({required this.weeks, required this.unit});

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white54,
            ),
          ),
        ));
      } else {
        labels.add(SizedBox(width: unit));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 22), // align with day grid
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
    return Column(
      children: labels.map((label) => SizedBox(
        height: unit,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.white38),
          ),
        ),
      )).toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<Color> colours;
  final double cellSize;

  const _Legend({required this.colours, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Less', style: TextStyle(fontSize: 9, color: Colors.white38)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: colours[i],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 9, color: Colors.white38)),
      ],
    );
  }
}
