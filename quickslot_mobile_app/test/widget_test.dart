import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot_mobile_app/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuickSlotApp(),
      ),
    );

    // Verify that the logo name is shown on login screen
    expect(find.text('QUICKSLOT'), findsOneWidget);
  });
}
