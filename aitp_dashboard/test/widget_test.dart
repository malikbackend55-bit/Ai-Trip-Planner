import 'package:flutter_test/flutter_test.dart';
import 'package:aitp_dashboard/main.dart';

void main() {
  testWidgets('Dashboard app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AitpDashboardApp());
    expect(find.text('Overview Stats'), findsOneWidget);
  });
}
