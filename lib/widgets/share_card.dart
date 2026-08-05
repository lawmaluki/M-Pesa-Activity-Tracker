import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/heatmap_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/heatmap_theme.dart';
import 'heatmap_widget.dart' show resolveHeatmapColours, buildHeatmapWeeks;

/// The shareable/saveable "year in review" card — title, days-tracked
/// pill, a compact heatmap, and a tilted 2x2 stat grid.
///
/// Fixed width so the exported image looks the same everywhere it's
/// captured; on narrow screens [ShareScreen] scales the *preview* down
/// with a FittedBox, which doesn't affect the resolution of the actual
/// captured PNG (the RepaintBoundary captures this widget's native size).
class ShareCard extends StatelessWidget {
  static const double width = 360;

  final int year;
  final int daysTracked;
  final Map<String, int> dailyCounts;
  final int transactionCount;
  final int longestStreak;
  final double received;
  final double sent;

  const ShareCard({
    super.key,
    required this.year,
    required this.daysTracked,
    required this.dailyCounts,
    required this.transactionCount,
    required this.longestStreak,
    required this.received,
    required this.sent,
  });

  static final _amountFmt = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = context.watch<HeatmapSettingsProvider>();
    final colours = resolveHeatmapColours(context, settings.colorTheme);

    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.brandGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_outlined,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'M-Pesa Tracker',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Title ───────────────────────────────────────────────────
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Money\n',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    height: 1.05,
                  ),
                ),
                TextSpan(
                  text: 'moves ',
                  style: TextStyle(
                    color: colors.accentGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    height: 1.05,
                  ),
                ),
                const TextSpan(text: '✨', style: TextStyle(fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Duration pill ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: colors.textSecondary, size: 13),
                const SizedBox(width: 8),
                Text(
                  '$daysTracked days • $year',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Heatmap ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: _MiniHeatmap(
              year: year,
              dailyCounts: dailyCounts,
              colours: colours,
              shape: settings.cellShape,
            ),
          ),
          const SizedBox(height: 20),

          // ── Stat grid ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _TiltedStat(
                  icon: Icons.swap_horiz_outlined,
                  bg: colors.purpleTintBg,
                  iconColor: colors.purpleTintIcon,
                  value: transactionCount.toString(),
                  label: 'TRANSACTIONS',
                  angle: -0.035,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TiltedStat(
                  icon: Icons.trending_up_outlined,
                  bg: colors.greenTintBg,
                  iconColor: colors.greenTintIcon,
                  value: '$longestStreak days',
                  label: 'LONGEST STREAK',
                  angle: 0.035,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TiltedStat(
                  icon: Icons.arrow_downward_outlined,
                  bg: colors.greenTintBg,
                  iconColor: colors.greenTintIcon,
                  value: 'Ksh ${_amountFmt.format(received)}',
                  label: 'RECEIVED',
                  angle: 0.035,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TiltedStat(
                  icon: Icons.arrow_upward_outlined,
                  bg: colors.purpleTintBg,
                  iconColor: colors.purpleTintIcon,
                  value: 'Ksh ${_amountFmt.format(sent)}',
                  label: 'SENT',
                  angle: -0.035,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Footer ──────────────────────────────────────────────────
          Center(
            child: Text(
              'Tracked with M-Pesa Tracker 💚',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TiltedStat extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final String value;
  final String label;
  final double angle;

  const _TiltedStat({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small, static (non-interactive) render of the activity heatmap —
/// same week grid, color theme, and cell shape as the main screen's
/// [HeatmapWidget] (via [resolveHeatmapColours]/[buildHeatmapWeeks]/
/// [HeatmapCellShape]), just sized to fit inside the fixed-width card.
class _MiniHeatmap extends StatelessWidget {
  final int year;
  final Map<String, int> dailyCounts;
  final List<Color> colours;
  final HeatmapCellShape shape;

  const _MiniHeatmap({
    required this.year,
    required this.dailyCounts,
    required this.colours,
    required this.shape,
  });

  static const _cellSize = 4.0;
  static const _gap = 1.0;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static int _intensity(int count) {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 10) return 3;
    return 4;
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weeks = buildHeatmapWeeks(year);
    final unit = _cellSize + _gap;
    final isCircle = shape == HeatmapCellShape.circle;

    final monthLabels = <Widget>[];
    int? lastMonth;
    for (final week in weeks) {
      final firstDay = week.firstWhere((d) => d != null, orElse: () => null);
      if (firstDay != null && firstDay.month != lastMonth) {
        lastMonth = firstDay.month;
        monthLabels.add(SizedBox(
          width: unit,
          child: Text(
            _monthNames[firstDay.month - 1],
            style: TextStyle(fontSize: 6.5, color: colors.textFaint),
          ),
        ));
      } else {
        monthLabels.add(SizedBox(width: unit));
      }
    }

    Widget cell(DateTime? day) {
      final count = day != null ? (dailyCounts[_key(day)] ?? 0) : 0;
      final color =
          day == null ? Colors.transparent : colours[_intensity(count)];
      return Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(1),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 13),
          child: Row(children: monthLabels),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: _dayLabels
                  .map((l) => SizedBox(
                        width: 10,
                        height: unit,
                        child: Center(
                          child: Text(
                            l,
                            style: TextStyle(
                                fontSize: 6.5, color: colors.textFaint),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 3),
            ...weeks.map((week) => Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Column(children: week.map(cell).toList()),
                )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Less',
                style: TextStyle(fontSize: 7, color: colors.textFaint)),
            const SizedBox(width: 4),
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  width: _cellSize,
                  height: _cellSize,
                  decoration: BoxDecoration(
                    color: colours[i],
                    shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isCircle ? null : BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Text('More',
                style: TextStyle(fontSize: 7, color: colors.textFaint)),
          ],
        ),
      ],
    );
  }
}
