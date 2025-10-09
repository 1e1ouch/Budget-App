import 'package:flutter_test/flutter_test.dart';
import 'package:blue_budget/repository.dart';
import 'package:blue_budget/models.dart';
import 'package:blue_budget/app_state.dart';

class _MemoryRepo implements Repository {
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
      _txns.add(txn); // upsert behavior for safety in tests
    }
    return txn;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _txns.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<BudgetLine>> fetchBudgets() async => _budgets;

  @override
  Future<void> saveBudgets(List<BudgetLine> lines) async {
    _budgets = List.of(lines);
  }
}

void main() {
  test('AppState loads and computes monthly totals', () async {
    final repo = _MemoryRepo();
    final app = AppState(repo);

    await app.loadInitial();

    expect(app.loading, false);
    expect(app.monthTxns.isNotEmpty, true);
    expect(app.monthly.income, greaterThan(0)); // paycheck present
    expect(app.monthly.spending, greaterThan(0)); // groceries present

    // add → update totals
    final newTxn = Txn(
      id: 't_new',
      date: DateTime.now(),
      merchant: 'Coffee',
      amount: -3.50,
      category: Category.dining,
    );
    await app.addTxn(newTxn);
    expect(app.monthTxns.any((t) => t.id == 't_new'), true);

    // edit
    final updated = Txn(
      id: 't_new',
      date: newTxn.date,
      merchant: 'Coffee Shop',
      amount: -4.00,
      category: Category.dining,
    );
    await app.updateTxn(updated);
    expect(
      app.monthTxns.firstWhere((t) => t.id == 't_new').merchant,
      'Coffee Shop',
    );

    // delete
    await app.deleteTxn('t_new');
    expect(app.monthTxns.any((t) => t.id == 't_new'), false);
  });
}
