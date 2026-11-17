import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/data/firebase/firebase_session.dart';
import 'package:bolsozen/data/repositories/firestore_budget_repository.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/data/repositories/firestore_user_repository.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';

class TestAuth extends Fake implements FirebaseAuth {
  User? user;
  @override
  User? get currentUser => user;
}

class TestUser extends Fake implements User {
  TestUser(this.uid);
  @override
  final String uid;
}

class NoFirestore extends Fake implements FirebaseFirestore {}

void main() {
  late TestAuth auth;
  late FirebaseSession session;
  setUp(() {
    auth = TestAuth();
    session = FirebaseSession(auth: auth, firestore: NoFirestore());
  });
  test('Repositórios recusam todas as operações sem sessão antes de acessar Firestore', () async {
    final transactions = FirestoreTransactionRepository(session);
    final budgets = FirestoreBudgetRepository(session);
    final users = FirestoreUserRepository(session);
    final matcher = throwsA(
      isA<DataFailure>().having(
        (e) => e.kind,
        'kind',
        DataFailureKind.unauthenticated,
      ),
    );
    await expectLater(transactions.fetchPage(), matcher);
    await expectLater(
      transactions.create(
        type: TransactionType.expense,
        amountCents: 1,
        category: Category.food,
        description: 'Teste',
        occurredAt: DateTime(2026),
      ),
      matcher,
    );
    await expectLater(transactions.update(transaction()), matcher);
    await expectLater(transactions.delete('t'), matcher);
    await expectLater(budgets.fetchMonth(FinancialMonth(2026, 11)), matcher);
    await expectLater(
      budgets.save(
        month: FinancialMonth(2026, 11),
        category: Category.food,
        limitCents: 1,
      ),
      matcher,
    );
    await expectLater(
      budgets.remove(month: FinancialMonth(2026, 11), category: Category.food),
      matcher,
    );
    await expectLater(users.fetch(), matcher);
    await expectLater(users.ensureProfile(displayName: 'Pessoa'), matcher);
  });
  test('Detecta troca de usuário e logout em operações pendentes', () {
    auth.user = TestUser('A');
    expect(session.uid, 'A');
    session.verify('A');
    auth.user = TestUser('B');
    expect(
      () => session.verify('A'),
      throwsA(
        isA<DataFailure>().having(
          (e) => e.kind,
          'kind',
          DataFailureKind.sessionChanged,
        ),
      ),
    );
    auth.user = null;
    expect(() => session.verify('B'), throwsA(isA<DataFailure>()));
  });
  test('Recusa cursor de outro usuário e tamanho de página inválido', () async {
    auth.user = TestUser('A');
    final repository = FirestoreTransactionRepository(session);
    for (final limit in [0, 101]) {
      await expectLater(
        repository.fetchPage(limit: limit),
        throwsA(isA<DataFailure>()),
      );
    }
    await expectLater(
      repository.fetchPage(after: transaction(userId: 'B')),
      throwsA(isA<DataFailure>()),
    );
    await expectLater(
      repository.update(transaction(userId: 'B')),
      throwsA(isA<DataFailure>()),
    );
    await expectLater(repository.delete('a/b'), throwsA(isA<DataFailure>()));
  });
  test('Traduz erros sem expor mensagens técnicas', () async {
    for (final code in [
      'permission-denied',
      'unauthenticated',
      'unavailable',
      'not-found',
      'other',
    ]) {
      await expectLater(
        guardData<void>(
          () async => throw FirebaseException(
            plugin: 'firestore',
            code: code,
            message: 'segredo técnico',
          ),
        ),
        throwsA(
          isA<DataFailure>().having(
            (e) => e.message,
            'mensagem',
            isNot(contains('segredo')),
          ),
        ),
      );
    }
  });
}
