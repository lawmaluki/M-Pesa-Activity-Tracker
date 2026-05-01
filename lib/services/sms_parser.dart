import '../models/transaction.dart';

/// Parses M-Pesa SMS messages into structured [MpesaTransaction] objects.
///
/// Handles all major M-Pesa transaction types:
/// - Send Money (to phone / to Paybill / to Buy Goods)
/// - Receive Money
/// - Withdraw Cash
/// - Airtime Purchase
/// - Reversal
class SmsParser {
  // M-Pesa ref always starts with transaction code, e.g. "RHL92ABC12"
  static final _refPattern = RegExp(r'^([A-Z0-9]{10,12})\s+Confirmed', multiLine: false);

  // Amount pattern: Ksh1,234.00 or Ksh1234.00
  static final _amountPattern = RegExp(r'Ksh([\d,]+(?:\.\d{2})?)');

  // Date patterns M-Pesa uses: "1/5/26" or "1/5/2026" or "01/05/2026"
  static final _datePattern = RegExp(
    r'on\s+(\d{1,2}/\d{1,2}/\d{2,4})\s+at\s+(\d{1,2}:\d{2}\s*(?:AM|PM))',
    caseSensitive: false,
  );

  // Balance pattern
  static final _balancePattern = RegExp(
    r'New M-Pesa balance is Ksh([\d,]+(?:\.\d{2})?)',
  );

  // Transaction cost pattern
  static final _costPattern = RegExp(
    r'Transaction cost,\s*Ksh([\d,]+(?:\.\d{2})?)',
  );

  // Counterparty name+phone: "JOHN DOE 0722123456" or just name "SAFARICOM POSTPAY"
  static final _counterpartyPattern = RegExp(
    r'(?:sent to|received from|withdrawn from|paid to)\s+(.+?)\s+(?:on\s+\d)',
    caseSensitive: false,
  );

  static MpesaTransaction? parse(String sms) {
    if (!sms.contains('Confirmed')) return null;

    final refMatch = _refPattern.firstMatch(sms);
    if (refMatch == null) return null;
    final ref = refMatch.group(1)!;

    final amounts = _amountPattern
        .allMatches(sms)
        .map((m) => _parseAmount(m.group(1)!))
        .toList();
    if (amounts.isEmpty) return null;
    final amount = amounts.first;

    final dateMatch = _datePattern.firstMatch(sms);
    final date = dateMatch != null
        ? _parseDate(dateMatch.group(1)!, dateMatch.group(2)!)
        : DateTime.now();

    final balanceMatch = _balancePattern.firstMatch(sms);
    final balance =
        balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : null;

    final costMatch = _costPattern.firstMatch(sms);
    final cost = costMatch != null ? _parseAmount(costMatch.group(1)!) : null;

    final counterpartyMatch = _counterpartyPattern.firstMatch(sms);
    final counterparty = counterpartyMatch?.group(1)?.trim();

    final type = _detectType(sms);

    return MpesaTransaction(
      ref: ref,
      date: date,
      amount: amount,
      type: type,
      counterparty: counterparty,
      balance: balance,
      transactionCost: cost,
      rawSms: sms,
    );
  }

  static TransactionType _detectType(String sms) {
    final lower = sms.toLowerCase();
    if (lower.contains('you have received') ||
        lower.contains('received ksh')) {
      return TransactionType.received;
    }
    if (lower.contains('airtime purchase') || lower.contains('airtime of')) {
      return TransactionType.airtime;
    }
    if (lower.contains('withdrawn from')) {
      return TransactionType.withdrawn;
    }
    if (lower.contains('reversal')) {
      return TransactionType.reversal;
    }
    // "sent to MPESA agent" vs "paid to" — pay bill has numeric account appended
    if (lower.contains('paid to')) {
      return TransactionType.buyGoods;
    }
    // sent to paybill number (6 digits) vs sent to phone
    if (lower.contains('sent to')) {
      // Paybill accounts are numeric-ish business codes; phones start with 07/01/+254
      final paybillPattern = RegExp(r'sent to\s+\S+\s+(\d{5,6})\s+on', caseSensitive: false);
      if (paybillPattern.hasMatch(sms)) return TransactionType.paybill;
      return TransactionType.sent;
    }
    return TransactionType.unknown;
  }

  static double _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime _parseDate(String datePart, String timePart) {
    try {
      final parts = datePart.split('/');
      if (parts.length != 3) return DateTime.now();
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      if (year < 100) year += 2000;

      // Parse time: "2:30 PM"
      final timeClean = timePart.trim().toUpperCase();
      final isPm = timeClean.contains('PM');
      final timeDigits =
          timeClean.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      int hour = int.parse(timeDigits[0]);
      final minute = int.parse(timeDigits[1]);
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Parse multiple SMS messages, returning only successfully parsed ones.
  static List<MpesaTransaction> parseAll(List<String> messages) {
    return messages
        .map(parse)
        .whereType<MpesaTransaction>()
        .toList();
  }

  /// Check if an SMS message looks like an M-Pesa notification.
  static bool isMpesaSms(String body) {
    return body.contains('M-Pesa') ||
        body.contains('MPESA') ||
        (body.contains('Confirmed') && body.contains('Ksh'));
  }
}
