import 'package:intl/intl.dart';

import '../../domain/models/category.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/financial_transaction.dart';

typedef FinancialHistoryRow = ({
  String? heading,
  FinancialTransaction? transaction,
});
typedef CategorySpendingView = ({
  Category category,
  double proportion,
  String percentage,
});

/// Projeção visual de dados confirmados. Nenhuma consulta ou fórmula financeira.
abstract final class FinancialProjection {
  // A prancha TEL-04 mostra um lançamento na área recente; histórico não é cortado.
  static List<FinancialTransaction> recent(
    List<FinancialTransaction> history,
  ) => List.unmodifiable(history.take(1));

  static List<CategorySpendingView> spending(FinancialSummary summary) {
    final entries = summary.categoryPercentages.entries.toList()
      ..sort((a, b) {
        final value = b.value.compareTo(a.value);
        return value != 0 ? value : a.key.id.compareTo(b.key.id);
      });
    final format = NumberFormat('0.#', 'pt_BR');
    return List.unmodifiable(
      entries.map(
        (e) => (
          category: e.key,
          proportion: (e.value / 100).clamp(0.0, 1.0),
          percentage: '${format.format(e.value)}%',
        ),
      ),
    );
  }

  /// Apenas cabeçalhos entre dias locais adjacentes do histórico já ordenado.
  /// Cada registro retornado contém heading OU transaction, nunca ambos.
  static List<FinancialHistoryRow> historyRows(
    List<FinancialTransaction> history, {
    required DateTime today,
  }) {
    final now = today.toLocal();
    final currentDay = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    DateTime? previousDay;
    final rows = <FinancialHistoryRow>[];
    for (final transaction in history) {
      final local = transaction.occurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (day != previousDay) {
        final prefix = day == currentDay
            ? 'Hoje, '
            : day == yesterday
            ? 'Ontem, '
            : '';
        rows.add((
          heading:
              '$prefix${DateFormat("d 'de' MMM 'de' yyyy", 'pt_BR').format(day)}',
          transaction: null,
        ));
        previousDay = day;
      }
      rows.add((heading: null, transaction: transaction));
    }
    return List.unmodifiable(rows);
  }
}
