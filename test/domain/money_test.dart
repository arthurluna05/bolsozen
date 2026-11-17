import 'package:bolsozen/domain/services/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final valid = {
    '120': 12000,
    '120,50': 12050,
    'R\$ 120,50': 12050,
    '1.234,56': 123456,
    '0,01': 1,
    '0,1': 10,
    '  R\$\u00a01.234,50  ': 123450,
    '0001,01': 101,
    '90071992547409,93': 9007199254740993,
  };
  for (final entry in valid.entries) {
    test(
      'Parsing exato ${entry.key}',
      () => expect(Money.parseCents(entry.key), entry.value),
    );
  }
  for (final input in [
    '',
    '0',
    '0,00',
    '-1',
    '+1',
    '1.23',
    '12.34,56',
    '1,234',
    '1,',
    ',50',
    '1e3',
    'NaN',
    'Infinity',
    'R\$',
    '1 000',
    '1,2,3',
    '999999999999999999999999999999999999',
  ]) {
    test(
      'Rejeita entrada $input',
      () => expect(() => Money.parseCents(input), throwsFormatException),
    );
  }
  test('Formata zero, sinal, agrupamento e centavos exatos', () {
    expect(Money.formatCents(0), 'R\$ 0,00');
    expect(Money.formatCents(1), 'R\$ 0,01');
    expect(Money.formatCents(-123456), '-R\$ 1.234,56');
    expect(Money.formatCents(9007199254740993), 'R\$ 90.071.992.547.409,93');
    for (final cents in [1, 10, 101, 123456, 9007199254740993]) {
      expect(Money.parseCents(Money.formatCents(cents)), cents);
    }
  });
}
