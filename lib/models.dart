class Category {
  final String id;
  final String name;
  const Category(this.id, this.name);

  static const groceries = Category('cat_groceries', 'Groceries');
  static const dining = Category('cat_dining', 'Dining');
  static const rent = Category('cat_rent', 'Rent');
  static const transfer = Category('cat_transfer', 'Transfer');

  static const all = <Category>[groceries, dining, rent, transfer];

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

class AppUser {
  final String username;
  final String password; // stored locally

  AppUser({
    required this.username,
    required this.password,
  });
}


class MonthlyTotals {
  final double income;
  final double spending;
  MonthlyTotals({required this.income, required this.spending});

  double get net => income - spending;
}

class BudgetLine {
  final Category category;
  final double limit;

  const BudgetLine({required this.category, required this.limit});
}

class Goal {
  final String id;
  final String name;
  final double target; // how much you want to save
  final double saved; // how much saved so far
  final DateTime? due; // optional due date

  Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.due,
  });

  double get pct => target <= 0 ? 0 : (saved / target).clamp(0, 1);
}
