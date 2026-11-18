import '../models/category.dart';
import 'money.dart';

/// Validação de entrada; não cria IDs, auditoria ou um segundo modelo monetário.
abstract final class TransactionValidation {
  static String? amount(String value) {
    try {
      Money.parseCents(value);
    } on FormatException catch (error) {
      return error.message;
    }
    return null;
  }

  static String? description(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Informe a descrição.';
    if (text.runes.length > 120) return 'Use até 120 caracteres na descrição.';
    return null;
  }

  static String? category(Category? value, TransactionType type) =>
      value == null || value.type != type
      ? 'Selecione uma categoria compatível.'
      : null;

  static void check({
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  }) {
    Money.requireSafeCents(amountCents);
    if (amountCents <= 0 ||
        category.type != type ||
        TransactionValidation.description(description) != null ||
        occurredAt.year < 1 ||
        occurredAt.year > 9999) {
      throw const FormatException('Confira os campos da transação.');
    }
  }
}
