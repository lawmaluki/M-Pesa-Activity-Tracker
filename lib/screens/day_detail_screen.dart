import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/heatmap_settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';
import '../theme/heatmap_theme.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/transaction_card.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime date;

  const DayDetailScreen({super.key, required this.date});

  static final _dateFmt = DateFormat('EEEE, MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: Text(
          _dateFmt.format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final txs = _transactionsForDay(provider, date);
          final summary = DaySummary(date: date, transactions: txs);

          if (txs.isEmpty) {
            return Center(
              child: Text(
                'No transactions on this day.',
                style: TextStyle(color: colors.textMuted),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _DaySummaryCard(summary: summary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '${txs.length} transaction${txs.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: colors.textTertiary, fontSize: 13),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = txs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionCard(
                        transaction: tx,
                        onDelete: tx.id != null
                            ? () => provider.deleteTransaction(tx.id!)
                            : null,
                      ),
                    );
                  },
                  childCount: txs.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  List<MpesaTransaction> _transactionsForDay(
      TransactionProvider provider, DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return provider.transactions
        .where((t) => t.dateKey == key)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

class _DaySummaryCard extends StatelessWidget {
  final DaySummary summary;

  const _DaySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = context.watch<HeatmapSettingsProvider>();
    final levelColours = resolveHeatmapColours(context, settings.colorTheme);
    final dotColor = levelColours[summary.intensity.clamp(0, 4)];
    final isCircleShape = settings.cellShape == HeatmapCellShape.circle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.successBg, colors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: isCircleShape
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        borderRadius:
                            isCircleShape ? null : BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Intensity ${summary.intensity}/4',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Received',
                value: Money.exact(summary.totalCredited),
                color: colors.accentGreen,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Spent',
                value: Money.exact(summary.totalDebited),
                color: colors.textSecondary,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Net',
                value:
                    '${summary.netFlow >= 0 ? '+' : '-'}${Money.exact(summary.netFlow.abs())}',
                color: summary.netFlow >= 0
                    ? colors.accentGreen
                    : colors.dangerText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
