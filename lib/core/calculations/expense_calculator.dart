class ExpenseCalculator {
  ExpenseCalculator._();

  /// Calculates invoice totals using integer currency units only.
  static int invoiceSubtotal(Iterable<({int quantity, int unitPrice})> items) {
    var total = 0;
    for (final item in items) {
      if (item.quantity < 0 || item.unitPrice < 0) {
        throw ArgumentError('Quantity and unit price cannot be negative.');
      }
      total += item.quantity * item.unitPrice;
    }
    return total;
  }

  static int invoiceTotal({
    required int subtotal,
    int discount = 0,
  }) {
    if (subtotal < 0 || discount < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
    if (discount > subtotal) {
      throw ArgumentError('Discount cannot exceed subtotal.');
    }
    return subtotal - discount;
  }

  static double budgetUsagePercent({
    required int spent,
    required int budget,
  }) {
    if (spent < 0 || budget < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
    if (budget == 0) return spent == 0 ? 0 : 100;
    return (spent / budget * 100).clamp(0, double.infinity);
  }

  static int remainingBudget({
    required int budget,
    required int spent,
  }) {
    if (budget < 0 || spent < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
    return budget - spent;
  }
}
