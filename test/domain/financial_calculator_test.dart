import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_summary.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/models/monthly_budget.dart';
import 'package:bolsozen/domain/services/financial_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

FinancialSummary summary(
  List<FinancialTransaction> transactions, {
  List<MonthlyBudget> budgets = const [],
  FinancialMonth? month,
}) => FinancialCalculator.summarize(
  userId: 'A',
  month: month ?? FinancialMonth(2026, 11),
  transactions: transactions,
  budgets: budgets,
);

void main() {
  test('T1/T2: saldo, totais, categorias, orçamento e +600%', () {
    final s = summary(t1(), budgets: t2());
    expect(s.balanceCents, 60000);
    expect(s.totals.incomeCents, 100000);
    expect(s.totals.expenseCents, 35000);
    expect(s.previousExpenseCents, 5000);
    expect(s.expenseVariationPercentage, 600);
    expect(s.expensesByCategory, {
      Category.food: 25000,
      Category.transport: 10000,
    });
    expect(s.categoryPercentages[Category.food], closeTo(71.428571, .000001));
    expect(
      s.categoryPercentages[Category.transport],
      closeTo(28.571429, .000001),
    );
    expect(
      s.budgetByCategory[Category.food]!.percentage,
      closeTo(83.333333, .000001),
    );
    expect(s.budgetByCategory[Category.food]!.status, BudgetStatus.attention);
    expect(s.budgetByCategory[Category.transport]!.percentage, 50);
    expect(s.totalBudget.percentage, 70);
    expect(s.history.map((t) => t.id), [
      'transport',
      'food',
      'salary',
      'leisure',
    ]);
    final october = summary(t1(), month: FinancialMonth(2026, 10));
    expect(october.totals.expenseCents, 5000);
    expect(october.balanceCents, 60000);
  });
  test(
    'Sem dados: zero monetário, ausência de base e sem distribuição inventada',
    () {
      final s = summary([]);
      expect(s.balanceCents, 0);
      expect(s.totals.incomeCents, 0);
      expect(s.totals.expenseCents, 0);
      expect(s.expensesByCategory, isEmpty);
      expect(s.categoryPercentages, isEmpty);
      expect(s.totalBudget.percentage, isNull);
      expect(s.totalBudget.status, isNull);
      expect(s.expenseVariationPercentage, isNull);
      expect(s.evolution.every((m) => m.expenseCents == 0), isTrue);
    },
  );
  test('Saldos positivo, zero, negativo e centavo exato', () {
    expect(
      summary([
        transaction(category: Category.salary, amount: 2),
        transaction(amount: 1),
      ]).balanceCents,
      1,
    );
    expect(
      summary([transaction(category: Category.salary), transaction()])
          .balanceCents,
      0,
    );
    expect(summary([transaction(amount: 1)]).balanceCents, -1);
    expect(
      summary([
        transaction(category: Category.salary, amount: 9007199254740993),
      ]).balanceCents,
      9007199254740993,
    );
  });
  test('Futuro conta no saldo global e no mês da ocorrência, não criação', () {
    final items = [transaction(date: DateTime(2027, 1, 1), amount: 123)];
    expect(summary(items).balanceCents, -123);
    expect(summary(items).totals.expenseCents, 0);
    expect(
      summary(items, month: FinancialMonth(2027, 1)).totals.expenseCents,
      123,
    );
  });
  test(
    'Relatório tem seis meses cronológicos incluindo janeiro e dezembro',
    () {
      final s = summary([
        transaction(date: DateTime(2026, 12, 31), amount: 100),
        transaction(id: 'next', date: DateTime(2027, 1, 1), amount: 50),
      ], month: FinancialMonth(2027, 1));
      expect(s.evolution.map((m) => m.month.key), [
        '2026-08',
        '2026-09',
        '2026-10',
        '2026-11',
        '2026-12',
        '2027-01',
      ]);
      expect(s.evolution.map((m) => m.expenseCents), [0, 0, 0, 0, 100, 50]);
      expect(s.expenseVariationPercentage, -50);
    },
  );
  test(
    'Ordenação por ocorrência, criação e ID ascendente sem mutar entrada',
    () {
      final items = [
        transaction(id: 'b'),
        transaction(id: 'a'),
        transaction(id: 'new', created: DateTime(2026, 12)),
        transaction(id: 'future', date: DateTime(2027)),
      ];
      expect(summary(items).history.map((t) => t.id), [
        'future',
        'new',
        'a',
        'b',
      ]);
      expect(items.first.id, 'b');
    },
  );
  test('Edição, mudança de competência e exclusão recalculam CA-07', () {
    final items = t1();
    items[1] = items[1].copyWith(amountCents: 20000);
    final edited = summary(items, budgets: t2());
    expect(edited.balanceCents, 65000);
    expect(edited.totals.expenseCents, 30000);
    expect(
      edited.budgetByCategory[Category.food]!.percentage,
      closeTo(66.666667, .000001),
    );
    items[1] = items[1].copyWith(occurredAt: DateTime(2026, 10, 4));
    expect(summary(items).balanceCents, 65000);
    expect(summary(items).totals.expenseCents, 10000);
    expect(
      summary(items, month: FinancialMonth(2026, 10)).totals.expenseCents,
      25000,
    );
    items.removeWhere((t) => t.id == 'transport');
    expect(summary(items, budgets: t2()).balanceCents, 75000);
    expect(summary(items, budgets: t2()).totalBudget.percentage, 0);
  });
  test('Trocar tipo/categoria reflete saldo e remove gasto e participação', () {
    final item = transaction(amount: 100);
    final changed = item.copyWith(
      type: TransactionType.income,
      category: Category.salary,
    );
    expect(summary([changed]).balanceCents, 100);
    expect(summary([changed]).expensesByCategory, isEmpty);
  });
  for (final entry in {
    0: BudgetStatus.normal,
    7999: BudgetStatus.normal,
    8000: BudgetStatus.attention,
    9999: BudgetStatus.attention,
    10000: BudgetStatus.reached,
    12500: BudgetStatus.reached,
  }.entries) {
    test('Consumo ${entry.key / 100}% e sinalização correta', () {
      final s = summary(
        entry.key == 0 ? [] : [transaction(amount: entry.key)],
        budgets: [budget(limit: 10000)],
      );
      final usage = s.budgetByCategory[Category.food]!;
      expect(usage.status, entry.value);
      expect(usage.percentage, closeTo(entry.key / 100, .000001));
    });
  }
  test('Somente categorias limitadas compõem indicador global', () {
    final items = [
      ...t1(),
      transaction(id: 'unlimited', category: Category.shopping, amount: 500000),
    ];
    final s = summary(items, budgets: t2());
    expect(s.totalBudget.percentage, 70);
    expect(
      summary(items, budgets: [budget(limit: 20000)]).totalBudget.percentage,
      125,
    );
    expect(summary(items).totalBudget.percentage, isNull);
    expect(
      summary(
        items,
        budgets: t2(),
        month: FinancialMonth(2026, 12),
      ).budgetByCategory,
      isEmpty,
    );
    expect(summary(items).totals.expenseCents, s.totals.expenseCents);
  });
  test('Limites de outro mês/UID e transações de outro UID são ignorados', () {
    final s = summary(
      [...t1(), transaction(userId: 'B', amount: 999999)],
      budgets: [
        ...t2(),
        budget(userId: 'B'),
        budget(month: FinancialMonth(2026, 10)),
      ],
    );
    expect(s.balanceCents, 60000);
    expect(s.totalBudget.percentage, 70);
    expect(s.history, hasLength(4));
  });
  test('Duplicação de limite é recusada em vez de alterar indicador silenciosamente', () {
    expect(
      () => summary(t1(), budgets: [budget(), budget()]),
      throwsArgumentError,
    );
  });
  test('Sem base anterior resulta null; queda total resulta -100%', () {
    expect(summary([transaction()]).expenseVariationPercentage, isNull);
    expect(
      summary([transaction(date: DateTime(2026, 10, 1))])
          .expenseVariationPercentage,
      -100,
    );
  });
  test('Resultados não permitem mutação', () {
    final s = summary(t1(), budgets: t2());
    expect(() => s.history.clear(), throwsUnsupportedError);
    expect(() => s.evolution.clear(), throwsUnsupportedError);
    expect(() => s.expensesByCategory.clear(), throwsUnsupportedError);
    expect(() => s.categoryPercentages.clear(), throwsUnsupportedError);
    expect(() => s.budgetByCategory.clear(), throwsUnsupportedError);
  });
  test(
    'Excesso do inteiro nativo não pode gerar saldo silenciosamente incorreto',
    () {
      expect(
        () => summary([
          transaction(category: Category.salary, amount: 9223372036854775807),
          transaction(id: 'extra', category: Category.salary, amount: 1),
        ]),
        throwsStateError,
      );
    },
  );
}
