import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'financial_test_fakes.dart';
import 'session_fakes.dart';

void main() {
  late FinancialTestHarness h;
  var disposed = false;
  setUp(() async {
    disposed = false;
    h = FinancialTestHarness();
    await h.start();
    h.repository.source = financialVisualTransactions(h.repository.uid);
    await h.controller.load();
  });
  tearDown(() => disposed ? h.session.close() : h.close());
  FinancialTransaction value(String id) => h.controller.transactionById(id)!;
  Future<TransactionSubmissionResult> remove([String id = 'food']) =>
      h.controller.deleteTransaction(value(id));
  Future<TransactionSubmissionResult> create() =>
      h.controller.createTransaction(
        type: TransactionType.income,
        amountCents: 100,
        category: Category.salary,
        description: 'Teste',
        occurredAt: DateTime(2026, 11),
      );
  Future<TransactionSubmissionResult> update() {
    final original = value('food');
    return h.controller.updateTransaction(
      original: original,
      type: original.type,
      amountCents: 20000,
      category: original.category,
      description: original.description,
      occurredAt: original.occurredAt,
    );
  }

  void commit(String id) => h.repository.source = h.repository.source
      .where((t) => t.id != id)
      .toList();

  for (final id in ['food', 'income']) {
    test(
      'Excluir $id confirma UID/ID, saldo/totais e ausência após carga completa',
      () async {
        final original = value(id);
        final result = await remove(id);
        expect(result.status, TransactionSubmissionStatus.confirmed);
        expect(result.id, id);
        expect(h.repository.deletes, [(id, h.repository.uid)]);
        expect(h.repository.reads, 2);
        expect(h.controller.confirmsDeletion(original), isTrue);
        expect(
          h.controller.summary!.balanceCents,
          id == 'food' ? 85000 : -40000,
        );
        expect(
          h.controller.summary!.totals.incomeCents,
          id == 'food' ? 100000 : 0,
        );
        expect(
          h.controller.summary!.totals.expenseCents,
          id == 'food' ? 10000 : 35000,
        );
        expect(h.repository.writes, isEmpty);
        expect(h.repository.updates, isEmpty);
      },
    );
  }
  test(
    'CA-07 editar, mover para outubro e excluir Transporte produz saldo 750',
    () async {
      await update();
      final original = value('food');
      await h.controller.updateTransaction(
        original: original,
        type: original.type,
        amountCents: original.amountCents,
        category: original.category,
        description: original.description,
        occurredAt: DateTime(2026, 10, 14),
      );
      final result = await remove('transport');
      expect(result.status, TransactionSubmissionStatus.confirmed);
      expect(h.controller.summary!.balanceCents, 75000);
      expect(h.controller.summary!.totals.expenseCents, 0);
      expect(h.controller.summary!.previousExpenseCents, 25000);
      expect(h.controller.summary!.expensesByCategory, isEmpty);
      expect(h.controller.transactions.first.id, 'income');
    },
  );
  test(
    'Excluir recente reordena histórico/categorias sem calculadora alternativa',
    () async {
      await remove('transport');
      expect(h.controller.transactions.first.id, 'food');
      expect(h.controller.summary!.expensesByCategory, {Category.food: 25000});
      expect(h.controller.summary!.categoryPercentages, {Category.food: 100});
    },
  );
  test(
    'Excluir último registro publica vazio e zero somente após confirmação',
    () async {
      h.repository.source = [value('food')];
      await h.controller.refresh();
      await remove();
      expect(h.controller.phase, FinancialPhase.empty);
      expect(h.controller.summary!.balanceCents, 0);
      expect(h.controller.hasConfirmedSnapshot, isTrue);
    },
  );
  test(
    'ID ausente, UID incompatível e original adulterado não iniciam delete',
    () async {
      final absent = await h.controller.deleteTransaction(
        transaction(id: 'missing', userId: h.repository.uid),
      );
      final other = await h.controller.deleteTransaction(
        transaction(id: 'food', userId: 'B'),
      );
      final changed = await h.controller.deleteTransaction(
        value('food').copyWith(description: 'Adulterado'),
      );
      expect(absent.failure!.kind, DataFailureKind.notFound);
      expect(other.failure!.kind, DataFailureKind.permissionDenied);
      expect(changed.failure!.kind, DataFailureKind.invalidData);
      expect(h.repository.deletes, isEmpty);
    },
  );
  for (final firstKind in ['create', 'update', 'delete']) {
    test(
      'Trava create/update/delete e duplo envio; primeira=$firstKind',
      () async {
        final done = Completer<void>();
        h.repository.write = (_) async {
          await done.future;
          return 'unconfirmed-id';
        };
        h.repository.updateCall = (_) => done.future;
        h.repository.deleteCall = (_) => done.future;
        final call = switch (firstKind) {
          'create' => create(),
          'update' => update(),
          _ => remove(),
        };
        for (final busy in [
          await create(),
          await update(),
          await remove(),
          await remove(),
        ]) {
          expect(busy.status, TransactionSubmissionStatus.busy);
        }
        expect(
          h.repository.writes.length +
              h.repository.updates.length +
              h.repository.deletes.length,
          1,
        );
        done.complete();
        await call;
        expect(h.controller.isSubmitting, isFalse);
      },
    );
  }
  test('Não remove item ou saldo antes do commit e recarga', () async {
    final done = Completer<void>();
    h.repository.deleteCall = (id) async {
      await done.future;
      commit(id);
    };
    final call = remove();
    expect(value('food').amountCents, 25000);
    expect(h.controller.summary!.balanceCents, 60000);
    expect(h.repository.reads, 1);
    done.complete();
    expect((await call).status, TransactionSubmissionStatus.confirmed);
  });
  test(
    'Commit confirmado com refresh falho mantém stale, retry apenas lê',
    () async {
      final original = value('food');
      h.repository.read = () async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      final result = await remove();
      expect(result.status, TransactionSubmissionStatus.refreshPending);
      expect(h.controller.hasPendingRefresh, isTrue);
      expect(h.controller.isStale, isTrue);
      expect(h.controller.transactionById('food'), isNotNull);
      expect(h.controller.summary!.balanceCents, 60000);
      expect((await create()).status, TransactionSubmissionStatus.uncertain);
      h.repository.read = null;
      await h.controller.refresh();
      expect(h.controller.confirmsDeletion(original), isTrue);
      expect(h.repository.deletes.length, 1);
    },
  );
  test('Leitura que ainda contém ID não confirma exclusão nem publica totais parciais', () async {
    final previous = h.repository.source;
    h.repository.read = () async => previous;
    final result = await remove();
    expect(result.status, TransactionSubmissionStatus.refreshPending);
    expect(h.controller.summary!.balanceCents, 60000);
    expect(h.controller.hasPendingRefresh, isTrue);
    h.repository.read = null;
    await h.controller.refresh();
    expect(h.controller.transactionById('food'), isNull);
    expect(h.repository.deletes.length, 1);
  });
  for (final persisted in [false, true]) {
    test(
      'Confirmação incerta persistida=$persisted só reconcilia por leitura',
      () async {
        final original = value('food');
        h.repository.deleteCall = (id) async {
          if (persisted) commit(id);
          throw const DataFailure(
            DataFailureKind.unavailable,
            'Sem confirmação.',
          );
        };
        final result = await remove();
        expect(result.status, TransactionSubmissionStatus.uncertain);
        expect(h.controller.requiresReconciliation, isTrue);
        expect(h.controller.isStale, isTrue);
        expect((await remove()).status, TransactionSubmissionStatus.uncertain);
        await h.controller.refresh();
        expect(h.controller.confirmsDeletion(original), persisted);
        expect(h.repository.deletes.length, 1);
      },
    );
  }
  for (final kind in [
    DataFailureKind.permissionDenied,
    DataFailureKind.notFound,
  ]) {
    test('Erro definido $kind não é sucesso e preserva registro', () async {
      h.repository.deleteCall = (_) async =>
          throw DataFailure(kind, 'Não foi possível excluir.');
      final result = await remove();
      expect(result.status, TransactionSubmissionStatus.failed);
      expect(result.failure!.kind, kind);
      expect(h.controller.transactionById('food'), isNotNull);
      expect(h.controller.summary!.balanceCents, 60000);
    });
  }
  test(
    'Aguarda leitura anterior e faz apenas uma nova carga posterior ao delete',
    () async {
      final page = Completer<List<FinancialTransaction>>();
      h.repository.read = () => page.future;
      final load = h.controller.refresh();
      final deletion = remove();
      expect(h.repository.deletes, isEmpty);
      h.repository.read = null;
      page.complete(h.repository.source);
      await load;
      expect((await deletion).status, TransactionSubmissionStatus.confirmed);
      expect(h.repository.reads, 3);
    },
  );
  test(
    'Revalida ID depois de leitura anterior sem enviar exclusão ausente',
    () async {
      final page = Completer<List<FinancialTransaction>>();
      h.repository.read = () => page.future;
      final load = h.controller.refresh();
      final deletion = remove();
      page.complete([]);
      await load;
      expect((await deletion).failure!.kind, DataFailureKind.notFound);
      expect(h.repository.deletes, isEmpty);
    },
  );
  for (final action in ['logout', 'uid', 'dispose']) {
    test(
      'Resposta atrasada de exclusão após $action não publica dados',
      () async {
        final done = Completer<void>();
        h.repository.deleteCall = (_) => done.future;
        final call = remove();
        if (action == 'logout') {
          await h.session.controller.signOut();
        } else if (action == 'uid') {
          h.session.users.profiles['B'] = userProfile('B');
          h.session.auth.events.add(authUser('B'));
          await flushSession();
        } else {
          disposed = true;
          h.controller.dispose();
        }
        done.complete();
        expect(
          (await call).status,
          TransactionSubmissionStatus.sessionInvalidated,
        );
        expect(h.controller.transactions, isEmpty);
        expect(h.repository.reads, 1);
      },
    );
  }
}
