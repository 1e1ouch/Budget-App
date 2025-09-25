class Category {
  final String id;
  final String name;
  const Category(this.id, this.name);

  // Common categories we’ll reuse across the app
  static const groceries = Category('cat_groceries', 'Groceries');
  static const dining = Category('cat_dining', 'Dining');
  static const rent = Category('cat_rent', 'Rent');
  static const transfer = Category('cat_transfer', 'Transfer');
}

class Txn {
  final String id;
  final DateTime date;
  final String merchant;
  final double amount; // negative = expense, positive = income
  final Category category;

  Txn({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.category,
  });

  String get amountString {
    final sign = amount < 0 ? '-' : '';
    return '$sign\$${amount.abs().toStringAsFixed(2)}';
  }
}

class MonthlyTotals {
  final double income;
  final double spending;
  MonthlyTotals({required this.income, required this.spending});

  double get net => income - spending;
}

/// a single budget row (category + monthly limit)
class BudgetLine {
  final Category category;
  final double limit;

  const BudgetLine({required this.category, required this.limit});
}
