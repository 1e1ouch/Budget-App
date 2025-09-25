import 'dart:async';
import 'models.dart';
import 'repository.dart';

class FakeRepository implements Repository {
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
      amount: -4.5,
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
}
