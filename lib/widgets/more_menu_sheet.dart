import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import 'appearance_sheet.dart';
import 'heatmap_customize_sheet.dart';

/// The app's overflow "⋮" menu, redesigned as a rounded bottom-sheet card
/// instead of a stock [PopupMenuButton] dropdown — matches the same
/// language as [AppearanceSheet] and [HeatmapCustomizeSheet] so all three
/// pickers in the app feel like one family instead of a mix of system
/// widgets and custom ones.
class MoreMenuSheet extends StatelessWidget {
  const MoreMenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MoreMenuSheet(),
    );
  }

  static String _appearanceLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title:
            Text('Clear all data?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'This will permanently delete all transactions.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete all', style: TextStyle(color: colors.dangerAccent)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<TransactionProvider>().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mode = context.watch<ThemeProvider>().mode;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Menu',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),
            _MenuRow(
              icon: Icons.brightness_6_outlined,
              iconBg: colors.neutralTintBg,
              iconColor: colors.neutralTintIcon,
              label: 'Appearance',
              trailing: _appearanceLabel(mode),
              onTap: () {
                Navigator.pop(context);
                AppearanceSheet.show(context);
              },
            ),
            const SizedBox(height: 10),
            _MenuRow(
              icon: Icons.palette_outlined,
              iconBg: colors.purpleTintBg,
              iconColor: colors.purpleTintIcon,
              label: 'Customize heatmap',
              onTap: () {
                Navigator.pop(context);
                HeatmapCustomizeSheet.show(context);
              },
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.border),
            const SizedBox(height: 16),
            _MenuRow(
              icon: Icons.delete_forever_outlined,
              iconBg: colors.redTintBg,
              iconColor: colors.dangerAccent,
              label: 'Clear all data',
              labelColor: colors.dangerAccent,
              onTap: () {
                Navigator.pop(context);
                _confirmClear(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor ?? colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: TextStyle(color: colors.textMuted, fontSize: 12.5),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_outlined,
                  color: colors.textFaint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
