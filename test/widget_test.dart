import 'package:flutter_test/flutter_test.dart';
import 'package:fit_cycle/main.dart';

void main() {
  testWidgets('FitCycle smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FitCycleApp());
    expect(find.byType(FitCycleApp), findsOneWidget);
  });
}
