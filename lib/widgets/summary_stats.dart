import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/money.dart';

class SummaryStats extends StatelessWidget {
  final int totalTransactions;
  final double totalSpent;
  final double totalReceived;

  const SummaryStats({
    super.key,
    required this.totalTransactions,
    required this.totalSpent,
    required this.totalReceived,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatTile(
          label: 'Transactions',
          value: totalTransactions.toString(),
          icon: Icons.swap_horiz_outlined,
          iconColor: colors.greenTintIcon,
          iconBg: colors.greenTintBg,
          highlighted: true,
          gradientBegin: Alignment.centerRight,
          gradientEnd: Alignment.centerLeft,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Spent',
          value: Money.whole(totalSpent),
          icon: Icons.arrow_upward_outlined,
          iconColor: colors.redTintIcon,
          iconBg: colors.redTintBg,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: 'Received',
          value: Money.whole(totalReceived),
          icon: Icons.arrow_downward_outlined,
          iconColor: colors.greenTintIcon,
          iconBg: colors.greenTintBg,
          highlighted: true,
          gradientBegin: Alignment.centerLeft,
          gradientEnd: Alignment.centerRight,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool highlighted;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.highlighted = false,
    this.gradientBegin = Alignment.centerLeft,
    this.gradientEnd = Alignment.centerRight,
  });

  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          highlighted ? _borderRadius - 1 : _borderRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );

    if (!highlighted) {
      return Expanded(child: card);
    }

    // Fine, light gradient border — a subtle ring that fades from a soft
    // green tint into the card's own background tone.
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          gradient: LinearGradient(
            begin: gradientBegin,
            end: gradientEnd,
            colors: [
              colors.surface.withValues(alpha: 0.0),
              colors.accentGreen.withValues(alpha: 0.35),
            ],
          ),
        ),
        child: card,
      ),
    );
  }
}
