import '../../data/firebase/data_failure.dart';
import '../../domain/models/category.dart';
import '../../domain/models/financial_month.dart';

enum BudgetSubmissionStatus {
  confirmed,
  partial,
  refreshPending,
  failed,
  uncertain,
  busy,
  sessionInvalidated,
}

/// Resultado local do salvamento sequencial; null em um valor significa remoção.
final class BudgetSubmissionResult {
  BudgetSubmissionResult({
    required this.month,
    required this.status,
    Map<Category, int?> confirmed = const {},
    Map<Category, int?> pending = const {},
    Set<Category> uncertain = const {},
    this.needsRead = false,
    this.failure,
  }) : confirmed = Map.unmodifiable(confirmed),
       pending = Map.unmodifiable(pending),
       uncertain = Set.unmodifiable(uncertain);
  final FinancialMonth month;
  final BudgetSubmissionStatus status;
  final Map<Category, int?> confirmed, pending;
  final Set<Category> uncertain;
  final bool needsRead;
  final DataFailure? failure;
}
