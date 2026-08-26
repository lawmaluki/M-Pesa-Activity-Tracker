import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/pdf_statement_parser.dart';
import '../services/statement_parser.dart';

enum LoadState { idle, loading, error }

class TransactionProvider extends ChangeNotifier {
  List<MpesaTransaction> _transactions = [];
  Map<String, int> _dailyCounts = {};
  LoadState _state = LoadState.idle;
  String? _errorMessage;
  int _selectedYear;
  DateTime? _selectedDay;

  TransactionProvider() : _selectedYear = DateTime.now().year;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<MpesaTransaction> get transactions => _transactions;
  Map<String, int> get dailyCounts => _dailyCounts;
  LoadState get state => _state;
  String? get errorMessage => _errorMessage;
  int get selectedYear => _selectedYear;
  DateTime? get selectedDay => _selectedDay;

  int get totalTransactions => _transactions.length;

  double get totalSpent => _transactions
      .where((t) => !t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalReceived => _transactions
      .where((t) => t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  // ── Year-scoped stats (for the share card, which is framed around
  // whichever year is currently selected on the heatmap) ─────────────────

  List<MpesaTransaction> get _selectedYearTransactions =>
      _transactions.where((t) => t.date.year == _selectedYear).toList();

  int get yearTransactionCount => _selectedYearTransactions.length;

  double get yearReceived => _selectedYearTransactions
      .where((t) => t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  double get yearSpent => _selectedYearTransactions
      .where((t) => !t.type.isCredit)
      .fold(0, (sum, t) => sum + t.amount);

  /// Longest run of consecutive calendar days with at least one
  /// transaction, within the selected year.
  int get longestStreakDays {
    if (_dailyCounts.isEmpty) return 0;
    final days = _dailyCounts.keys.map(DateTime.parse).toList()..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// Days elapsed in the selected year — the full year length if it's in
  /// the past, or "today's day-of-year" if it's the current year.
  int get daysTrackedInSelectedYear {
    final now = DateTime.now();
    final yearStart = DateTime(_selectedYear, 1, 1);
    if (_selectedYear < now.year) {
      final yearEnd = DateTime(_selectedYear, 12, 31);
      return yearEnd.difference(yearStart).inDays + 1;
    } else if (_selectedYear == now.year) {
      final today = DateTime(now.year, now.month, now.day);
      return today.difference(yearStart).inDays + 1;
    }
    return 0;
  }

  List<MpesaTransaction> get selectedDayTransactions {
    if (_selectedDay == null) return [];
    final key = _dateKey(_selectedDay!);
    return _transactions
        .where((t) => t.dateKey == key)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  DaySummary? get selectedDaySummary {
    if (_selectedDay == null) return null;
    return DaySummary(
      date: _selectedDay!,
      transactions: selectedDayTransactions,
    );
  }

  int countForDay(String dateKey) => _dailyCounts[dateKey] ?? 0;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _setState(LoadState.loading);
    try {
      _transactions = await DatabaseService.instance.fetchAll();
      await _refreshHeatmapData();
      _setState(LoadState.idle);
    } catch (e) {
      _setError('Failed to load transactions: $e');
    }
  }

  Future<ImportResult> importCsv(String csvContent) async {
    _setState(LoadState.loading);
    try {
      final result = StatementParser.parseCSV(csvContent);
      final inserted = await DatabaseService.instance
          .insertTransactionsBatch(result.transactions);
      if (inserted > 0) {
        _transactions = await DatabaseService.instance.fetchAll();
        await _refreshHeatmapData();
      }
      _setState(LoadState.idle);
      return ImportResult(
        inserted: inserted,
        parsed: result.count,
        errors: result.errors,
      );
    } catch (e) {
      _setError('CSV import failed: $e');
      return ImportResult(inserted: 0, parsed: 0, errors: ['Error: $e']);
    }
  }

  Future<ImportResult> importPastedSms(String text) async {
    _setState(LoadState.loading);
    try {
      final result = StatementParser.parsePastedSms(text);
      final inserted = await DatabaseService.instance
          .insertTransactionsBatch(result.transactions);
      if (inserted > 0) {
        _transactions = await DatabaseService.instance.fetchAll();
        await _refreshHeatmapData();
      }
      _setState(LoadState.idle);
      return ImportResult(
        inserted: inserted,
        parsed: result.count,
        errors: result.errors,
      );
    } catch (e) {
      _setError('Paste import failed: $e');
      return ImportResult(inserted: 0, parsed: 0, errors: ['Error: $e']);
    }
  }

  Future<ImportResult> importPdf(
    String filePath,
    String password, {
    PdfImportProgress? onProgress,
  }) async {
    _setState(LoadState.loading);
    try {
      final result = await PdfStatementParser.parsePdf(
        filePath,
        password,
        onProgress: onProgress,
      );
      final inserted = await DatabaseService.instance
          .insertTransactionsBatch(result.transactions);
      if (inserted > 0) {
        _transactions = await DatabaseService.instance.fetchAll();
        await _refreshHeatmapData();
      }
      _setState(LoadState.idle);
      return ImportResult(
        inserted: inserted,
        parsed: result.count,
        errors: result.errors,
        warnings: result.warnings,
      );
    } on PdfImportException catch (e) {
      _setState(LoadState.idle);
      return ImportResult(
        inserted: 0,
        parsed: 0,
        errors: [e.message],
        isPasswordError: e.isPasswordError,
      );
    } catch (e) {
      _setError('PDF import failed: $e');
      return ImportResult(inserted: 0, parsed: 0, errors: ['Error: $e']);
    }
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseService.instance.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    await _refreshHeatmapData();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await DatabaseService.instance.deleteAll();
    _transactions = [];
    _dailyCounts = {};
    _selectedDay = null;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    if (_selectedYear == year) return;
    _selectedYear = year;
    _refreshHeatmapData().then((_) => notifyListeners());
  }

  void selectDay(DateTime? day) {
    _selectedDay = day;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _refreshHeatmapData() async {
    _dailyCounts =
        await DatabaseService.instance.fetchDailyCountsForYear(_selectedYear);
  }

  void _setState(LoadState s) {
    _state = s;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _state = LoadState.error;
    _errorMessage = msg;
    notifyListeners();
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class ImportResult {
  final int inserted;
  final int parsed;
  final List<String> errors;
  final List<String> warnings;
  final bool isPasswordError;

  const ImportResult({
    required this.inserted,
    required this.parsed,
    required this.errors,
    this.warnings = const [],
    this.isPasswordError = false,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
