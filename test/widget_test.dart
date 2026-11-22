import 'package:flutter_test/flutter_test.dart';
import 'package:tuna_sales_ledger/main.dart';

void main() {
  test('formats Yemeni riyal amounts', () {
    expect(money(6500), '6,500 ر.ي');
  });
}
