import 'package:flutter_test/flutter_test.dart';
import 'package:mpesa_tracker/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MpesaTrackerApp());
    expect(find.byType(MpesaTrackerApp), findsOneWidget);
  });
}
