import 'package:bolsozen/domain/services/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/services/financial_calculator.dart';

import 'fixtures.dart';

void main() {
  for (final input in [
    '90071992547409,92',
    '90071992547409,93',
    '90071992547409,94',
    '90071992547409,95',
    'R\$ 90.071.992.547.409,93',
    '999999999999999999999999999999999999',
  ]) {
    test('Rejeita texto fora da faixa interoperável: $input', () {
      expect(() => Money.parseCents(input), throwsFormatException);
    });
  }
  test('Erro de precisão orienta usuário sem arredondar', () {
    expect(
      () => Money.parseCents('90071992547409,93'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('precisão suportada'),
        ),
      ),
    );
  });
  test('Fronteira numérica recusa ambos os sinais e aceita limite', () {
    Money.requireSafeCents(Money.maxSafeCents);
    Money.requireSafeCents(-Money.maxSafeCents);
    expect(
      () => Money.requireSafeCents(Money.maxSafeCents + 1),
      throwsFormatException,
    );
    expect(
      () => Money.requireSafeCents(-Money.maxSafeCents - 1),
      throwsFormatException,
    );
  });
  test('Formatação maior é exata somente na plataforma nativa', () {
    final value = int.parse('9007199254740993');
    if (Money.isJavaScript) {
      expect(() => Money.formatCents(value), throwsFormatException);
      expect(() => Money.formatCents(-value), throwsFormatException);
    } else {
      expect(Money.formatCents(value), 'R\$ 90.071.992.547.409,93');
      expect(Money.formatCents(-value), '-R\$ 90.071.992.547.409,93');
    }
  });
  for (final category in [Category.salary, Category.food]) {
    test('Agregado acima da fronteira: ${category.id}', () {
      calculate() => FinancialCalculator.summarize(
        userId: 'A',
        month: FinancialMonth(2026, 11),
        transactions: [
          transaction(category: category, amount: Money.maxSafeCents),
          transaction(id: 'extra', category: category, amount: 2),
        ],
      );
      if (Money.isJavaScript) {
        expect(calculate, throwsStateError);
      } else {
        final result = calculate();
        expect(
          BigInt.from(result.balanceCents).abs(),
          BigInt.parse('9007199254740993'),
        );
      }
    });
  }
  for (final entry in {
    '0,01': '1',
    '120': '12000',
    'R\$ 1.234,56': '123456',
    '90071992547409,90': '9007199254740990',
    '90071992547409,91': '9007199254740991',
    'R\$ 90.071.992.547.409,91': '9007199254740991',
  }.entries) {
    test('Preserva texto de centavos representável ${entry.value}', () {
      final cents = Money.parseCents(entry.key);
      expect(BigInt.from(cents), BigInt.parse(entry.value));
      expect(
        BigInt.from(Money.parseCents(Money.formatCents(cents))),
        BigInt.parse(entry.value),
      );
    });
  }
  test('Formatação próxima à fronteira também preserva sinal negativo', () {
    final value = int.parse('9007199254740991');
    expect(Money.formatCents(-value), '-R\$ 90.071.992.547.409,91');
  });
}
