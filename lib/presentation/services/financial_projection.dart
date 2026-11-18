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
  /// Projeção local: mantém itens/ordem do snapshot, sem cálculos ou consultas.
  static List<FinancialTransaction> filterHistory(
    List<FinancialTransaction> history, {
    String query = '',
    TransactionType? type,
    Category? category,
  }) {
    final key = _searchKey(query);
    return List.unmodifiable(
      history.where(
        (item) =>
            (type == null || item.type == type) &&
            (category == null || item.category == category) &&
            (key.isEmpty ||
                _searchKey(item.description).contains(key) ||
                _searchKey(item.category.label).contains(key)),
      ),
    );
  }

  // Português/latim básico; não modifica dados armazenados ou rótulos exibidos.
  static String _searchKey(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .split('')
        .map((char) => accents[char] ?? char)
        .join();
  }

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
