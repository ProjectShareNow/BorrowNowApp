import 'package:flutter_test/flutter_test.dart';
import 'package:borrow_now/main.dart';
import 'package:borrow_now/services/service_registry.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceRegistry.init();
  });

  testWidgets('BorrowNow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BorrowNowApp());
    expect(find.byType(BorrowNowApp), findsOneWidget);

    // Advance past the splash screen delay (2 seconds)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
