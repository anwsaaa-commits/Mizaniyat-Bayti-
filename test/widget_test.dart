import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuna_sales_ledger/main.dart';
void main() {
 testWidgets('home screen loads', (tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const TunaApp());
  await tester.pumpAndSettle();
  expect(find.text('حسابات بيع وشراء السمك'), findsOneWidget);
 });
}
