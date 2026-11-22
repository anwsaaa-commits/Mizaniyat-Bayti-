import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_sales_ledger/main.dart';
void main(){
 test('calculates invoice total and remaining correctly',(){
  final x=SaleInvoice(id:'1',buyer:'مشتري',note:'',date:'2026-11-22',kg:2.5,price:6500,paid:5000);
  expect(x.total,16250);expect(x.balance,11250);
 });
 test('fully paid cash invoice has zero debt',(){
  final x=SaleInvoice(id:'2',buyer:'مشتري',note:'',date:'2026-11-22',kg:2,price:6500,paid:13000);
  expect(x.balance,0);
 });
}
