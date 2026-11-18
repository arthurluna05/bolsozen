import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'financial_test_fakes.dart';
import 'session_fakes.dart';

void main() {
  late FinancialTestHarness h;
  setUp(() async {
    h = FinancialTestHarness();
    await h.start();
    h.repository.source = financialVisualTransactions(h.repository.uid);
    await h.controller.load();
  });
  tearDown(() => h.close());

  Future<TransactionSubmissionResult> submit({
    TransactionType type = TransactionType.expense,
    Category category = Category.food,
    int amount = 12050,
    String description = '  Almoço  ',
    DateTime? date,
  }) => h.controller.createTransaction(
    type: type,
    amountCents: amount,
    category: category,
    description: description,
    occurredAt: date ?? DateTime(2026, 11, 18),
  );
  void commit(TransactionDraftFixture draft, String id) {
    h.repository.source = [
      ...h.repository.source,
      transaction(
        id: id,
        userId: h.repository.uid,
        amount: draft.amountCents,
        category: draft.category,
        description: draft.description,
        date: draft.occurredAt,
      ),
    ];
  }

  for (final type in TransactionType.values) {
    test(
      'Criação ${type.name}, UID e recarga confirmada compartilhada',
      () async {
        final result = await submit(
          type: type,
          category: type == TransactionType.income
              ? Category.salary
              : Category.food,
        );
        expect(result.status, TransactionSubmissionStatus.confirmed);
        expect(result.id, 'created-1');
        expect(h.repository.writes.single.uid, h.repository.uid);
        expect(h.repository.writes.single.amountCents, 12050);
        expect(h.repository.writes.single.description, 'Almoço');
        expect(h.repository.reads, 2);
        expect(h.controller.transactions.any((t) => t.id == result.id), isTrue);
        expect(
          h.controller.summary!.balanceCents,
          type == TransactionType.income ? 72050 : 47950,
        );
        expect(h.controller.hasPendingRefresh, isFalse);
      },
    );
  }
  test(
    'Valores/categoria/descrição/data inválidos não chamam repositório',
    () async {
      for (final amount in [0, -1, Money.maxSafeCents + 1]) {
        expect(
          (await submit(amount: amount)).status,
          TransactionSubmissionStatus.failed,
        );
      }
      expect(
        (await submit(category: Category.salary)).status,
        TransactionSubmissionStatus.failed,
      );
      expect(
        (await submit(description: ' ')).status,
        TransactionSubmissionStatus.failed,
      );
      expect(
        (await submit(description: List.filled(121, 'á').join())).status,
        TransactionSubmissionStatus.failed,
      );
      expect(
        (await submit(date: DateTime(0))).status,
        TransactionSubmissionStatus.failed,
      );
      expect(h.repository.writes, isEmpty);
    },
  );
  test(
    'Futuro não muda competência e altera apenas saldo global pertinente',
    () async {
      await submit(date: DateTime(2027, 1, 1));
      expect(h.controller.summary!.balanceCents, 47950);
      expect(h.controller.summary!.totals.expenseCents, 35000);
    },
  );
  test(
    'Duplo envio e refresh concorrente não duplicam escrita nem leitura',
    () async {
      final pending = Completer<String>();
      h.repository.write = (_) => pending.future;
      final first = submit();
      expect(h.controller.isSubmitting, isTrue);
      expect((await submit()).status, TransactionSubmissionStatus.busy);
      final refresh = h.controller.refresh();
      expect(identical(refresh, h.controller.refresh()), isTrue);
      expect(h.repository.reads, 1);
      commit(h.repository.writes.single, 'confirmed');
      pending.complete('confirmed');
      expect((await first).status, TransactionSubmissionStatus.confirmed);
      await refresh;
      expect(h.repository.writes, hasLength(1));
      expect(h.repository.reads, 2);
    },
  );
  test('Leitura antiga termina antes da gravação; recarga posterior não é reutilizada', () async {
    final pending = Completer<List<FinancialTransaction>>();
    h.repository.read = () => pending.future;
    final old = h.controller.refresh();
    final writing = submit();
    expect(h.repository.writes, isEmpty);
    h.repository.read = null;
    pending.complete(h.repository.source);
    await old;
    expect((await writing).status, TransactionSubmissionStatus.confirmed);
    expect(h.repository.reads, 3);
  });
  test(
    'Commit confirmado e recarga falha: retry só lê, nunca cria novamente',
    () async {
      h.repository.write = (draft) async {
        commit(draft, 'saved');
        h.repository.read = () async =>
            throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
        return 'saved';
      };
      final result = await submit();
      expect(result.status, TransactionSubmissionStatus.refreshPending);
      expect(h.controller.summary!.balanceCents, 60000);
      expect(h.controller.hasPendingRefresh, isTrue);
      expect(h.controller.isStale, isTrue);
      await submit();
      expect(h.repository.writes, hasLength(1));
      h.repository.read = null;
      await h.controller.refresh();
      expect(h.controller.hasPendingRefresh, isFalse);
      expect(h.controller.summary!.balanceCents, 47950);
      expect(h.repository.writes, hasLength(1));
    },
  );
  test(
    'ID confirmado ausente na leitura não é atualização bem-sucedida',
    () async {
      h.repository.write = (_) async => 'missing';
      expect(
        (await submit()).status,
        TransactionSubmissionStatus.refreshPending,
      );
      expect(h.controller.phase, FinancialPhase.error);
      expect(h.controller.summary!.balanceCents, 60000);
    },
  );
  test(
    'Negação explícita permite corrigir/repetir; não vira sucesso',
    () async {
      h.repository.write = (_) async => throw const DataFailure(
        DataFailureKind.permissionDenied,
        'Sem permissão.',
      );
      final failure = await submit();
      expect(failure.status, TransactionSubmissionStatus.failed);
      expect(failure.failure!.kind, DataFailureKind.permissionDenied);
      expect(h.controller.requiresReconciliation, isFalse);
      h.repository.write = null;
      expect((await submit()).status, TransactionSubmissionStatus.confirmed);
    },
  );
  test(
    'Falha de rede é resultado incerto; exige leitura antes de outro envio',
    () async {
      h.repository.write = (_) async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      expect((await submit()).status, TransactionSubmissionStatus.uncertain);
      expect(h.controller.requiresReconciliation, isTrue);
      expect((await submit()).status, TransactionSubmissionStatus.uncertain);
      expect(h.repository.writes, hasLength(1));
      await h.controller.refresh();
      expect(h.controller.requiresReconciliation, isFalse);
      expect(h.repository.writes, hasLength(1));
    },
  );
  test(
    'Troca de sessão durante commit descarta ID e não recarrega para outro UID',
    () async {
      final pending = Completer<String>();
      h.repository.write = (_) => pending.future;
      final writing = submit();
      h.session.auth.events.add(authUser('other'));
      await flushSession();
      pending.complete('old-user-id');
      final result = await writing;
      expect(result.status, TransactionSubmissionStatus.sessionInvalidated);
      expect(result.id, isNull);
      expect(h.controller.summary, isNull);
      expect(h.repository.reads, 1);
    },
  );
  test(
    'Mudança de identidade no notify final também invalida resultado',
    () async {
      h.controller.addListener(() {
        if (!h.controller.isSubmitting &&
            h.repository.writes.isNotEmpty &&
            h.controller.phase != FinancialPhase.sessionInvalidated) {
          h.session.auth.events.add(null);
        }
      });
      final result = await submit();
      expect(result.status, TransactionSubmissionStatus.sessionInvalidated);
      expect(result.id, isNull);
    },
  );
  test('Dispose durante gravação impede notificações e resultados privados tardios', () async {
    final local = FinancialTestHarness();
    await local.start();
    final pending = Completer<String>();
    local.repository.write = (_) => pending.future;
    final future = local.controller.createTransaction(
      type: TransactionType.expense,
      amountCents: 100,
      category: Category.food,
      description: 'Teste',
      occurredAt: DateTime(2026),
    );
    local.controller.dispose();
    pending.complete('late');
    expect(
      (await future).status,
      TransactionSubmissionStatus.sessionInvalidated,
    );
    await local.session.close();
  });
}
