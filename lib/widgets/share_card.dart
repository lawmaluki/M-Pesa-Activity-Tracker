import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/heatmap_settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/heatmap_theme.dart';
import '../utils/money.dart';
import 'heatmap_widget.dart' show resolveHeatmapColours, buildHeatmapWeeks;

/// The shareable/saveable "year in review" card — title, days-tracked
/// pill, a compact heatmap, and a tilted 2x2 stat grid.
///
/// [width] is computed by [ShareScreen] from the available screen space
/// (rather than hardcoded) so the card sits edge-to-edge with sensible
/// margins on any device instead of overflowing narrow ones or leaving
/// odd gaps on wide ones — and so the heatmap grid below always has the
/// most room possible to render its cells at a legible size.
class ShareCard extends StatelessWidget {
  final double width;
  final int year;
  final int daysTracked;
  final Map<String, int> dailyCounts;
  final int transactionCount;
  final int longestStreak;
  final double received;
  final double sent;

  const ShareCard({
    super.key,
    required this.width,
    required this.year,
    required this.daysTracked,
    required this.dailyCounts,
    required this.transactionCount,
    required this.longestStreak,
    required this.received,
    required this.sent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = context.watch<HeatmapSettingsProvider>();
    final colours = resolveHeatmapColours(context, settings.colorTheme);

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
          const SizedBox(height: 18),

          // ── Title ───────────────────────────────────────────────────
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Money ',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.05,
                  ),
                ),
                TextSpan(
                  text: 'moves ',
                  style: TextStyle(
                    color: colors.accentGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    height: 1.05,
                  ),
                ),
                const TextSpan(text: '✨', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 16),

          // ── Heatmap — the whole point of the share, give it the room ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.accentGreen.withValues(alpha: 0.35)),
            ),
            child: _MiniHeatmap(
              year: year,
              dailyCounts: dailyCounts,
              colours: colours,
              emptyColor: colors.border,
              shape: settings.cellShape,
            ),
          ),
          const SizedBox(height: 18),

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
                  value: Money.compact(received),
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
                  value: Money.compact(sent),
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

/// A small, static (non-interactive) render of the activity heatmap — same
/// week grid, color theme, and cell shape as the main screen's
/// [HeatmapWidget] (via [resolveHeatmapColours]/[buildHeatmapWeeks]/
/// [HeatmapCellShape]).
///
/// Cell size isn't a fixed constant — it's derived from whatever width
/// [LayoutBuilder] reports for its housing container, so the grid always
/// fills the space it's given edge-to-edge and cells are as large (and
/// legible) as the container allows, rather than a cramped fixed size.
class _MiniHeatmap extends StatelessWidget {
  final int year;
  final Map<String, int> dailyCounts;
  final List<Color> colours;
  final Color emptyColor;
  final HeatmapCellShape shape;

  const _MiniHeatmap({
    required this.year,
    required this.dailyCounts,
    required this.colours,
    required this.emptyColor,
    required this.shape,
  });

  static const _gap = 0.8;
  static const _dayLabelWidth = 8.0;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  // First-letter-only month labels — plenty to place the grid in time at
  // this scale, and they don't overflow the narrow per-week columns the
  // way "Jan"/"Feb" full names did.
  static const _monthNames = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
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
    final isCircle = shape == HeatmapCellShape.circle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - _dayLabelWidth;
        final unit = gridWidth / weeks.length;
        final cellSize = (unit - _gap).clamp(4.0, 14.0);
        final cellRadius = (cellSize * 0.3).clamp(0.6, 3.0);
        final labelFontSize = (cellSize * 1.4).clamp(7.5, 11.0);

        final monthLabels = <Widget>[];
        int? lastMonth;
        for (final week in weeks) {
          final firstDay =
              week.firstWhere((d) => d != null, orElse: () => null);
          if (firstDay != null && firstDay.month != lastMonth) {
            lastMonth = firstDay.month;
            monthLabels.add(SizedBox(
              width: unit,
              child: Text(
                _monthNames[firstDay.month - 1],
                style: TextStyle(fontSize: labelFontSize, color: colors.textFaint),
              ),
            ));
          } else {
            monthLabels.add(SizedBox(width: unit));
          }
        }

        Widget cell(DateTime? day) {
          final count = day != null ? (dailyCounts[_key(day)] ?? 0) : 0;
          final level = day == null ? -1 : _intensity(count);
          final color = level < 0
              ? Colors.transparent
              : (level == 0 ? emptyColor : colours[level]);
          return Padding(
            padding: const EdgeInsets.only(bottom: _gap),
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: color,
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(cellRadius),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: _dayLabelWidth),
              child: Row(children: monthLabels),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _dayLabelWidth,
                  child: Column(
                    children: _dayLabels
                        .map((l) => SizedBox(
                              height: unit,
                              child: Center(
                                child: Text(
                                  l,
                                  style: TextStyle(
                                      fontSize: labelFontSize,
                                      color: colors.textFaint),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                ...weeks.map((week) => Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: Column(children: week.map(cell).toList()),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Less',
                    style:
                        TextStyle(fontSize: labelFontSize, color: colors.textFaint)),
                const SizedBox(width: 5),
                ...List.generate(
                  5,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 2.5),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: i == 0 ? emptyColor : colours[i],
                        shape:
                            isCircle ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius:
                            isCircle ? null : BorderRadius.circular(cellRadius),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Text('More',
                    style:
                        TextStyle(fontSize: labelFontSize, color: colors.textFaint)),
              ],
            ),
          ],
        );
      },
    );
  }
}
