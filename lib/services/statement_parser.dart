import 'package:csv/csv.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';

/// Parses M-Pesa statement exports (CSV from the M-Pesa app/Safaricom portal)
/// and pasted raw SMS text blocks.
class StatementParser {
  // M-Pesa statement CSV column indices (official export format)
  static const _colReceipt = 0;
  static const _colDate = 1;
  static const _colDetails = 2;
  static const _colStatus = 3;
  static const _colPaidIn = 4;
  static const _colWithdrawn = 5;
  // ignore: unused_field
  static const _colBalance = 6;

  /// Parse an M-Pesa CSV statement (exported from M-Pesa app or web portal).
  ///
  /// Expected columns:
  /// Receipt No., Completion Time, Details, Transaction Status,
  /// Paid In, Withdrawn, Balance
  static ParseResult parseCSV(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n').convert(csvContent);
    if (rows.length < 2) {
      return ParseResult(transactions: [], errors: ['Empty or invalid CSV']);
    }

    // Find the header row (skip leading metadata rows Safaricom sometimes adds)
    int headerIndex = 0;
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty &&
          row[0].toString().toLowerCase().contains('receipt')) {
        headerIndex = i;
        break;
      }
    }

    final transactions = <MpesaTransaction>[];
    final errors = <String>[];

    for (int i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;

      try {
        final ref = row[_colReceipt].toString().trim();
        if (ref.isEmpty || ref.toLowerCase() == 'receipt no.') continue;

        final dateStr = row[_colDate].toString().trim();
        final date = _parseCsvDate(dateStr);
        if (date == null) continue;

        final details = row[_colDetails].toString().trim();
        final status = row[_colStatus].toString().trim().toLowerCase();
        if (!status.contains('complet')) continue; // skip failed/reversed

        final paidInStr = row[_colPaidIn].toString().trim();
        final withdrawnStr = row[_colWithdrawn].toString().trim();

        final paidIn = _parseAmount(paidInStr);
        final withdrawn = _parseAmount(withdrawnStr);

        if (paidIn == 0 && withdrawn == 0) continue;

        final isCredit = paidIn > 0;
        final amount = isCredit ? paidIn : withdrawn;
        final type = _inferTypeFromDetails(details, isCredit);

        transactions.add(MpesaTransaction(
          ref: ref,
          date: date,
          amount: amount,
          type: type,
          counterparty: _extractCounterparty(details),
          rawSms: 'CSV Import: $details',
        ));
      } catch (e) {
        errors.add('Row $i: $e');
      }
    }

    return ParseResult(transactions: transactions, errors: errors);
  }

  /// Parse a block of pasted raw SMS text (one message per line or blank-line separated).
  static ParseResult parsePastedSms(String text) {
    // Split on double newlines (message blocks) or try single-message lines
    final blocks = text
        .split(RegExp(r'\n{2,}'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    // If no double-newline separators, try to split by M-Pesa ref pattern
    final allMessages = blocks.length == 1
        ? _splitByRef(text)
        : blocks;

    final parsed = SmsParser.parseAll(allMessages);
    final errors = <String>[];
    if (parsed.isEmpty && allMessages.isNotEmpty) {
      errors.add('No valid M-Pesa transactions found in the pasted text. '
          'Make sure you paste the full SMS content.');
    }

    return ParseResult(transactions: parsed, errors: errors);
  }

  static List<String> _splitByRef(String text) {
    final refRegex = RegExp(r'(?=[A-Z0-9]{10,12}\s+Confirmed)');
    final parts = text.split(refRegex).where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts : [text];
  }

  static DateTime? _parseCsvDate(String raw) {
    if (raw.isEmpty) return null;
    try {
      // Format: "2026-01-15 10:30:00" or "15/01/2026 10:30"
      if (raw.contains('-')) {
        return DateTime.parse(raw);
      }
      // DD/MM/YYYY HH:MM[:SS]
      final parts = raw.split(' ');
      final dateParts = parts[0].split('/');
      if (dateParts.length < 3) return null;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      int hour = 0, minute = 0;
      if (parts.length > 1) {
        final timeParts = parts[1].split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static double _parseAmount(String raw) {
    if (raw.isEmpty) return 0;
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  static TransactionType _inferTypeFromDetails(String details, bool isCredit) {
    final lower = details.toLowerCase();
    if (isCredit) {
      if (lower.contains('reversal')) return TransactionType.reversal;
      return TransactionType.received;
    }
    if (lower.contains('airtime') || lower.contains('bundles')) {
      return TransactionType.airtime;
    }
    if (lower.contains('withdraw') || lower.contains('agent')) {
      return TransactionType.withdrawn;
    }
    if (lower.contains('paybill') || lower.contains('pay bill') ||
        lower.contains('utility') || lower.contains('business')) {
      return TransactionType.paybill;
    }
    if (lower.contains('merchant') || lower.contains('till') ||
        lower.contains('buy goods') || lower.contains('lipa')) {
      return TransactionType.buyGoods;
    }
    if (lower.contains('transfer') || lower.contains('sent')) {
      return TransactionType.sent;
    }
    return TransactionType.unknown;
  }

  static String? _extractCounterparty(String details) {
    // "Customer Transfer to JOHN DOE 0722000000" → "JOHN DOE 0722000000"
    final patterns = [
      RegExp(r'(?:to|from|at)\s+(.+?)(?:\s+\d{6,}|\s*$)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(details);
      if (match != null) return match.group(1)?.trim();
    }
    return details.isNotEmpty ? details : null;
  }
}

class ParseResult {
  final List<MpesaTransaction> transactions;
  final List<String> errors;

  const ParseResult({required this.transactions, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  int get count => transactions.length;
}
