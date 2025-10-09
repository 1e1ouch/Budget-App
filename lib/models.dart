class Category {
  final String id;
  final String name;
  const Category(this.id, this.name);

  // Common categories (canonical singletons)
  static const groceries = Category('cat_groceries', 'Groceries');
  static const dining = Category('cat_dining', 'Dining');
  static const rent = Category('cat_rent', 'Rent');
  static const transfer = Category('cat_transfer', 'Transfer');

  static const all = <Category>[groceries, dining, rent, transfer];

  // Prefer canonical constants when possible; otherwise create ad-hoc
  static Category fromId(String id, String name) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return Category(id, name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category($id, $name)';
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
