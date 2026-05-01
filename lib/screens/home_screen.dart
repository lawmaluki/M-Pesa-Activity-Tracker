import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/sms_service.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/summary_stats.dart';
import '../widgets/transaction_card.dart';
import 'import_screen.dart';
import 'day_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadData();
      _startSmsListener();
    });
  }

  void _startSmsListener() async {
    final granted = await SmsService.hasPermission();
    if (!granted || !mounted) return;
    SmsService.startListening((tx) {
      if (!mounted) return;
      context.read<TransactionProvider>().onNewTransaction(tx);
    });
  }

  Future<void> _syncSms() async {
    final provider = context.read<TransactionProvider>();
    final granted = await SmsService.requestPermissions();
    if (!mounted) return;

    if (!granted) {
      _showSnack('SMS permission denied. Grant it in Settings to auto-sync.');
      return;
    }

    final result = await provider.syncSms();
    if (!mounted) return;

    _showSnack(result.message);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(provider),
                if (provider.state == LoadState.loading)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      color: Color(0xFF4CD964),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _YearSelector(
                          year: provider.selectedYear,
                          onChanged: provider.setSelectedYear,
                        ),
                        const SizedBox(height: 16),
                        _HeatmapSection(provider: provider),
                        const SizedBox(height: 20),
                        SummaryStats(
                          totalTransactions: provider.totalTransactions,
                          totalSpent: provider.totalSpent,
                          totalReceived: provider.totalReceived,
                        ),
                        const SizedBox(height: 24),
                        _RecentHeader(
                          selectedDay: provider.selectedDay,
                          onClear: () => provider.selectDay(null),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _buildTransactionList(provider),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportScreen()),
        ),
        backgroundColor: const Color(0xFF25A244),
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Import', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  SliverAppBar _buildAppBar(TransactionProvider provider) {
    return SliverAppBar(
      backgroundColor: Colors.black,
      pinned: true,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF25A244),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'M-Pesa Tracker',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync_rounded, color: Colors.white70),
          tooltip: 'Sync SMS',
          onPressed: provider.state == LoadState.loading ? null : _syncSms,
        ),
        PopupMenuButton<String>(
          color: const Color(0xFF2C2C2E),
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
          onSelected: (value) async {
            if (value == 'clear') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  title: const Text('Clear all data?'),
                  content: const Text(
                    'This will permanently delete all transactions.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete all',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await context.read<TransactionProvider>().clearAll();
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded,
                      color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Clear all data',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    final txs = provider.selectedDay != null
        ? provider.selectedDayTransactions
        : provider.transactions;

    if (txs.isEmpty && provider.state == LoadState.idle) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded,
                  size: 56, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              const Text(
                'No transactions yet',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap Import or sync your SMS to get started.',
                style: TextStyle(color: Colors.white24, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
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
    );
  }
}

class _HeatmapSection extends StatelessWidget {
  final TransactionProvider provider;

  const _HeatmapSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (provider.selectedDay != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DayDetailScreen(date: provider.selectedDay!),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          HeatmapWidget(
            year: provider.selectedYear,
            dailyCounts: provider.dailyCounts,
            onDayTap: (date, count) {
              provider.selectDay(date);
              if (count > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayDetailScreen(date: date),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final void Function(int) onChanged;

  const _YearSelector({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
          onPressed:
              year > currentYear - 5 ? () => onChanged(year - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Text(
          year.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          onPressed: year < currentYear ? () => onChanged(year + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _RecentHeader extends StatelessWidget {
  final DateTime? selectedDay;
  final VoidCallback onClear;

  const _RecentHeader({required this.selectedDay, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          selectedDay != null
              ? 'Transactions on ${_fmt(selectedDay!)}'
              : 'Recent Transactions',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (selectedDay != null)
          GestureDetector(
            onTap: onClear,
            child: const Text(
              'Show all',
              style: TextStyle(color: Color(0xFF4CD964), fontSize: 13),
            ),
          ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
