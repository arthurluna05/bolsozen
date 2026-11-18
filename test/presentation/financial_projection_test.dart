import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/services/financial_calculator.dart';
import 'package:bolsozen/presentation/services/financial_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../domain/fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  test('Participação usa percentuais do domínio, não consumo de orçamento', () {
    final summary = FinancialCalculator.summarize(
      userId: 'A',
      month: FinancialMonth(2026, 11),
      transactions: t1(),
      budgets: t2(),
    );
    final spending = FinancialProjection.spending(summary);
    expect(spending.map((e) => e.category), [
      Category.food,
      Category.transport,
    ]);
    expect(spending.first.percentage, '71,4%');
    expect(
      spending.first.proportion,
      closeTo(summary.categoryPercentages[Category.food]! / 100, 0.000001),
    );
    expect(spending.first.percentage, isNot('83,3%'));
    expect(summary.totalBudget.percentage, 70);
  });
  test('Recente é projeção imutável do primeiro registro já ordenado, sem cortar histórico', () {
    final summary = FinancialCalculator.summarize(
      userId: 'A',
      month: FinancialMonth(2026, 11),
      transactions: t1(),
    );
    final recent = FinancialProjection.recent(summary.history);
    expect(recent.single, same(summary.history.first));
    expect(summary.history, hasLength(4));
    expect(() => recent.clear(), throwsUnsupportedError);
  });
  test('Cabeçalhos Hoje/Ontem/outro dia preservam ordem e identidades na virada do ano', () {
    final data = [
      transaction(id: 'a', date: DateTime(2027, 1, 1, 15)),
      transaction(id: 'b', date: DateTime(2027, 1, 1)),
      transaction(id: 'c', date: DateTime(2026, 12, 31)),
      transaction(id: 'd', date: DateTime(2026, 12, 30)),
    ];
    final rows = FinancialProjection.historyRows(
      data,
      today: DateTime(2027, 1, 1, 18),
    );
    expect(rows.where((r) => r.heading != null).map((r) => r.heading), [
      'Hoje, 1 de jan. de 2027',
      'Ontem, 31 de dez. de 2026',
      '30 de dez. de 2026',
    ]);
    expect(
      rows.where((r) => r.transaction != null).map((r) => r.transaction),
      data,
    );
    expect(
      rows.every((r) => (r.heading == null) != (r.transaction == null)),
      isTrue,
    );
    expect(() => rows.clear(), throwsUnsupportedError);
  });
  test(
    'Vazio não fabrica categoria, percentual, grupo ou transação recente',
    () {
      final summary = FinancialCalculator.summarize(
        userId: 'A',
        month: FinancialMonth(2026, 11),
        transactions: const [],
      );
      expect(FinancialProjection.spending(summary), isEmpty);
      expect(FinancialProjection.recent(summary.history), isEmpty);
      expect(
        FinancialProjection.historyRows(
          summary.history,
          today: DateTime(2026, 11, 5),
        ),
        isEmpty,
      );
    },
  );
}
