import 'package:flutter_test/flutter_test.dart';
import 'package:mizaniyat_bayti/core/calculations/expense_calculator.dart';
void main(){group('Invoice accounting',(){
test('sums all invoice items and applies discount once',(){final subtotal=ExpenseCalculator.invoiceSubtotal([(quantity:2,unitPrice:1200),(quantity:1,unitPrice:800),(quantity:4,unitPrice:250)]);expect(subtotal,4200);expect(ExpenseCalculator.invoiceTotal(subtotal:subtotal,discount:200),4000);});
test('rejects negative quantities',(){expect(()=>ExpenseCalculator.invoiceSubtotal([(quantity:-1,unitPrice:500)]),throwsArgumentError);});
test('keeps exact integer currency arithmetic',(){expect(ExpenseCalculator.invoiceSubtotal([(quantity:3,unitPrice:333)]),999);});
});}
