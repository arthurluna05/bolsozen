import 'category.dart';

final class FinancialTransaction {
  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountCents,
    required this.category,
    required String description,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  }) : description = description.trim() {
    if (id.trim().isEmpty || userId.trim().isEmpty) {
      throw ArgumentError('Identificadores obrigatórios');
    }
    if (amountCents <= 0) throw ArgumentError.value(amountCents, 'amountCents');
    if (category.type != type) {
      throw ArgumentError('Categoria incompatível com o tipo');
    }
    if (this.description.isEmpty || this.description.runes.length > 120) {
      throw ArgumentError('Descrição deve conter de 1 a 120 caracteres');
    }
  }

  final String id;
  final String userId;
  final TransactionType type;
  final int amountCents;
  final Category category;
  final String description;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialTransaction copyWith({
    TransactionType? type,
    int? amountCents,
    Category? category,
    String? description,
    DateTime? occurredAt,
    DateTime? updatedAt,
  }) => FinancialTransaction(
    id: id,
    userId: userId,
    type: type ?? this.type,
    amountCents: amountCents ?? this.amountCents,
    category: category ?? this.category,
    description: description ?? this.description,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
