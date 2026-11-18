// Fakes exclusivamente de testes/preview; sem Firebase ou persistência.
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:bolsozen/domain/repositories/transaction_repository.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:bolsozen/domain/services/financial_calculator.dart';

import '../domain/fixtures.dart';
import 'session_fakes.dart';

typedef TransactionDraftFixture = ({
  TransactionType type,
  int amountCents,
  Category category,
  String description,
  DateTime occurredAt,
  String? uid,
});

class FinancialTransactionsFake implements TransactionRepository {
  String uid = 'financial-test';
  List<FinancialTransaction> source = [];
  int reads = 0;
  Future<List<FinancialTransaction>> Function()? read;
  final writes = <TransactionDraftFixture>[];
  Future<String> Function(TransactionDraftFixture draft)? write;

  @override
  Future<List<FinancialTransaction>> fetchPage({
    FinancialTransaction? after,
    int limit = 100,
    String? expectedUserId,
  }) async {
    reads++;
    if (expectedUserId != uid) {
      throw const DataFailure(
        DataFailureKind.sessionChanged,
        'Sessão alterada.',
      );
    }
    if (read != null) return read!();
    final start = after == null
        ? 0
        : source.indexWhere((t) => t.id == after.id) + 1;
    return source.skip(start).take(limit).toList();
  }

  @override
  Future<String> create({
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
    String? expectedUserId,
  }) async {
    final draft = (
      type: type,
      amountCents: amountCents,
      category: category,
      description: description,
      occurredAt: occurredAt,
      uid: expectedUserId,
    );
    writes.add(draft);
    if (expectedUserId != uid) {
      throw const DataFailure(
        DataFailureKind.sessionChanged,
        'Sessão alterada.',
      );
    }
    if (write != null) return write!(draft);
    final id = 'created-${writes.length}';
    source = FinancialCalculator.summarize(
      userId: uid,
      month: FinancialMonth(2026, 11),
      transactions: [
        ...source,
        transaction(
          id: id,
          userId: uid,
          amount: amountCents,
          category: category,
          description: description,
          date: occurredAt,
        ),
      ],
    ).history;
    return id;
  }

  @override
  Future<void> update(FinancialTransaction transaction) =>
      throw UnsupportedError('Preview somente leitura');
  @override
  Future<void> delete(String id) =>
      throw UnsupportedError('Preview somente leitura');
}

class FinancialTestHarness {
  final session = SessionHarness();
  final repository = FinancialTransactionsFake();
  late final FinancialController controller;
  UserProfile get profile => session.users.profiles[repository.uid]!;

  Future<void> start({String name = 'Pessoa de teste'}) async {
    session.users.profiles[repository.uid] = userProfile(
      repository.uid,
      name: name,
    );
    session.controller.start();
    session.auth.events.add(authUser(repository.uid));
    await flushSession();
    controller = FinancialController(
      transactions: repository,
      session: session.controller,
      expectedUserId: repository.uid,
      initialMonth: FinancialMonth(2026, 11),
    );
  }

  Future<void> close() async {
    controller.dispose();
    await session.close();
  }
}

List<FinancialTransaction> financialVisualTransactions(String uid) => [
  transaction(
    id: 'income',
    userId: uid,
    category: Category.salary,
    amount: 100000,
    description: 'Salário — teste visual',
    date: DateTime(2026, 11, 3),
  ),
  transaction(
    id: 'food',
    userId: uid,
    amount: 25000,
    description: 'Supermercado — teste visual',
    date: DateTime(2026, 11, 4),
  ),
  transaction(
    id: 'transport',
    userId: uid,
    category: Category.transport,
    amount: 10000,
    description: 'Transporte — teste visual',
    date: DateTime(2026, 11, 5),
  ),
  transaction(
    id: 'leisure',
    userId: uid,
    category: Category.leisure,
    amount: 5000,
    description: 'Lazer — teste visual',
    date: DateTime(2026, 10, 12),
  ),
];
