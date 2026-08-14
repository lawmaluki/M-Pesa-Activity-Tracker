import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

/// Modern bottom-sheet picker for System/Light/Dark appearance — replaces
/// the plain system-style AlertDialog + radio list with the same rounded
/// card + tappable-row language used by [HeatmapCustomizeSheet], so the two
/// pickers in the app feel like they belong together.
class AppearanceSheet extends StatelessWidget {
  const AppearanceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AppearanceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final themeProvider = context.watch<ThemeProvider>();

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
              'Appearance',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how M-Pesa Tracker looks on your device.',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            _AppearanceTile(
              icon: Icons.brightness_auto_outlined,
              label: 'System default',
              subtitle: 'Matches your device setting',
              selected: themeProvider.mode == ThemeMode.system,
              onTap: () {
                themeProvider.setMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _AppearanceTile(
              icon: Icons.light_mode_outlined,
              label: 'Light',
              subtitle: 'Bright background, dark text',
              selected: themeProvider.mode == ThemeMode.light,
              onTap: () {
                themeProvider.setMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            _AppearanceTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              subtitle: 'Dark background, light text',
              selected: themeProvider.mode == ThemeMode.dark,
              onTap: () {
                themeProvider.setMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected
          ? colors.accentGreen.withValues(alpha: 0.10)
          : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.accentGreen : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.accentGreen.withValues(alpha: 0.18)
                      : colors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.accentGreen : colors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style:
                          TextStyle(color: colors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colors.accentGreen : colors.textFaint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
