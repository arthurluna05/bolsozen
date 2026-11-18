import 'package:intl/intl.dart';

import '../../domain/models/financial_summary.dart';

/// Apenas formatação/projeção gráfica; os cálculos vêm do domínio.
abstract final class BudgetPresentation {
  static String percentage(BudgetUsage usage) =>
      '${NumberFormat('0.##', 'pt_BR').format(usage.percentage)}%';

  static double progress(BudgetUsage usage) =>
      ((usage.percentage ?? 0) / 100).clamp(0.0, 1.0);

  static String status(BudgetUsage usage) => switch (usage.status) {
    BudgetStatus.normal => 'Dentro do limite',
    BudgetStatus.attention => 'Atenção ao limite',
    BudgetStatus.reached => 'Limite atingido ou excedido',
    null => 'Sem limite',
  };
}
