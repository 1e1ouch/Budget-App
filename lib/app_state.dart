import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';

class AppState extends ChangeNotifier {
  final Repository repo;
  AppState(this.repo);

  bool loading = true;

  // Data for the current month
  late DateTime _month;
  MonthlyTotals monthly = MonthlyTotals(income: 0, spending: 0);
  List<Txn> _txns = <Txn>[];
  List<BudgetLine> _budgets = <BudgetLine>[];

  // Public getters used by UI
  DateTime get month => _month;
  List<Txn> get monthTxns => _txns;
  List<Txn> get recent => _txns.take(20).toList();
  List<BudgetLine> get budgets => _budgets;

  // ---- Derived budget numbers ----
  double get totalBudgetLimit =>
      _budgets.fold<double>(0, (s, b) => s + b.limit);

  double get totalBudgetSpent =>
      _budgets.fold<double>(0, (s, b) => s + spentForCategory(b.category.id));

  double get totalBudgetRemaining =>
      (totalBudgetLimit - totalBudgetSpent).clamp(0, double.infinity);

  double spentForCategory(String catId) {
    return _txns
        .where((t) => t.amount < 0 && t.category.id == catId)
        .fold<double>(0, (s, t) => s + (-t.amount));
  }

  // ---- Lifecycle ----
  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();

    _month = DateTime(DateTime.now().year, DateTime.now().month);
    await _refreshAll();

    loading = false;
    notifyListeners();
  }

  Future<void> _refreshAll() async {
    final results = await Future.wait([
      repo.fetchTransactions(month: _month),
      repo.fetchMonthlyTotals(month: _month),
      repo.fetchBudgets(),
    ]);

    _txns = results[0] as List<Txn>;
    monthly = results[1] as MonthlyTotals;
    _budgets = results[2] as List<BudgetLine>;
  }

  Future<void> addTxn(Txn t) async {
    await repo.addTransaction(t);
    // refresh month data (totals + txns)
    _txns = await repo.fetchTransactions(month: _month);
    monthly = await repo.fetchMonthlyTotals(month: _month);
    notifyListeners();
  }

  Future<void> saveBudgets(List<BudgetLine> lines) async {
    await repo.saveBudgets(lines);
    _budgets = await repo.fetchBudgets();
    notifyListeners();
  }
}
