import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/models/monthly_budget.dart';

FinancialTransaction transaction({
  String id = 't',
  String userId = 'A',
  int amount = 100,
  Category category = Category.food,
  DateTime? date,
  DateTime? created,
  String description = 'Teste',
}) => FinancialTransaction(
  id: id,
  userId: userId,
  type: category.type,
  amountCents: amount,
  category: category,
  description: description,
  occurredAt: date ?? DateTime(2026, 11, 4),
  createdAt: created ?? DateTime(2026, 11, 10),
  updatedAt: DateTime(2026, 11, 10),
);

MonthlyBudget budget({
  Category category = Category.food,
  int limit = 30000,
  String userId = 'A',
  FinancialMonth? month,
}) => MonthlyBudget(
  userId: userId,
  month: month ?? FinancialMonth(2026, 11),
  category: category,
  limitCents: limit,
  createdAt: DateTime(2026, 11),
  updatedAt: DateTime(2026, 11),
);

List<FinancialTransaction> t1() => [
  transaction(
    id: 'salary',
    category: Category.salary,
    amount: 100000,
    date: DateTime(2026, 11, 3),
  ),
  transaction(id: 'food', amount: 25000),
  transaction(
    id: 'transport',
    category: Category.transport,
    amount: 10000,
    date: DateTime(2026, 11, 5),
  ),
  transaction(
    id: 'leisure',
    category: Category.leisure,
    amount: 5000,
    date: DateTime(2026, 10, 12),
  ),
];
List<MonthlyBudget> t2() => [
  budget(),
  budget(category: Category.transport, limit: 20000),
];
