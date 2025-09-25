import 'package:flutter/foundation.dart';
import 'models.dart';
import 'repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._repo);
  final Repository _repo;

  bool loading = true;
  MonthlyTotals monthly = MonthlyTotals(income: 0, spending: 0);
  List<Txn> monthTxns = [];
  List<Txn> recent = [];

  Future<void> loadInitial() async {
    loading = true;
    notifyListeners();

    final now = DateTime.now();
    monthTxns = await _repo.fetchTransactions(month: now);
    monthly = await _repo.fetchMonthlyTotals(month: now);
    recent = monthTxns.take(10).toList();

    loading = false;
    notifyListeners();
  }

  Future<void> addTxn(Txn t) async {
    await _repo.addTransaction(t);
    await loadInitial();
  }
}
