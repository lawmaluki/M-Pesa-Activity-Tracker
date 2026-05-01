import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final MpesaTransaction transaction;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  static final _amountFmt = NumberFormat('#,##0.00');
  static final _timeFmt = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.isCredit;
    final amountColor = isCredit ? const Color(0xFF4CD964) : Colors.white;

    return Dismissible(
      key: ValueKey(transaction.id ?? transaction.ref),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            title: const Text('Delete transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
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
          color: const Color(0xFF2C2C2E),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (transaction.counterparty != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.counterparty!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    transaction.ref,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} Ksh ${_amountFmt.format(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeFmt.format(transaction.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
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
    final (icon, bg) = _iconData(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  static (IconData, Color) _iconData(TransactionType type) {
    switch (type) {
      case TransactionType.sent:
        return (Icons.arrow_upward_rounded, const Color(0xFF3A3A3C));
      case TransactionType.received:
        return (Icons.arrow_downward_rounded, const Color(0xFF1A4D2E));
      case TransactionType.withdrawn:
        return (Icons.atm_rounded, const Color(0xFF3A2C1A));
      case TransactionType.paybill:
        return (Icons.receipt_long_rounded, const Color(0xFF1A2D4D));
      case TransactionType.buyGoods:
        return (Icons.shopping_bag_rounded, const Color(0xFF2D1A4D));
      case TransactionType.airtime:
        return (Icons.phone_android_rounded, const Color(0xFF2D2D1A));
      case TransactionType.reversal:
        return (Icons.undo_rounded, const Color(0xFF4D1A1A));
      case TransactionType.unknown:
        return (Icons.swap_horiz_rounded, const Color(0xFF3A3A3C));
    }
  }
}
