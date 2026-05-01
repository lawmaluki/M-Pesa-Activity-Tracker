import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime date;

  const DayDetailScreen({super.key, required this.date});

  static final _dateFmt = DateFormat('EEEE, MMMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
            return const Center(
              child: Text(
                'No transactions on this day.',
                style: TextStyle(color: Colors.white38),
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
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
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

  static final _fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4D2E), Color(0xFF0F2C1A)],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Intensity ${summary.intensity}/4',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Received',
                value: 'Ksh ${_fmt.format(summary.totalCredited)}',
                color: const Color(0xFF4CD964),
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Spent',
                value: 'Ksh ${_fmt.format(summary.totalDebited)}',
                color: Colors.white70,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Net',
                value:
                    '${summary.netFlow >= 0 ? '+' : ''}Ksh ${_fmt.format(summary.netFlow.abs())}',
                color: summary.netFlow >= 0
                    ? const Color(0xFF4CD964)
                    : Colors.red.shade300,
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
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
