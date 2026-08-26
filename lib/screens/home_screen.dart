import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/more_menu_sheet.dart';
import '../widgets/summary_stats.dart';
import '../widgets/transaction_card.dart';
import 'import_screen.dart';
import 'day_detail_screen.dart';
import 'share_screen.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(provider),
                if (provider.state == LoadState.loading)
                  SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      color: colors.accentGreen,
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
        backgroundColor: colors.brandGreen,
        icon: const Icon(Icons.upload_file_outlined, color: Colors.white),
        label: const Text('Import', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  SliverAppBar _buildAppBar(TransactionProvider provider) {
    final colors = context.colors;
    return SliverAppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      pinned: true,
      toolbarHeight: 64,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.brandGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'M-Pesa Tracker',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track. Analyze. Take Control.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _CircleIconButton(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onPressed: () => ShareScreen.show(context),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Icons.more_vert_outlined,
          tooltip: 'Menu',
          onPressed: () => MoreMenuSheet.show(context),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    final colors = context.colors;
    final txs = provider.selectedDay != null
        ? provider.selectedDayTransactions
        : provider.transactions;

    if (txs.isEmpty && provider.state == LoadState.idle) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 56, color: colors.textPrimary.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(color: colors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Import or sync your SMS to get started.',
                style: TextStyle(color: colors.textFaint, fontSize: 13),
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
    final colors = context.colors;
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
          Text(
            'Activity',
            style: TextStyle(
              color: colors.textPrimary,
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final String? tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedColor = iconColor ?? colors.textSecondary;
    final button = Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? resolvedColor.withValues(alpha: 0.3)
                : resolvedColor,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final void Function(int) onChanged;

  const _YearSelector({required this.year, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentYear = DateTime.now().year;
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.chevron_left_outlined,
          onPressed:
              year > currentYear - 5 ? () => onChanged(year - 1) : null,
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                year.toString(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_outlined,
                  color: colors.textTertiary, size: 20),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.chevron_right_outlined,
          onPressed: year < currentYear ? () => onChanged(year + 1) : null,
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
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          selectedDay != null
              ? 'Transactions on ${_fmt(selectedDay!)}'
              : 'Recent Transactions',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Text(
            'View all',
            style: TextStyle(
              color: colors.accentGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
