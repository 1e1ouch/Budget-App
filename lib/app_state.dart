import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._repo);
  final Repository _repo;

  bool loading = true;

  // Current-month aggregates
  MonthlyTotals monthly = MonthlyTotals(income: 0, spending: 0);
  List<Txn> monthTxns = [];
  List<Txn> recent = [];

  // Budgets (static list for v1)
  List<BudgetLine> budgets = [];

  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();

    final now = DateTime.now();
    monthTxns = await _repo.fetchTransactions(month: now);
    monthly = await _repo.fetchMonthlyTotals(month: now);
    budgets = await _repo.fetchBudgets(); // load budgets
    recent = monthTxns.take(10).toList();

    loading = false;
    notifyListeners();
  }

  Future<void> addTxn(Txn t) async {
    await _repo.addTransaction(t);
    await loadInitial();
  }

  /// Dollars spent in this month for a given category (positive value).
  double spentForCategory(String categoryId) {
    double total = 0;
    for (final t in monthTxns) {
      if (t.category.id == categoryId && t.amount < 0) {
        total += -t.amount; // make expenses positive
      }
    }
    return total;
  }

  /// roll-up helpers for the Budget summary row.
  double get totalBudgetLimit =>
      budgets.fold<double>(0, (sum, b) => sum + b.limit);

  double get totalBudgetSpent => budgets.fold<double>(
    0,
    (sum, b) => sum + spentForCategory(b.category.id),
  );

  double get totalBudgetRemaining => totalBudgetLimit - totalBudgetSpent;
}
