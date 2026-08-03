import 'package:pdfrx/pdfrx.dart';

import '../models/transaction.dart';
import 'statement_parser.dart';

/// Called after each page's text has been extracted. `page` is 1-based.
typedef PdfImportProgress = void Function(int page, int totalPages);

/// Thrown when the PDF couldn't be opened — most commonly a wrong password.
class PdfImportException implements Exception {
  final String message;
  final bool isPasswordError;

  const PdfImportException(this.message, {this.isPasswordError = false});

  @override
  String toString() => message;
}

/// Parses a password-protected M-Pesa statement PDF (the real export from
/// the M-Pesa app, not a flattened/scanned copy) and hands off to the
/// existing [StatementParser.parseCSV] logic — no business logic is
/// duplicated here. This file only:
///
///   1. Opens + decrypts the PDF and pulls text out of every page.
///   2. Reconstructs the "Receipt No. / Completion Time / Details /
///      Transaction Status / Paid In / Withdrawn / Balance" table rows from
///      that raw text (M-Pesa wraps long Details across multiple lines, so
///      a row is "everything from one receipt-code line up to the next").
///   3. Serialises those rows back into CSV text and calls
///      [StatementParser.parseCSV] on it, exactly as the CSV import tab
///      already does.
///   4. Cross-checks the parsed totals against the statement's own SUMMARY
///      block and attaches a warning (not a hard failure) if they disagree.
///
/// The row-reconstruction algorithm (step 2) was validated against a real
/// decrypted statement (279/279 rows, totals reconciled exactly) before
/// being ported here.
class PdfStatementParser {
  static final RegExp _rowStart = RegExp(
    r'^([A-Z0-9]{8,12})\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+(.*)$',
  );
  static final RegExp _statusPattern =
      RegExp(r'(Completed|Failed|Pending)', caseSensitive: false);
  static final RegExp _amountPattern = RegExp(r'-?[\d,]+\.\d{2}');
  static final RegExp _totalLine = RegExp(
    r'TOTAL:?\s*(-?[\d,]+\.\d{2})\s+(-?[\d,]+\.\d{2})',
    caseSensitive: false,
  );

  // Lines that are page furniture / the SUMMARY block rather than
  // transaction rows — skipped so they can't be misread as row content.
  static const _skipMarkers = [
    'Page ', 'Disclaimer', 'Statement Verification', 'For self-help',
    'M-PESA STATEMENT', 'Customer Name', 'Mobile Number', 'Email Address',
    'Statement Period', 'Request Date', 'SUMMARY', 'TRANSACTION TYPE',
    'SEND MONEY', 'RECEIVED MONEY', 'AGENT DEPOSIT', 'AGENT WITHDRAWAL',
    'LIPA NA', 'OTHERS:', 'TOTAL:', 'DETAILED STATEMENT', 'Receipt No.',
    'conditions apply', 'To verify the validity',
  ];

  /// Parses [filePath] with [password] and returns a [ParseResult] built
  /// entirely by [StatementParser.parseCSV].
  static Future<ParseResult> parsePdf(
    String filePath,
    String password, {
    PdfImportProgress? onProgress,
  }) async {
    final fullText = await _extractText(filePath, password, onProgress);

    if (fullText.trim().length < 200) {
      // A genuine statement has thousands of characters of text. A near-
      // empty result almost always means this PDF has no text layer at
      // all — i.e. it's a flattened/scanned copy, not the real export.
      throw const PdfImportException(
        "This PDF doesn't contain readable text — it looks like a scanned "
        'or flattened copy rather than the original M-Pesa export. Request '
        'a fresh statement from the M-Pesa app and try again.',
      );
    }

    final rows = _reconstructRows(fullText);
    final csv = _buildCsv(rows);
    final result = StatementParser.parseCSV(csv);

    return _withReconciliation(result, fullText);
  }

  // ── PDF opening + text extraction ─────────────────────────────────────
  //
  // API confirmed against pdfrx 1.3.5: PdfDocument.openFile takes a
  // `passwordProvider` (not a plain `password` argument), and
  // PdfPage.loadText() returns a PdfPageText whose text lives on
  // `.fullText` (not `.text`).

  static Future<String> _extractText(
    String filePath,
    String password,
    PdfImportProgress? onProgress,
  ) async {
    final PdfDocument document;
    try {
      document = await PdfDocument.openFile(
        filePath,
        // createSimplePasswordProvider hands the password to pdfrx exactly
        // once, then returns null — so a wrong password fails fast instead
        // of pdfrx calling this provider forever waiting for a new guess.
        passwordProvider:
            createSimplePasswordProvider(password.isEmpty ? null : password),
      );
    } on PdfPasswordException {
      throw const PdfImportException(
        'Incorrect password. Enter the PIN you set when requesting this '
        'statement from the M-Pesa app.',
        isPasswordError: true,
      );
    } catch (e) {
      throw PdfImportException('Could not open this PDF: $e');
    }

    try {
      final buffer = StringBuffer();
      final pageCount = document.pages.length;
      for (var i = 0; i < pageCount; i++) {
        final page = document.pages[i];
        final pageText = await page.loadText();
        buffer.writeln(pageText.fullText);
        onProgress?.call(i + 1, pageCount);
      }
      return buffer.toString();
    } finally {
      await document.dispose();
    }
  }

