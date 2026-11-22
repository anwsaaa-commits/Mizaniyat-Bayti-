import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_sales_ledger/main.dart';
void main(){test('invoice calculations',(){final x=SaleInvoice('buyer','2026-11-22','',2.5,6500,5000);expect(x.total,16250);expect(x.balance,11250);});}
