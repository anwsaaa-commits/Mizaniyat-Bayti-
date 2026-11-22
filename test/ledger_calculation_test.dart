import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_sales_ledger/main.dart';
void main() {
 test('calculates totals and remaining balance', () {
  const item = SaleInvoice(buyer:'Test',date:'2026-11-22',note:'',kg:2.5,price:6500,paid:5000);
  expect(item.total,16250);
  expect(item.balance,11250);
 });
 test('fully paid invoice has zero balance', () {
  const item = SaleInvoice(buyer:'Test',date:'2026-11-22',note:'',kg:2,price:6500,paid:13000);
  expect(item.balance,0);
 });
}
