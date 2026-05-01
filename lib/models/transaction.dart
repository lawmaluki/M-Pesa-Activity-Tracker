import 'package:intl/intl.dart';

enum TransactionType {
  sent,
  received,
  withdrawn,
  paybill,
  buyGoods,
  airtime,
  reversal,
  unknown,
}

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.sent:
        return 'Sent';
      case TransactionType.received:
        return 'Received';
      case TransactionType.withdrawn:
        return 'Withdrawn';
      case TransactionType.paybill:
        return 'Pay Bill';
      case TransactionType.buyGoods:
        return 'Buy Goods';
      case TransactionType.airtime:
        return 'Airtime';
      case TransactionType.reversal:
        return 'Reversal';
      case TransactionType.unknown:
        return 'Other';
    }
  }

  bool get isCredit =>
      this == TransactionType.received || this == TransactionType.reversal;

  String get dbValue => name;

  static TransactionType fromDb(String value) =>
      TransactionType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TransactionType.unknown,
      );
}

class MpesaTransaction {
  final int? id;
  final String ref;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String? counterparty;
  final double? balance;
  final double? transactionCost;
  final String rawSms;

  const MpesaTransaction({
    this.id,
    required this.ref,
    required this.date,
    required this.amount,
    required this.type,
    this.counterparty,
    this.balance,
    this.transactionCost,
    required this.rawSms,
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'ref': ref,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type.dbValue,
        'counterparty': counterparty,
        'balance': balance,
        'transaction_cost': transactionCost,
        'raw_sms': rawSms,
      };

  factory MpesaTransaction.fromMap(Map<String, dynamic> map) =>
      MpesaTransaction(
        id: map['id'] as int?,
        ref: map['ref'] as String,
        date: DateTime.parse(map['date'] as String),
        amount: (map['amount'] as num).toDouble(),
        type: TransactionTypeX.fromDb(map['type'] as String),
        counterparty: map['counterparty'] as String?,
        balance: map['balance'] != null
            ? (map['balance'] as num).toDouble()
            : null,
        transactionCost: map['transaction_cost'] != null
            ? (map['transaction_cost'] as num).toDouble()
            : null,
        rawSms: map['raw_sms'] as String,
      );

  MpesaTransaction copyWith({int? id}) => MpesaTransaction(
        id: id ?? this.id,
        ref: ref,
        date: date,
        amount: amount,
        type: type,
        counterparty: counterparty,
        balance: balance,
        transactionCost: transactionCost,
        rawSms: rawSms,
      );
}

class DaySummary {
  final DateTime date;
  final List<MpesaTransaction> transactions;

  const DaySummary({required this.date, required this.transactions});

  int get count => transactions.length;

  double get totalDebited => transactions
      .where((t) => !t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalCredited => transactions
      .where((t) => t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  double get netFlow => totalCredited - totalDebited;

  // intensity 0–4 for heatmap colour levels
  int get intensity {
    if (count == 0) return 0;
    if (count <= 2) return 1;
    if (count <= 5) return 2;
    if (count <= 10) return 3;
    return 4;
  }
}
