import 'category.dart';
import 'financial_month.dart';
import 'financial_transaction.dart';

enum BudgetStatus { normal, attention, reached }

final class MonthlyTotals {
  const MonthlyTotals(this.month, this.incomeCents, this.expenseCents);
  final FinancialMonth month;
  final int incomeCents;
  final int expenseCents;
}

final class BudgetUsage {
  const BudgetUsage(this.consumedCents, this.limitCents);
  final int consumedCents;
  final int limitCents;

  /// null significa ausência de limites, não orçamento de 0%.
  double? get percentage =>
      limitCents == 0 ? null : consumedCents / limitCents * 100;
  BudgetStatus? get status {
    if (limitCents == 0) return null;
    if (consumedCents >= limitCents) return BudgetStatus.reached;
    if (BigInt.from(consumedCents) * BigInt.from(100) >=
        BigInt.from(limitCents) * BigInt.from(80)) {
      return BudgetStatus.attention;
    }
    return BudgetStatus.normal;
  }
}

/// Resultado transitório: nunca é fonte de verdade persistida.
final class FinancialSummary {
  FinancialSummary({
    required this.balanceCents,
    required this.totals,
    required Map<Category, int> expensesByCategory,
    required Map<Category, double> categoryPercentages,
    required Map<Category, BudgetUsage> budgetByCategory,
    required this.totalBudget,
    required this.previousExpenseCents,
    required this.expenseVariationPercentage,
    required List<MonthlyTotals> evolution,
    required List<FinancialTransaction> history,
  }) : expensesByCategory = Map.unmodifiable(expensesByCategory),
       categoryPercentages = Map.unmodifiable(categoryPercentages),
       budgetByCategory = Map.unmodifiable(budgetByCategory),
       evolution = List.unmodifiable(evolution),
       history = List.unmodifiable(history);

  final int balanceCents;
  final MonthlyTotals totals;
  final Map<Category, int> expensesByCategory;
  final Map<Category, double> categoryPercentages;
  final Map<Category, BudgetUsage> budgetByCategory;
  final BudgetUsage totalBudget;
  final int previousExpenseCents;
  final double? expenseVariationPercentage;
  final List<MonthlyTotals> evolution;
  final List<FinancialTransaction> history;
}
