import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('Catálogo contém exatamente os IDs e tipos documentados', () {
    expect(Category.values.map((c) => c.id), [
      'food',
      'transport',
      'shopping',
      'leisure',
      'health',
      'education',
      'housing',
      'other_expense',
      'salary',
      'other_income',
    ]);
    expect(Category.forType(TransactionType.expense), hasLength(8));
    expect(Category.forType(TransactionType.income), [
      Category.salary,
      Category.otherIncome,
    ]);
    expect(Category.fromId('food').label, 'Alimentação');
    expect(() => Category.fromId('unknown'), throwsArgumentError);
    expect(
      () => Category.forType(TransactionType.expense).clear(),
      throwsUnsupportedError,
    );
  });
  test('Transação valida valor, descrição e identificadores', () {
    for (final amount in [0, -1]) {
      expect(() => transaction(amount: amount), throwsArgumentError);
    }
    expect(() => transaction(id: ' '), throwsArgumentError);
    expect(() => transaction(userId: ''), throwsArgumentError);
    expect(() => transaction(description: '  '), throwsArgumentError);
    expect(() => transaction(description: 'a' * 121), throwsArgumentError);
    expect(transaction(description: '  Mercado  ').description, 'Mercado');
    expect(transaction(description: 'a' * 120).description.length, 120);
    expect(transaction(amount: 1).amountCents, 1);
  });
  test('Cópia imutável revalida categoria e preserva identidade/auditoria', () {
    final original = transaction();
    expect(
      () => original.copyWith(type: TransactionType.income),
      throwsArgumentError,
    );
    final changed = original.copyWith(
      type: TransactionType.income,
      category: Category.salary,
      amountCents: 200,
    );
    expect(original.amountCents, 100);
    expect(changed.amountCents, 200);
    expect(changed.id, original.id);
    expect(changed.userId, original.userId);
    expect(changed.createdAt, original.createdAt);
  });
  test('Limite positivo apenas para despesa, chave mensal determinística', () {
    expect(() => budget(limit: 0), throwsArgumentError);
    expect(() => budget(limit: -1), throwsArgumentError);
    expect(() => budget(category: Category.salary), throwsArgumentError);
    expect(() => budget(userId: ''), throwsArgumentError);
    expect(budget().id, '2026-11_food');
  });
  test('Competência valida mês, igualdade e mudança de ano', () {
    expect(() => FinancialMonth(2026, 0), throwsArgumentError);
    expect(() => FinancialMonth(2026, 13), throwsArgumentError);
    expect(FinancialMonth(2026, 12).shift(1), FinancialMonth(2027, 1));
    expect(FinancialMonth(2026, 1).shift(-1).key, '2025-12');
    expect({FinancialMonth(2026, 11), FinancialMonth(2026, 11)}, hasLength(1));
  });
  test('Data UTC agrupada pelo calendário local, inclusive borda mensal', () {
    final utc = DateTime.utc(2027, 1, 1, 1);
    final local = utc.toLocal();
    expect(
      FinancialMonth.fromDate(utc),
      FinancialMonth(local.year, local.month),
    );
    expect(FinancialMonth(local.year, local.month).contains(utc), isTrue);
  });
}
