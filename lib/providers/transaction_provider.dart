import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';
import '../services/statement_parser.dart';

enum LoadState { idle, loading, error }

class TransactionProvider extends ChangeNotifier {
  List<MpesaTransaction> _transactions = [];
  Map<String, int> _dailyCounts = {};
  Map<String, double> _dailyAmounts = {};
  LoadState _state = LoadState.idle;
  String? _errorMessage;
  int _selectedYear;
  DateTime? _selectedDay;

  TransactionProvider() : _selectedYear = DateTime.now().year;

  // ── Getters ──────────────────────────────────────────────────────────────

  List<MpesaTransaction> get transactions => _transactions;
  Map<String, int> get dailyCounts => _dailyCounts;
  Map<String, double> get dailyAmounts => _dailyAmounts;
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
  double amountForDay(String dateKey) => _dailyAmounts[dateKey] ?? 0;

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

  Future<SyncResult> syncSms() async {
    _setState(LoadState.loading);
    try {
      final result = await SmsService.syncFromDevice();
      if (result.newCount > 0) {
        _transactions = await DatabaseService.instance.fetchAll();
        await _refreshHeatmapData();
      }
      _setState(LoadState.idle);
      return result;
    } catch (e) {
      _setError('SMS sync failed: $e');
      return SyncResult(
        success: false,
        message: 'Error: $e',
        newCount: 0,
        totalParsed: 0,
      );
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
    _dailyAmounts = {};
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

  void onNewTransaction(MpesaTransaction tx) {
    _transactions.insert(0, tx);
    final key = tx.dateKey;
    _dailyCounts[key] = (_dailyCounts[key] ?? 0) + 1;
    _dailyAmounts[key] = (_dailyAmounts[key] ?? 0) + tx.amount;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _refreshHeatmapData() async {
    _dailyCounts =
        await DatabaseService.instance.fetchDailyCountsForYear(_selectedYear);
    _dailyAmounts =
        await DatabaseService.instance.fetchDailyAmountsForYear(_selectedYear);
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

  const ImportResult({
    required this.inserted,
    required this.parsed,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}
