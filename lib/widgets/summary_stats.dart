import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  static final _fmt = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Transactions',
          value: totalTransactions.toString(),
          icon: Icons.swap_horiz_rounded,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: 'Spent',
          value: 'Ksh ${_fmt.format(totalSpent)}',
          icon: Icons.arrow_upward_rounded,
          color: Colors.white70,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: 'Received',
          value: 'Ksh ${_fmt.format(totalReceived)}',
          icon: Icons.arrow_downward_rounded,
          color: const Color(0xFF4CD964),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
