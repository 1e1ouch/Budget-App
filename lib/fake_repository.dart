import 'dart:async';

import 'models.dart';
import 'repository.dart';

class FakeRepository implements Repository {
  // --- sample transactions
  final _seed = <Txn>[
    Txn(
      id: 't1',
      date: DateTime.now().subtract(const Duration(days: 1)),
      merchant: 'Whole Foods',
      amount: -54.23,
      category: Category.groceries,
    ),
    Txn(
      id: 't2',
      date: DateTime.now().subtract(const Duration(days: 2)),
      merchant: 'Rent',
      amount: -1200,
      category: Category.rent,
    ),
    Txn(
      id: 't3',
      date: DateTime.now().subtract(const Duration(days: 3)),
      merchant: 'Coffee',
      amount: -4.50,
      category: Category.dining,
    ),
    Txn(
      id: 't4',
      date: DateTime.now().subtract(const Duration(days: 4)),
      merchant: 'Paycheck',
      amount: 1800,
      category: Category.transfer,
    ),
  ];

  // --- sample budgets (v1 defaults)
  final _budgets = <BudgetLine>[
    const BudgetLine(category: Category.groceries, limit: 300),
    const BudgetLine(category: Category.dining, limit: 150),
    const BudgetLine(category: Category.rent, limit: 1200),
    const BudgetLine(category: Category.transfer, limit: 0),
  ];

  @override
  Future<List<Txn>> fetchTransactions({required DateTime month}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final sameMonth =
        _seed
            .where(
              (t) => t.date.year == month.year && t.date.month == month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return sameMonth;
  }

  @override
  Future<MonthlyTotals> fetchMonthlyTotals({required DateTime month}) async {
    final txns = await fetchTransactions(month: month);
    final income = txns
        .where((t) => t.amount > 0)
        .fold<double>(0, (s, t) => s + t.amount);
    final spending = txns
        .where((t) => t.amount < 0)
        .fold<double>(0, (s, t) => s + (-t.amount));
    return MonthlyTotals(income: income, spending: spending);
  }

  @override
  Future<Txn> addTransaction(Txn txn) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _seed.add(txn);
    return txn;
  }

  // return a copy of the budget lines
  @override
  Future<List<BudgetLine>> fetchBudgets() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List<BudgetLine>.from(_budgets);
  }
}
