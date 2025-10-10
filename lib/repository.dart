import 'models.dart';

abstract class Repository {
  Future<MonthlyTotals> fetchMonthlyTotals({required DateTime month});
  Future<List<Txn>> fetchTransactions({required DateTime month});

  Future<Txn> addTransaction(Txn txn);
  Future<Txn> updateTransaction(Txn txn);
  Future<void> deleteTransaction(String id);

  Future<List<BudgetLine>> fetchBudgets();
  Future<void> saveBudgets(List<BudgetLine> lines);
  Future<List<Goal>> fetchGoals();
  Future<Goal> addGoal(Goal g);
  Future<Goal> updateGoal(Goal g);
  Future<void> deleteGoal(String id);
}
