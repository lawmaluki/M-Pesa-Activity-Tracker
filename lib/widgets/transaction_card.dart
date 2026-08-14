import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

class TransactionCard extends StatelessWidget {
  final MpesaTransaction transaction;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCredit = transaction.type.isCredit;
    final amountColor = isCredit ? colors.accentGreen : colors.textPrimary;

    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.ref),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.dangerAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colors.dangerAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text('Delete transaction?',
                style: TextStyle(color: colors.textPrimary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: colors.dangerAccent)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _TypeIcon(type: transaction.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.type.label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (transaction.counterparty != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.counterparty!,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    transaction.ref,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ${Money.exact(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeFmt.format(transaction.date),
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final TransactionType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, iconColor) = _iconData(type, context.colors);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  static (IconData, Color, Color) _iconData(
      TransactionType type, AppColors colors) {
    switch (type) {
      case TransactionType.sent:
        return (
          Icons.arrow_upward_outlined,
          colors.redTintBg,
          colors.redTintIcon,
        );
      case TransactionType.received:
        return (
          Icons.arrow_downward_outlined,
          colors.greenTintBg,
          colors.greenTintIcon,
        );
      case TransactionType.withdrawn:
        return (
          Icons.atm_outlined,
          colors.amberTintBg,
          colors.amberTintIcon,
        );
      case TransactionType.paybill:
        return (
          Icons.receipt_long_outlined,
          colors.blueTintBg,
          colors.blueTintIcon,
        );
      case TransactionType.buyGoods:
        return (
          Icons.shopping_bag_outlined,
          colors.purpleTintBg,
          colors.purpleTintIcon,
        );
      case TransactionType.airtime:
        return (
          Icons.phone_android_outlined,
          colors.yellowTintBg,
          colors.yellowTintIcon,
        );
      case TransactionType.reversal:
        return (
          Icons.undo_outlined,
          colors.reversalTintBg,
          colors.reversalTintIcon,
        );
      case TransactionType.unknown:
        return (
          Icons.swap_horiz_outlined,
          colors.neutralTintBg,
          colors.neutralTintIcon,
        );
    }
  }
}
