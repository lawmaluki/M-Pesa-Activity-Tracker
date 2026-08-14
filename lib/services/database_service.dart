import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mpesa_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ref TEXT NOT NULL UNIQUE,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            counterparty TEXT,
            balance REAL,
            transaction_cost REAL,
            raw_sms TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_date ON transactions(date)',
        );
      },
    );
  }

  Future<int> insertTransactionsBatch(List<MpesaTransaction> txs) async {
    final database = await db;
    int inserted = 0;
    await database.transaction((txn) async {
      for (final tx in txs) {
        final result = await txn.insert(
          'transactions',
          tx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (result > 0) inserted++;
      }
    });
    return inserted;
  }

  Future<List<MpesaTransaction>> fetchAll() async {
    final database = await db;
    final maps = await database.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map(MpesaTransaction.fromMap).toList();
  }

  Future<Map<String, int>> fetchDailyCountsForYear(int year) async {
    final database = await db;
    final start = DateTime(year);
    final end = DateTime(year + 1);
    final result = await database.rawQuery(
      '''
      SELECT substr(date, 1, 10) as day, COUNT(*) as cnt
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY day
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return {for (final row in result) row['day'] as String: row['cnt'] as int};
  }

  Future<void> deleteTransaction(int id) async {
    final database = await db;
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final database = await db;
    await database.delete('transactions');
  }
}
