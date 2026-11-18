import '../models/category.dart';
import '../models/financial_month.dart';
import '../models/financial_summary.dart';
import '../models/financial_transaction.dart';
import '../models/monthly_budget.dart';
import 'money.dart';

abstract final class FinancialCalculator {
  /// Entrada deve conter o histórico completo carregado, sem páginas faltantes.
  /// Dados de outros usuários são ignorados, inclusive limites.
  static FinancialSummary summarize({
    required String userId,
    required FinancialMonth month,
    required Iterable<FinancialTransaction> transactions,
    Iterable<MonthlyBudget> budgets = const [],
  }) {
    if (userId.trim().isEmpty) throw ArgumentError('Usuário obrigatório');
    final history = transactions.where((item) => item.userId == userId).toList()
      ..sort((a, b) {
        final date = b.occurredAt.compareTo(a.occurredAt);
        if (date != 0) return date;
        final creation = b.createdAt.compareTo(a.createdAt);
        return creation != 0 ? creation : a.id.compareTo(b.id);
      });
    MonthlyTotals totalsFor(FinancialMonth target) => MonthlyTotals(
      target,
      _sum(
        history
            .where(
              (t) =>
                  target.contains(t.occurredAt) &&
                  t.type == TransactionType.income,
            )
            .map((t) => t.amountCents),
      ),
      _sum(
        history
            .where(
              (t) =>
                  target.contains(t.occurredAt) &&
                  t.type == TransactionType.expense,
            )
            .map((t) => t.amountCents),
      ),
    );
    final totals = totalsFor(month);
    final expenses = <Category, int>{};
    for (final t in history.where(
      (t) => month.contains(t.occurredAt) && t.type == TransactionType.expense,
    )) {
      expenses[t.category] = _sum([expenses[t.category] ?? 0, t.amountCents]);
    }
    final usage = <Category, BudgetUsage>{};
    for (final budget in budgets.where(
      (b) => b.userId == userId && b.month == month,
    )) {
      if (usage.containsKey(budget.category)) {
        throw ArgumentError('Limite duplicado para a mesma categoria e mês');
      }
      usage[budget.category] = BudgetUsage(
        expenses[budget.category] ?? 0,
        budget.limitCents,
      );
    }
    final previous = totalsFor(month.shift(-1)).expenseCents;
    return FinancialSummary(
      balanceCents: _sum(
        history.map(
          (t) =>
              t.type == TransactionType.income ? t.amountCents : -t.amountCents,
        ),
      ),
      totals: totals,
      expensesByCategory: expenses,
      categoryPercentages: {
        for (final entry in expenses.entries)
          entry.key: entry.value / totals.expenseCents * 100,
      },
      budgetByCategory: usage,
      totalBudget: BudgetUsage(
        _sum(usage.values.map((u) => u.consumedCents)),
        _sum(usage.values.map((u) => u.limitCents)),
      ),
      previousExpenseCents: previous,
      expenseVariationPercentage: previous == 0
          ? null
          : (totals.expenseCents - previous) / previous * 100,
      evolution: List.generate(6, (index) => totalsFor(month.shift(index - 5))),
      history: history,
    );
  }

  // Não permitir wrap silencioso do inteiro nativo em agregações monetárias.
  static int _sum(Iterable<int> values) {
    final total = values.fold(BigInt.zero, (sum, value) {
      if (Money.isJavaScript) Money.requireSafeCents(value);
      return sum + BigInt.from(value);
    });
    if (Money.isJavaScript && total.abs() > BigInt.from(Money.maxSafeCents)) {
      throw StateError('Total excede a precisão monetária suportada na Web');
    }
    final result = total.toInt();
    if (BigInt.from(result) != total) {
      throw StateError('Total excede a precisão inteira suportada');
    }
    return result;
  }
}
