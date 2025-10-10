import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'repository.dart';

class LocalRepository implements Repository {
  late Box _txns;
  late Box _budgets;
  late Box _goals;

  Future<void> init() async {
    await Hive.initFlutter();
    _txns = await Hive.openBox('txns');
    _budgets = await Hive.openBox('budgets');
    _goals = await Hive.openBox('goals');

    if (_budgets.isEmpty || _txns.isEmpty) {
      await _seedDemo();
    }

    // Seed an example goal if none exist
    if (_goals.isEmpty) {
      final demo = Goal(
        id: 'g1',
        name: 'Emergency Fund',
        target: 1000,
        saved: 250,
        due: DateTime(DateTime.now().year, DateTime.now().month + 3, 1),
      );
      await addGoal(demo);
    }
  }

  Future<void> _seedDemo() async {
    await _budgets.clear();
    await _txns.clear();

    final budgets = [
      BudgetLine(category: Category.groceries, limit: 300),
      BudgetLine(category: Category.dining, limit: 150),
      BudgetLine(category: Category.rent, limit: 1200),
      BudgetLine(category: Category.transfer, limit: 0),
    ];
    await saveBudgets(budgets);

    final now = DateTime.now();
    final seed = <Txn>[
      Txn(
        id: 't1',
        date: now.subtract(const Duration(days: 1)),
        merchant: 'Whole Foods',
        amount: -54.23,
        category: Category.groceries,
      ),
      Txn(
        id: 't2',
        date: now.subtract(const Duration(days: 2)),
        merchant: 'Rent',
        amount: -1200,
        category: Category.rent,
      ),
      Txn(
        id: 't3',
        date: now.subtract(const Duration(days: 3)),
        merchant: 'Coffee',
        amount: -4.5,
        category: Category.dining,
      ),
      Txn(
        id: 't4',
        date: now.subtract(const Duration(days: 4)),
        merchant: 'Paycheck',
        amount: 1800,
        category: Category.transfer,
      ),
    ];
    for (final t in seed) {
      await _txns.put(t.id, _txnToMap(t));
    }
  }

  @override
  Future<List<Txn>> fetchTransactions({required DateTime month}) async {
    final list = _txns.values.cast<Map>().map(_txnFromMap).toList();
    final filtered =
        list
            .where(
              (t) => t.date.year == month.year && t.date.month == month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
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
    await _txns.put(txn.id, _txnToMap(txn));
    return txn;
  }

  @override
  Future<Txn> updateTransaction(Txn txn) async {
    await _txns.put(txn.id, _txnToMap(txn));
    return txn;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _txns.delete(id);
  }

  @override
  Future<List<BudgetLine>> fetchBudgets() async {
    final list = _budgets.values.cast<Map>().map(_budgetFromMap).toList();
    return list;
  }

  @override
  Future<void> saveBudgets(List<BudgetLine> lines) async {
    await _budgets.clear();
    for (final line in lines) {
      await _budgets.add(_budgetToMap(line));
    }
  }

  @override
  Future<void> resetDemoData() async {
    await _seedDemo();
  }

  // ---- Goals ----
  @override
  Future<List<Goal>> fetchGoals() async {
    final list = _goals.values.cast<Map>().map(_goalFromMap).toList();
    list.sort(
      (a, b) => (a.due ?? DateTime(2100)).compareTo(b.due ?? DateTime(2100)),
    );
    return list;
  }

  @override
  Future<Goal> addGoal(Goal g) async {
    await _goals.put(g.id, _goalToMap(g));
    return g;
  }

  @override
  Future<Goal> updateGoal(Goal g) async {
    await _goals.put(g.id, _goalToMap(g));
    return g;
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _goals.delete(id);
  }

  // -------- helpers --------

  Map<String, dynamic> _txnToMap(Txn t) => {
    'id': t.id,
    'date': t.date.millisecondsSinceEpoch,
    'merchant': t.merchant,
    'amount': t.amount,
    'catId': t.category.id,
    'catName': t.category.name,
  };

  Txn _txnFromMap(Map m) => Txn(
    id: m['id'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
    merchant: m['merchant'] as String,
    amount: (m['amount'] as num).toDouble(),
    category: Category.fromId(m['catId'] as String, m['catName'] as String),
  );

  Map<String, dynamic> _budgetToMap(BudgetLine b) => {
    'catId': b.category.id,
    'catName': b.category.name,
    'limit': b.limit,
  };

  BudgetLine _budgetFromMap(Map m) => BudgetLine(
    category: Category.fromId(m['catId'] as String, m['catName'] as String),
    limit: (m['limit'] as num).toDouble(),
  );

  Map<String, dynamic> _goalToMap(Goal g) => {
    'id': g.id,
    'name': g.name,
    'target': g.target,
    'saved': g.saved,
    'due': g.due?.millisecondsSinceEpoch,
  };

  Goal _goalFromMap(Map m) => Goal(
    id: m['id'] as String,
    name: m['name'] as String,
    target: (m['target'] as num).toDouble(),
    saved: (m['saved'] as num).toDouble(),
    due: m['due'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['due'] as int),
  );
}
