import 'package:intl/intl.dart';

import '../../domain/models/category.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/services/financial_calculator.dart';

typedef ReportCategory = ({
  Category category,
  int cents,
  int count,
  double percentage,
});
typedef ReportMonth = ({FinancialMonth month, int cents, double? variation});

/// Deriva detalhes do relatório de um snapshot completo, sem novas leituras.
final class ReportProjection {
  ReportProjection(FinancialSummary summary, {required String userId}) {
    final counts = <Category, int>{};
    for (final item in summary.history) {
      if (item.userId == userId &&
          item.type == TransactionType.expense &&
          summary.totals.month.contains(item.occurredAt)) {
        counts.update(item.category, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final entries = summary.expensesByCategory.entries.toList()
      ..sort((a, b) {
        final amount = b.value.compareTo(a.value);
        return amount != 0 ? amount : a.key.id.compareTo(b.key.id);
      });
    categories = List.unmodifiable(
      entries.map(
        (e) => (
          category: e.key,
          cents: e.value,
          count: counts[e.key] ?? 0,
          percentage: summary.categoryPercentages[e.key]!,
        ),
      ),
    );
    final first = summary.evolution.first.month;
    var previous = FinancialCalculator.summarize(
      userId: userId,
      month: first,
      transactions: summary.history,
    ).previousExpenseCents;
    final months = <ReportMonth>[];
    var sum = BigInt.zero;
    for (final total in summary.evolution) {
      months.add((
        month: total.month,
        cents: total.expenseCents,
        variation: FinancialCalculator.compareExpenses(
          total.expenseCents,
          previous,
        ),
      ));
      previous = total.expenseCents;
      sum += BigInt.from(total.expenseCents);
    }
    evolution = List.unmodifiable(months);
    // Média dos seis meses, incluindo zeros confirmados, arredondada ao centavo.
    final divisor = BigInt.from(months.length);
    averageCents = ((sum + divisor ~/ BigInt.two) ~/ divisor).toInt();
    maximum = months.reduce((a, b) => a.cents >= b.cents ? a : b);
    minimum = months.reduce((a, b) => a.cents <= b.cents ? a : b);
  }

  late final List<ReportCategory> categories;
  late final List<ReportMonth> evolution;
  late final int averageCents;
  late final ReportMonth maximum, minimum;

  static String percentage(double value) =>
      '${NumberFormat('0.##', 'pt_BR').format(value)}%';
  static String variation(double? value) => value == null
      ? 'Sem base de comparação'
      : '${value > 0 ? '+' : ''}${percentage(value)}';
  static String monthLabel(FinancialMonth month, {bool short = false}) =>
      DateFormat(
        short ? 'MMM' : 'MMMM yyyy',
        'pt_BR',
      ).format(DateTime(month.year, month.month));

  /// Marcas exatas do eixo, em centavos; double apenas nas coordenadas.
  static List<int> axisTicks(List<ReportMonth> months) {
    final max = months.fold(
      0,
      (value, item) => item.cents > value ? item.cents : value,
    );
    if (max == 0) return const [0];
    return List.generate(
      5,
      (i) => (BigInt.from(max) * BigInt.from(i) ~/ BigInt.from(4)).toInt(),
    );
  }
}
