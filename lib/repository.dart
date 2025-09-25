import 'models.dart';

abstract class Repository {
  Future<MonthlyTotals> fetchMonthlyTotals({required DateTime month});
  Future<List<Txn>> fetchTransactions({required DateTime month});
  Future<Txn> addTransaction(Txn txn);
  Future<List<BudgetLine>> fetchBudgets();
}