  // ── Row reconstruction (validated against a real statement) ──────────

  static List<_RawRow> _reconstructRows(String fullText) {
    final rows = <_RawRow>[];
    _RawRow? current;

    for (final raw in fullText.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (_skipMarkers.any(line.contains)) continue;

      final match = _rowStart.firstMatch(line);
      if (match != null) {
        if (current != null) rows.add(current);
        current = _RawRow(
          ref: match.group(1)!,
          time: match.group(2)!,
          lines: [match.group(3) ?? ''],
        );
      } else {
        current?.lines.add(line);
      }
    }
    if (current != null) rows.add(current);
    return rows;
  }

  static String _buildCsv(List<_RawRow> rows) {
    final buffer = StringBuffer()
      ..writeln(
        'Receipt No.,Completion Time,Details,Transaction Status,Paid In,'
        'Withdrawn,Balance',
      );

    for (final row in rows) {
      final joined = row.lines.join(' ');
      final statusMatch = _statusPattern.firstMatch(joined);
      final status = statusMatch?.group(1) ?? '';
      final amounts = _amountPattern
          .allMatches(joined)
          .map((m) => m.group(0)!)
          .toList();

      if (status.isEmpty || amounts.isEmpty) {
        // Couldn't confidently parse this row — skip it rather than
        // guess. It won't be counted, and the reconciliation check below
        // will surface the discrepancy.
        continue;
      }

      final balance = amounts.last;
      final movement = amounts.length > 1
          ? amounts.sublist(0, amounts.length - 1)
          : const <String>[];

      double paidIn = 0;
      double withdrawn = 0;
      for (final n in movement) {
        final value = double.tryParse(n.replaceAll(',', '')) ?? 0;
        if (value < 0) {
          withdrawn += value;
        } else {
          paidIn += value;
        }
      }

      // Details = everything in the joined text before the status keyword.
      final statusIndex = joined.indexOf(status);
      final details =
          (statusIndex > -1 ? joined.substring(0, statusIndex) : joined)
              .trim();

      buffer.writeln([
        _csvField(row.ref),
        _csvField(row.time),
        _csvField(details),
        _csvField(status),
        _csvField(paidIn == 0 ? '' : paidIn.toStringAsFixed(2)),
        _csvField(withdrawn == 0 ? '' : withdrawn.toStringAsFixed(2)),
        _csvField(balance),
      ].join(','));
    }

    return buffer.toString();
  }

  static String _csvField(String value) => '"${value.replaceAll('"', '""')}"';

  // ── Reconciliation against the statement's own SUMMARY block ─────────

  static ParseResult _withReconciliation(ParseResult result, String fullText) {
    final totalMatch = _totalLine.firstMatch(fullText);
    if (totalMatch == null) return result;

    final statementPaidIn =
        double.tryParse(totalMatch.group(1)!.replaceAll(',', '')) ?? 0;
    final statementPaidOut =
        double.tryParse(totalMatch.group(2)!.replaceAll(',', '')) ?? 0;

    final parsedPaidIn = result.transactions
        .where((t) => t.type.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
    final parsedPaidOut = result.transactions
        .where((t) => !t.type.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    const tolerance = 1.0; // allow for rounding
    final paidInOk = (parsedPaidIn - statementPaidIn).abs() <= tolerance;
    final paidOutOk = (parsedPaidOut - statementPaidOut).abs() <= tolerance;

    if (paidInOk && paidOutOk) return result;

    final warning = "Parsed totals don't fully match this statement's own "
        'summary (Paid In: Ksh ${parsedPaidIn.toStringAsFixed(2)} parsed vs '
        'Ksh ${statementPaidIn.toStringAsFixed(2)} on the statement · '
        'Paid Out: Ksh ${parsedPaidOut.toStringAsFixed(2)} parsed vs '
        'Ksh ${statementPaidOut.toStringAsFixed(2)} on the statement). '
        'Some rows may not have been recognized — please review your '
        'transactions.';

    return ParseResult(
      transactions: result.transactions,
      errors: result.errors,
      warnings: [...result.warnings, warning],
    );
  }
}

class _RawRow {
  final String ref;
  final String time;
  final List<String> lines;

  _RawRow({required this.ref, required this.time, required this.lines});
}
