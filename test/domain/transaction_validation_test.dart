import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/services/transaction_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Entrada monetária pt-BR reutiliza Money sem arredondar', () {
    for (final value in [
      '0,01',
      '120',
      'R\$ 1.234,56',
      '90.071.992.547.409,91',
    ]) {
      expect(TransactionValidation.amount(value), isNull);
    }
    for (final value in ['', '0', '-1', '90071992547409,93']) {
      expect(TransactionValidation.amount(value), isNotNull);
    }
  });
  test('Descrição usa runes, trim e não trunca Unicode', () {
    expect(TransactionValidation.description('   '), isNotNull);
    expect(TransactionValidation.description('  Café 😊  '), isNull);
    expect(
      TransactionValidation.description(List.filled(120, 'á').join()),
      isNull,
    );
    expect(
      TransactionValidation.description(List.filled(121, 'á').join()),
      isNotNull,
    );
    expect(
      TransactionValidation.description(List.filled(61, 'e\u0301').join()),
      isNotNull,
    );
  });
  test('Categoria deve existir e corresponder ao tipo', () {
    expect(
      TransactionValidation.category(null, TransactionType.income),
      isNotNull,
    );
    expect(
      TransactionValidation.category(Category.food, TransactionType.income),
      isNotNull,
    );
    expect(
      TransactionValidation.category(Category.salary, TransactionType.income),
      isNull,
    );
  });
}
