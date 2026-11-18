import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/presentation/services/financial_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../domain/fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  final source = [
    transaction(
      id: 'first',
      category: Category.salary,
      description: 'Salário principal',
      date: DateTime(2027, 1, 1),
    ),
    transaction(
      id: 'food',
      description: 'Feira 🍎',
      date: DateTime(2026, 12, 31),
    ),
    transaction(
      id: 'transport',
      category: Category.transport,
      description: 'Ônibus',
      date: DateTime(2026, 12, 30),
    ),
  ];
  for (final query in ['FEIRA', '  fei  ', '🍎']) {
    test('Busca parcial descrição $query, case/trim/Unicode', () {
      expect(
        FinancialProjection.filterHistory(
          source,
          query: query,
        ).map((t) => t.id),
        ['food'],
      );
    });
  }
  for (final query in [
    'Alimentação',
    'alimentacao',
    '  ALIMENTACAO ',
    'Alimentac\u0327a\u0303o',
  ]) {
    test('Busca por categoria com acentos/precompostos/combinados: $query', () {
      expect(
        FinancialProjection.filterHistory(
          source,
          query: query,
        ).map((t) => t.id),
        ['food'],
      );
    });
  }
  test('Tipo E categoria E busca; descrição OU categoria', () {
    expect(
      FinancialProjection.filterHistory(
        source,
        type: TransactionType.expense,
        category: Category.food,
        query: 'feira',
      ).map((t) => t.id),
      ['food'],
    );
    expect(
      FinancialProjection.filterHistory(
        source,
        type: TransactionType.expense,
        category: Category.food,
        query: 'salario',
      ),
      isEmpty,
    );
    expect(
      FinancialProjection.filterHistory(
        source,
        type: TransactionType.income,
        category: Category.food,
      ),
      isEmpty,
    );
    expect(
      FinancialProjection.filterHistory(source, query: 'feira alimentacao'),
      isEmpty,
    );
    expect(
      FinancialProjection.filterHistory(
        source,
        type: TransactionType.income,
      ).map((t) => t.id),
      ['first'],
    );
    expect(
      FinancialProjection.filterHistory(
        source,
        type: TransactionType.expense,
      ).map((t) => t.id),
      ['food', 'transport'],
    );
  });
  test('Todas não remove texto/categoria; nenhuma mutação ou reordenação', () {
    final reverse = source.reversed.toList();
    final all = FinancialProjection.filterHistory(reverse, query: ' ');
    expect(all, reverse);
    expect(identical(all.first, reverse.first), isTrue);
    expect(() => all.clear(), throwsUnsupportedError);
    expect(reverse.length, 3);
    expect(
      FinancialProjection.filterHistory(
        source,
        category: Category.food,
        query: 'feira',
      ).single.id,
      'food',
    );
  });
  test('Busca alcança o registro 201 sem truncar à primeira página', () {
    final rows = List.generate(
      201,
      (i) => transaction(
        id: '$i',
        description: i == 200 ? 'Último registro' : 'Outro',
      ),
    );
    expect(
      FinancialProjection.filterHistory(rows, query: 'ultimo').single.id,
      '200',
    );
    expect(rows.length, 201);
  });
  test(
    'Agrupa somente após filtro, sem cabeçalhos vazios, virada de mês/ano',
    () {
      final rows = FinancialProjection.historyRows(
        FinancialProjection.filterHistory(
          source,
          type: TransactionType.expense,
        ),
        today: DateTime(2027, 1, 1),
      );
      expect(rows.where((r) => r.heading != null).map((r) => r.heading), [
        'Ontem, 31 de dez. de 2026',
        '30 de dez. de 2026',
      ]);
      expect(
        rows.where((r) => r.transaction != null).map((r) => r.transaction!.id),
        ['food', 'transport'],
      );
      expect(
        FinancialProjection.historyRows(
          FinancialProjection.filterHistory(source, query: 'inexistente'),
          today: DateTime(2027),
        ),
        isEmpty,
      );
    },
  );
}
