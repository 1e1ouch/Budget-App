import 'package:flutter_test/flutter_test.dart';
import 'package:blue_budget/main.dart';

void main() {
  testWidgets(
    'shows Dashboard then navigates to Budget and Transactions tabs',
    (tester) async {
      // Build the app
      await tester.pumpWidget(const BudgetApp());

      // Default screen is Dashboard
      expect(find.text('Dashboard'), findsWidgets); // title + tab label
      expect(find.text('Dashboard (placeholder)'), findsOneWidget);

      // Tap "Budget" tab
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();
      expect(find.text('Budget (placeholder)'), findsOneWidget);

      // Tap "Transactions" tab
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.text('Transactions (placeholder)'), findsOneWidget);
    },
  );
}
