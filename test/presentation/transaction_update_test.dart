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
  late FinancialTransaction original;
  var disposed = false;
  setUp(() async {
    disposed = false;
    h = FinancialTestHarness();
    await h.start();
    h.repository.source = financialVisualTransactions(h.repository.uid);
    await h.controller.load();
    original = h.controller.transactionById('food')!;
  });
  tearDown(() => disposed ? h.session.close() : h.close());

  Future<TransactionSubmissionResult> edit({
    FinancialTransaction? from,
    int amount = 20000,
    TransactionType type = TransactionType.expense,
    Category category = Category.food,
    String? description,
    DateTime? date,
  }) => h.controller.updateTransaction(
    original: from ?? original,
    type: type,
    amountCents: amount,
    category: category,
    description: description ?? original.description,
    occurredAt: date ?? original.occurredAt,
  );
  Future<TransactionSubmissionResult> create() =>
      h.controller.createTransaction(
        type: TransactionType.income,
        amountCents: 100,
        category: Category.salary,
        description: 'Teste',
        occurredAt: DateTime(2026, 11),
      );
  void commit(FinancialTransaction value) => h.repository.source = h
      .repository
      .source
      .map((t) => t.id == value.id ? value : t)
      .toList();

  test(
    'CA-07 editar 250→200 confirma saldo 650 e despesas novembro 300',
    () async {
      final result = await edit();
      expect(result.status, TransactionSubmissionStatus.confirmed);
      expect(result.id, original.id);
      expect(h.controller.summary!.balanceCents, 65000);
      expect(h.controller.summary!.totals.expenseCents, 30000);
      expect(h.repository.updates.single.$2, h.repository.uid);
      expect(h.repository.writes, isEmpty);
      final saved = h.controller.transactionById(original.id)!;
      expect(saved.userId, original.userId);
      expect(saved.createdAt, original.createdAt);
      expect(h.repository.reads, 2);
    },
  );
  test(
    'CA-07 mover Alimentação editada para outubro mantém saldo e reordena',
    () async {
      await edit();
      original = h.controller.transactionById(original.id)!;
      await edit(date: DateTime(2026, 10, 14));
      expect(h.controller.summary!.balanceCents, 65000);
      expect(h.controller.summary!.totals.expenseCents, 10000);
      expect(h.controller.summary!.previousExpenseCents, 25000);
      expect(h.controller.transactions.map((t) => t.id), [
        'transport',
        'income',
        'food',
        'leisure',
      ]);
    },
  );
  test('Edição muda tipo/categoria/descrição e aceita data futura', () async {
    final date = DateTime(2099, 12, 4);
    final result = await edit(
      type: TransactionType.income,
      category: Category.otherIncome,
      description: '  Entrada editada  ',
      date: date,
    );
    expect(result.status, TransactionSubmissionStatus.confirmed);
    final value = h.controller.transactionById(original.id)!;
    expect(value.type, TransactionType.income);
    expect(value.category, Category.otherIncome);
    expect(value.description, 'Entrada editada');
    expect(value.occurredAt, date);
    expect(h.controller.transactions.first.id, original.id);
  });
  test('Sem ID no snapshot não chama update nem create', () async {
    final result = await edit(
      from: transaction(id: 'missing', userId: h.repository.uid),
    );
    expect(result.failure!.kind, DataFailureKind.notFound);
    expect(h.repository.updates, isEmpty);
    expect(h.repository.writes, isEmpty);
  });
  test(
    'Proprietário incompatível e original adulterado são recusados',
    () async {
      expect(
        (await edit(
          from: transaction(id: original.id, userId: 'B'),
        )).failure!.kind,
        DataFailureKind.permissionDenied,
      );
      expect(
        (await edit(from: original.copyWith(description: 'Adulterado')))
            .failure!
            .kind,
        DataFailureKind.invalidData,
      );
      expect(h.repository.updates, isEmpty);
    },
  );
  test(
    'Valores inválidos, descrição e categoria não passam pela trava',
    () async {
      for (final result in [
        await edit(amount: 0),
        await edit(amount: int.parse('9007199254740993')),
        await edit(description: ''),
        await edit(category: Category.salary),
      ]) {
        expect(result.status, TransactionSubmissionStatus.failed);
        expect(result.failure!.kind, DataFailureKind.invalidData);
      }
      expect(h.repository.updates, isEmpty);
      expect(h.controller.isSubmitting, isFalse);
    },
  );
  test('Limite monetário conserva centavos sem criar outro registro', () async {
    final income = h.controller.transactionById('income')!;
    final result = await edit(
      from: income,
      amount: Money.maxSafeCents,
      type: TransactionType.income,
      category: Category.salary,
    );
    expect(result.status, TransactionSubmissionStatus.confirmed);
    expect(
      h.controller.transactionById('income')!.amountCents,
      Money.maxSafeCents,
    );
    expect(h.controller.transactions.length, 4);
  });
  for (final updateFirst in [true, false]) {
    test(
      'Trava única create/update; updateFirst=$updateFirst sem envios concorrentes',
      () async {
        final pending = Completer<void>();
        h.repository.updateCall = (value) async {
          await pending.future;
          commit(value);
        };
        h.repository.write = (_) async {
          await pending.future;
          return 'not-committed';
        };
        final first = updateFirst ? edit() : create();
        final second = updateFirst ? await create() : await edit();
        final duplicate = updateFirst ? await edit() : await create();
        expect(second.status, TransactionSubmissionStatus.busy);
        expect(duplicate.status, TransactionSubmissionStatus.busy);
        expect(h.repository.updates.length + h.repository.writes.length, 1);
        pending.complete();
        await first;
        expect(h.controller.isSubmitting, isFalse);
      },
    );
  }
  test('Refresh anterior termina antes do update, recarga posterior não é reutilizada', () async {
    final pending = Completer<List<FinancialTransaction>>();
    h.repository.read = () => pending.future;
    final oldRead = h.controller.refresh();
    final update = edit();
    expect(h.repository.updates, isEmpty);
    h.repository.read = null;
    pending.complete(h.repository.source);
    await oldRead;
    expect((await update).status, TransactionSubmissionStatus.confirmed);
    expect(h.repository.reads, 3);
  });
  test('Original removido durante refresh anterior bloqueia escrita', () async {
    final pending = Completer<List<FinancialTransaction>>();
    h.repository.read = () => pending.future;
    final oldRead = h.controller.refresh();
    final update = edit();
    pending.complete([]);
    await oldRead;
    expect((await update).failure!.kind, DataFailureKind.notFound);
    expect(h.repository.updates, isEmpty);
  });
  test(
    'Commit confirmado e falha de recarga mantêm snapshot stale; retry só lê',
    () async {
      h.repository.read = () async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      final result = await edit();
      expect(result.status, TransactionSubmissionStatus.refreshPending);
      expect(h.controller.isStale, isTrue);
      expect(h.controller.transactionById(original.id)!.amountCents, 25000);
      expect((await create()).status, TransactionSubmissionStatus.uncertain);
      h.repository.read = null;
      await h.controller.refresh();
      expect(h.controller.confirmsUpdate(result.expectedTransaction!), isTrue);
      expect(h.repository.updates.length, 1);
      expect(h.repository.writes, isEmpty);
    },
  );
  for (final absent in [false, true]) {
    test(
      'Recarga completa ${absent ? 'sem ID' : 'com valor antigo'} não confirma edição',
      () async {
        final before = h.repository.source;
        h.repository.read = () async => absent ? [] : before;
        final result = await edit();
        expect(result.status, TransactionSubmissionStatus.refreshPending);
        expect(h.controller.hasPendingRefresh, isTrue);
        expect(h.controller.summary!.balanceCents, 60000);
        h.repository.read = null;
        await h.controller.refresh();
        expect(
          h.controller.confirmsUpdate(result.expectedTransaction!),
          isTrue,
        );
        expect(h.repository.updates.length, 1);
      },
    );
  }
  for (final persisted in [false, true]) {
    test(
      'Resultado incerto, persistido=$persisted, exige leitura sem repetir update',
      () async {
        h.repository.updateCall = (value) async {
          if (persisted) commit(value);
          throw const DataFailure(
            DataFailureKind.unavailable,
            'Resultado incerto.',
          );
        };
        final result = await edit();
        expect(result.status, TransactionSubmissionStatus.uncertain);
        expect(h.controller.requiresReconciliation, isTrue);
        expect(h.controller.isStale, isTrue);
        expect((await edit()).status, TransactionSubmissionStatus.uncertain);
        await h.controller.refresh();
        expect(h.controller.requiresReconciliation, isFalse);
        expect(
          h.controller.confirmsUpdate(result.expectedTransaction!),
          persisted,
        );
        expect(h.repository.updates.length, 1);
        expect(h.repository.writes, isEmpty);
      },
    );
  }
  for (final kind in [
    DataFailureKind.notFound,
    DataFailureKind.permissionDenied,
  ]) {
    test(
      'Falha definida $kind não declara sucesso nem cria substituto',
      () async {
        h.repository.updateCall = (_) async =>
            throw DataFailure(kind, 'Falha.');
        final result = await edit();
        expect(result.status, TransactionSubmissionStatus.failed);
        expect(result.failure!.kind, kind);
        expect(h.controller.summary!.balanceCents, 60000);
        expect(h.repository.writes, isEmpty);
      },
    );
  }
  for (final action in ['logout', 'uid', 'dispose']) {
    test('Resposta atrasada após $action não publica atualização', () async {
      final pending = Completer<void>();
      h.repository.updateCall = (_) => pending.future;
      final call = edit();
      if (action == 'dispose') {
        h.controller.dispose();
        disposed = true;
      } else if (action == 'logout') {
        await h.session.controller.signOut();
      } else {
        h.session.users.profiles['B'] = userProfile('B');
        h.session.auth.events.add(authUser('B'));
        await flushSession();
      }
      pending.complete();
      expect(
        (await call).status,
        TransactionSubmissionStatus.sessionInvalidated,
      );
      expect(h.controller.transactions, isEmpty);
      expect(h.repository.reads, 1);
    });
  }
}
