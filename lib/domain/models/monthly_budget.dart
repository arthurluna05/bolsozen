import 'category.dart';
import 'financial_month.dart';

final class MonthlyBudget {
  MonthlyBudget({
    required this.userId,
    required this.month,
    required this.category,
    required this.limitCents,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (userId.trim().isEmpty) throw ArgumentError('Usuário obrigatório');
    if (category.type != TransactionType.expense) {
      throw ArgumentError('Limite exige categoria de despesa');
    }
    if (limitCents <= 0) throw ArgumentError.value(limitCents, 'limitCents');
  }

  final String userId;
  final FinancialMonth month;
  final Category category;
  final int limitCents;
  final DateTime createdAt;
  final DateTime updatedAt;
  String get id => '${month.key}_${category.id}';
}
