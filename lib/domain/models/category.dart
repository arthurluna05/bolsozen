enum TransactionType { income, expense }

/// Catálogo fechado do MVP; nomes de enum não são IDs persistidos.
enum Category {
  food('food', 'Alimentação', TransactionType.expense),
  transport('transport', 'Transporte', TransactionType.expense),
  shopping('shopping', 'Compras', TransactionType.expense),
  leisure('leisure', 'Lazer', TransactionType.expense),
  health('health', 'Saúde', TransactionType.expense),
  education('education', 'Educação', TransactionType.expense),
  housing('housing', 'Moradia', TransactionType.expense),
  otherExpense('other_expense', 'Outros', TransactionType.expense),
  salary('salary', 'Salário', TransactionType.income),
  otherIncome('other_income', 'Outras receitas', TransactionType.income);

  const Category(this.id, this.label, this.type);
  final String id;
  final String label;
  final TransactionType type;

  static Category fromId(String id) => values.firstWhere(
    (category) => category.id == id,
    orElse: () =>
        throw ArgumentError.value(id, 'categoryId', 'Categoria inválida'),
  );

  static List<Category> forType(TransactionType type) =>
      List.unmodifiable(values.where((category) => category.type == type));
}
