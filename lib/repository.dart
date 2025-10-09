import 'models.dart';

abstract class Repository {
  Future<MonthlyTotals> fetchMonthlyTotals({required DateTime month});
  Future<List<Txn>> fetchTransactions({required DateTime month});

  Future<Txn> addTransaction(Txn txn);
  Future<Txn> updateTransaction(Txn txn); // NEW
  Future<void> deleteTransaction(String id); // NEW

  Future<List<BudgetLine>> fetchBudgets();
  Future<void> saveBudgets(List<BudgetLine> lines);
}
