import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';
import 'package:intl/intl.dart';

class AppState extends ChangeNotifier {
  final Repository repo;
  AppState(this.repo);

  bool loading = true;

  late DateTime _month;
  MonthlyTotals monthly = MonthlyTotals(income: 0, spending: 0);
  List<Txn> _txns = <Txn>[];
  List<BudgetLine> _budgets = <BudgetLine>[];

  DateTime get month => _month;
  List<Txn> get monthTxns => _txns;
  List<Txn> get recent => _txns.take(20).toList();
  List<BudgetLine> get budgets => _budgets;

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
      repo.fetchGoals(),
    ]);
    _txns = results[0] as List<Txn>;
    monthly = results[1] as MonthlyTotals;
    _budgets = results[2] as List<BudgetLine>;
    _goals = results[3] as List<Goal>;
  }

  Future<void> addTxn(Txn t) async {
    await repo.addTransaction(t);
    await _refreshAfterMutation();
  }

  Future<void> updateTxn(Txn t) async {
    await repo.updateTransaction(t);
    await _refreshAfterMutation();
  }

  Future<void> deleteTxn(String id) async {
    await repo.deleteTransaction(id);
    await _refreshAfterMutation();
  }

  Future<void> saveBudgets(List<BudgetLine> lines) async {
    await repo.saveBudgets(lines);
    _budgets = await repo.fetchBudgets();
    notifyListeners();
  }

  Future<void> _refreshAfterMutation() async {
    _txns = await repo.fetchTransactions(month: _month);
    monthly = await repo.fetchMonthlyTotals(month: _month);
    notifyListeners();
  }

  String get monthLabel => DateFormat('MMMM yyyy').format(_month);
  Future<void> setMonth(DateTime m) async {
    _month = DateTime(m.year, m.month);
    await _refreshAll();
    notifyListeners();
  }

  Future<void> stepMonth(int delta) async {
    final m = DateTime(_month.year, _month.month + delta);
    await setMonth(m);
  }

  // ---- Goals ----
  List<Goal> _goals = <Goal>[];
  List<Goal> get goals => _goals;
  double get totalGoalsTarget => _goals.fold(0, (s, g) => s + g.target);
  double get totalGoalsSaved => _goals.fold(0, (s, g) => s + g.saved);

  Future<void> refreshGoals() async {
    _goals = await repo.fetchGoals();
    notifyListeners();
  }

  Future<void> addGoal(Goal g) async {
    await repo.addGoal(g);
    await refreshGoals();
  }

  Future<void> updateGoal(Goal g) async {
    await repo.updateGoal(g);
    await refreshGoals();
  }

  Future<void> deleteGoal(String id) async {
    await repo.deleteGoal(id);
    await refreshGoals();
  }

  Future<void> importTransactions(List<Txn> items) async {
    for (final t in items) {
      if (_txns.any((x) => x.id == t.id)) continue;
      await repo.addTransaction(t);
    }
    await _refreshAfterMutation();
  }
}
