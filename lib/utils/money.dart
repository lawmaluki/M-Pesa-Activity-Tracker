import 'package:intl/intl.dart';

/// Formatting for the single currency this app deals in.
///
/// Every amount rendered in the UI goes through here so the "Ksh " prefix
/// and the grouping/decimal style stay consistent, and so each
/// [NumberFormat] is built once rather than once per widget that needs it.
///
/// Callers that need a leading +/- compose it themselves around
/// [exact] — the sign's spacing differs between surfaces.
class Money {
  Money._();

  static final _exact = NumberFormat('#,##0.00');
  static final _whole = NumberFormat('#,##0');
  static final _compact = NumberFormat.compact();

  /// `Ksh 1,234.56` — full precision, for individual transactions and
  /// day totals where the exact figure matters.
  static String exact(double amount) => 'Ksh ${_exact.format(amount)}';

  /// `Ksh 1,235` — rounded, for the at-a-glance summary tiles.
  static String whole(double amount) => 'Ksh ${_whole.format(amount)}';

  /// `Ksh 1.2K` — abbreviated, for the space-constrained share card.
  static String compact(double amount) => 'Ksh ${_compact.format(amount)}';
}
