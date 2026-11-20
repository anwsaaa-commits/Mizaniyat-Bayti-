import 'package:flutter_test/flutter_test.dart';
import 'package:mizaniyat_bayti/core/calculations/expense_calculator.dart';

void main() {
  group('ExpenseCalculator', () {
    test('calculates invoice subtotal from multiple items', () {
      final subtotal = ExpenseCalculator.invoiceSubtotal([
        (quantity: 2, unitPrice: 1500),
        (quantity: 3, unitPrice: 500),
      ]);
      expect(subtotal, 4500);
    });

    test('applies discount once to invoice subtotal', () {
      expect(
        ExpenseCalculator.invoiceTotal(subtotal: 4500, discount: 500),
        4000,
      );
    });

    test('rejects discount greater than subtotal', () {
      expect(
        () => ExpenseCalculator.invoiceTotal(subtotal: 100, discount: 101),
        throwsArgumentError,
      );
    });

    test('calculates budget usage percentage', () {
      expect(
        ExpenseCalculator.budgetUsagePercent(spent: 8000, budget: 10000),
        80,
      );
    });

    test('calculates negative remaining balance after overspending', () {
      expect(
        ExpenseCalculator.remainingBudget(budget: 1000, spent: 1250),
        -250,
      );
    });

    test('keeps integer currency arithmetic exact', () {
      expect(
        ExpenseCalculator.invoiceSubtotal([
          (quantity: 3, unitPrice: 333),
        ]),
        999,
      );
    });
  });
}
