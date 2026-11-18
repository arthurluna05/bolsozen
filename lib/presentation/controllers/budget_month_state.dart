import '../../data/firebase/data_failure.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/monthly_budget.dart';

enum BudgetPhase { idle, loading, ready, empty, refreshing, error }

/// Snapshot de apresentação; null não equivale a uma consulta vazia confirmada.
final class BudgetMonthState {
  BudgetMonthState({
    required this.userId,
    required this.month,
    required this.available,
    required this.phase,
    List<MonthlyBudget>? limits,
    this.summary,
    this.failure,
    this.lastConfirmedAt,
    this.isStale = false,
  }) : limits = limits == null ? null : List.unmodifiable(limits);

  final String userId;
  final FinancialMonth month;
  final bool available;
  final BudgetPhase phase;
  final List<MonthlyBudget>? limits;
  final FinancialSummary? summary;
  final DataFailure? failure;
  final DateTime? lastConfirmedAt;
  final bool isStale;
  bool get hasConfirmedLimits => limits != null;
  bool get hasConfirmedUsage =>
      available && summary != null && failure == null && !isStale;
  BudgetUsage? get totalBudget => summary?.totalBudget;
}
