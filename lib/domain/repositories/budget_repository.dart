import '../models/category.dart';
import '../models/financial_month.dart';
import '../models/monthly_budget.dart';

/// Vinculado a um UID; salvar substitui o limite da mesma competência/categoria.
abstract interface class BudgetRepository {
  Future<List<MonthlyBudget>> fetchMonth(FinancialMonth month);
  Future<void> save({
    required FinancialMonth month,
    required Category category,
    required int limitCents,
  });
  Future<void> remove({
    required FinancialMonth month,
    required Category category,
  });
}
