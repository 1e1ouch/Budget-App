import 'package:flutter_test/flutter_test.dart';
import 'package:blue_budget/repository.dart';
import 'package:blue_budget/models.dart';
import 'package:blue_budget/app_state.dart';

class _MemoryRepo implements Repository {
  // ---- In-memory stores ----
  final List<Txn> _txns = <Txn>[
    Txn(
      id: 't1',
      date: DateTime.now(),
      merchant: 'Whole Foods',
      amount: -54.23,
      category: Category.groceries,
    ),
    Txn(
      id: 't2',
      date: DateTime.now(),
      merchant: 'Paycheck',
      amount: 1800,
      category: Category.transfer,
    ),
  ];

  List<BudgetLine> _budgets = const [
    BudgetLine(category: Category.groceries, limit: 300),
    BudgetLine(category: Category.dining, limit: 150),
    BudgetLine(category: Category.rent, limit: 1200),
    BudgetLine(category: Category.transfer, limit: 0),
  ];

  final List<Goal> _goals = <Goal>[
    Goal(id: 'g1', name: 'Emergency Fund', target: 500, saved: 100, due: null),
  ];

  // ---- Transactions ----
  @override
  Future<List<Txn>> fetchTransactions({required DateTime month}) async {
    return _txns
        .where((t) => t.date.year == month.year && t.date.month == month.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
    _txns.add(txn);
    return txn;
  }

  @override
  Future<Txn> updateTransaction(Txn txn) async {
    final i = _txns.indexWhere((t) => t.id == txn.id);
    if (i >= 0) {
      _txns[i] = txn;
    } else {
      _txns.add(txn);
    }
    return txn;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _txns.removeWhere((t) => t.id == id);
  }

  // ---- Budgets ----
  @override
  Future<List<BudgetLine>> fetchBudgets() async => _budgets;

  @override
  Future<void> saveBudgets(List<BudgetLine> lines) async {
    _budgets = List.of(lines);
  }

  // ---- Reset (no-op for tests, but implement to satisfy interface) ----
  @override
  Future<void> resetDemoData() async {
    // Keep it simple for tests: just ensure lists are non-empty.
    if (_txns.isEmpty) {
      _txns.add(
        Txn(
          id: 't_seed',
          date: DateTime.now(),
          merchant: 'Seed',
          amount: -1,
          category: Category.groceries,
        ),
      );
    }
  }

  // ---- Goals ----
  @override
  Future<List<Goal>> fetchGoals() async => List.of(_goals);

  @override
  Future<Goal> addGoal(Goal g) async {
    _goals.add(g);
    return g;
  }

  @override
  Future<Goal> updateGoal(Goal g) async {
    final i = _goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) _goals[i] = g;
    return g;
  }

  @override
  Future<void> deleteGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
  }
}

void main() {
  test('AppState loads, transactions + goals CRUD works', () async {
    final repo = _MemoryRepo();
    final app = AppState(repo);

    await app.loadInitial();

    // Loaded state
    expect(app.loading, false);
    expect(app.monthTxns.isNotEmpty, true);
    expect(app.budgets.isNotEmpty, true);
    expect(app.goals.isNotEmpty, true);

    // ---- Transactions CRUD ----
    final newTxn = Txn(
      id: 't_new',
      date: DateTime.now(),
      merchant: 'Coffee',
      amount: -3.50,
      category: Category.dining,
    );
    await app.addTxn(newTxn);
    expect(app.monthTxns.any((t) => t.id == 't_new'), true);

    final updatedTxn = Txn(
      id: 't_new',
      date: newTxn.date,
      merchant: 'Coffee Shop',
      amount: -4.00,
      category: Category.dining,
    );
    await app.updateTxn(updatedTxn);
    expect(
      app.monthTxns.firstWhere((t) => t.id == 't_new').merchant,
      'Coffee Shop',
    );

    await app.deleteTxn('t_new');
    expect(app.monthTxns.any((t) => t.id == 't_new'), false);

    // ---- Goals CRUD ----
    final g = Goal(
      id: 'g_new',
      name: 'New Laptop',
      target: 1200,
      saved: 300,
      due: null,
    );
    await app.addGoal(g);
    expect(app.goals.any((x) => x.id == 'g_new'), true);

    final g2 = Goal(
      id: 'g_new',
      name: 'New Laptop',
      target: 1200,
      saved: 500, // progress
      due: null,
    );
    await app.updateGoal(g2);
    expect(app.goals.firstWhere((x) => x.id == 'g_new').saved, 500);

    await app.deleteGoal('g_new');
    expect(app.goals.any((x) => x.id == 'g_new'), false);
  });
}
