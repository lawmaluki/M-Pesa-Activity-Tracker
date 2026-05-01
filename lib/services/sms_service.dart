import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/transaction.dart';
import 'database_service.dart';
import 'sms_parser.dart';

class SmsService {
  static final _query = SmsQuery();

  /// Requests READ_SMS permission. Returns true if granted.
  static Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Reads all M-Pesa messages from the device inbox and syncs them to the DB.
  static Future<SyncResult> syncFromDevice() async {
    final granted = await hasPermission();
    if (!granted) {
      return const SyncResult(
        success: false,
        message: 'SMS permission not granted',
        newCount: 0,
        totalParsed: 0,
      );
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      final bodies = messages
          .where((m) => m.body != null && SmsParser.isMpesaSms(m.body!))
          .map((m) => m.body!)
          .toList();

      final parsed = SmsParser.parseAll(bodies);
      final inserted =
          await DatabaseService.instance.insertTransactionsBatch(parsed);

      return SyncResult(
        success: true,
        message:
            'Scanned ${messages.length} messages, found ${bodies.length} M-Pesa, $inserted new added',
        newCount: inserted,
        totalParsed: parsed.length,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Error reading SMS: $e',
        newCount: 0,
        totalParsed: 0,
      );
    }
  }

  // Real-time background SMS listening requires a native BroadcastReceiver.
  // Implement via a platform channel in a future iteration.
  static void startListening(void Function(MpesaTransaction) onTransaction) {}
}

class SyncResult {
  final bool success;
  final String message;
  final int newCount;
  final int totalParsed;

  const SyncResult({
    required this.success,
    required this.message,
    required this.newCount,
    required this.totalParsed,
  });
}
