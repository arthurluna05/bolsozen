import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/repositories/transaction_repository.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'session_fakes.dart';

class _Transactions extends Fake implements TransactionRepository {
  final calls = <({FinancialTransaction? after, int limit, String? uid})>[];
  String? uid = 'A';
  List<FinancialTransaction> source = [];
  Future<List<FinancialTransaction>> Function(FinancialTransaction? after)?
  read;

  @override
  Future<List<FinancialTransaction>> fetchPage({
    FinancialTransaction? after,
    int limit = 100,
    String? expectedUserId,
  }) async {
    calls.add((after: after, limit: limit, uid: expectedUserId));
    if (expectedUserId != uid) {
      throw const DataFailure(DataFailureKind.sessionChanged, 'Sessão mudou');
    }
    if (read != null) return read!(after);
    final start = after == null
        ? 0
        : source.indexWhere((t) => t.id == after.id) + 1;
    return source.skip(start).take(limit).toList();
  }
}

List<FinancialTransaction> records(int count) => List.generate(
  count,
  (i) => transaction(id: 't${i.toString().padLeft(3, '0')}', amount: 1),
);

void main() {
  late SessionHarness session;
  late _Transactions repo;
  late FinancialController controller;
  var disposed = false;
  setUp(() async {
    session = SessionHarness();
    session.controller.start();
    session.users.profiles['A'] = userProfile('A');
    session.auth.events.add(authUser('A'));
    await flushSession();
    repo = _Transactions();
    controller = FinancialController(
      transactions: repo,
      session: session.controller,
      expectedUserId: 'A',
      initialMonth: FinancialMonth(2026, 11),
    );
    disposed = false;
  });
  tearDown(() async {
    if (!disposed) controller.dispose();
    await session.close();
  });

  test('Construtor não consulta e carga vazia confirmada não é erro', () async {
    expect(controller.phase, FinancialPhase.idle);
    expect(controller.summary, isNull);
    expect(repo.calls, isEmpty);
    final phases = <FinancialPhase>[];
    controller.addListener(() => phases.add(controller.phase));
    await controller.load();
    expect(phases, [FinancialPhase.loading, FinancialPhase.empty]);
    expect(controller.summary!.balanceCents, 0);
    expect(controller.hasConfirmedSnapshot, isTrue);
    expect(controller.failure, isNull);
    await controller.load();
    expect(repo.calls, hasLength(1));
  });

  for (final count in [0, 100, 101, 200, 201]) {
    test('Carrega histórico completo de $count registros', () async {
      repo.source = records(count);
      await controller.load();
      expect(controller.transactions, hasLength(count));
      expect(controller.summary!.balanceCents, -count);
      expect(repo.calls, hasLength(count ~/ 100 + 1));
      expect(repo.calls.every((c) => c.limit == 100 && c.uid == 'A'), isTrue);
      if (count >= 100) expect(repo.calls[1].after, same(repo.source[99]));
      if (count >= 200) expect(repo.calls[2].after, same(repo.source[199]));
    });
  }

  for (final amount in [50, 100, 150]) {
    test('Saldo global ${amount - 100} e totais separados', () async {
      repo.source = [
        transaction(category: Category.salary, amount: amount),
        transaction(id: 'expense', amount: 100),
      ];
      await controller.load();
      expect(controller.summary!.balanceCents, amount - 100);
      expect(controller.summary!.totals.incomeCents, amount);
      expect(controller.summary!.totals.expenseCents, 100);
    });
  }

  test('T1, futuro e mudança de mês/ano sem nova consulta', () async {
    repo.source = [
      ...t1(),
      transaction(
        id: 'future',
        category: Category.salary,
        amount: 100,
        date: DateTime(2027, 1, 1),
      ),
    ];
    await controller.load();
    expect(controller.summary!.balanceCents, 60100);
    expect(controller.summary!.totals.incomeCents, 100000);
    expect(controller.summary!.totals.expenseCents, 35000);
    controller.selectMonth(FinancialMonth(2026, 10));
    expect(controller.summary!.totals.expenseCents, 5000);
    expect(controller.summary!.balanceCents, 60100);
    controller.selectMonth(FinancialMonth(2027, 1));
    expect(controller.summary!.totals.incomeCents, 100);
    expect(controller.summary!.history, hasLength(5));
    expect(repo.calls, hasLength(1));
  });

  test('Lista e resumo são imutáveis e ordenados pelo domínio', () async {
    repo.source = [
      transaction(id: 'z'),
      transaction(id: 'a'),
      transaction(id: 'new', date: DateTime(2026, 12)),
      transaction(id: 'created', created: DateTime(2026, 12)),
    ];
    await controller.load();
    expect(controller.transactions.map((t) => t.id), [
      'new',
      'created',
      'a',
      'z',
    ]);
    expect(() => controller.transactions.clear(), throwsUnsupportedError);
    expect(() => controller.summary!.history.clear(), throwsUnsupportedError);
  });

  test('Deduplica conteúdo idêntico e usa último cursor bruto', () async {
    final all = records(201);
    // Duplicata no início não deve afetar o último cursor bruto.
    final second = [all[99].copyWith(), ...all.sublist(100, 199)];
    var step = 0;
    repo.read = (_) async =>
        [all.sublist(0, 100), second, all.sublist(199)][step++];
    await controller.load();
    expect(repo.calls[2].after, same(second.last));
    expect(controller.transactions, hasLength(201));
    expect(controller.summary!.balanceCents, -201);
  });

  test('Conflito de mesmo ID invalida carga inteira', () async {
    final all = records(100);
    repo.read = (after) async =>
        after == null ? all : [all.last.copyWith(description: 'alterada')];
    await controller.load();
    expect(controller.phase, FinancialPhase.error);
    expect(controller.failure!.kind, DataFailureKind.invalidData);
    expect(controller.summary, isNull);
    expect(controller.transactions, isEmpty);
  });

  for (final scenario in ['parado', 'ciclo', 'retrocesso']) {
    test('Detecta cursor $scenario sem loop', () async {
      final all = records(200);
      var step = 0;
      repo.read = (_) async {
        step++;
        if (step == 1) return all.sublist(0, 100);
        if (scenario == 'parado') return all.sublist(0, 100);
        if (scenario == 'retrocesso') return [all[50]];
        return step == 2 ? all.sublist(100) : all.sublist(0, 100);
      };
      await controller.load();
      expect(controller.phase, FinancialPhase.error);
      expect(controller.failure!.kind, DataFailureKind.invalidData);
      expect(repo.calls.length, lessThanOrEqualTo(3));
      expect(controller.summary, isNull);
    });
  }

  test('Página maior que contrato é erro, nunca truncamento', () async {
    repo.read = (_) async => records(101);
    await controller.load();
    expect(controller.failure!.kind, DataFailureKind.invalidData);
    expect(controller.summary, isNull);
  });

  test(
    'Página intermediária falha sem publicar saldo parcial; retry reinicia',
    () async {
      final all = records(101);
      repo.read = (after) async {
        if (after != null) {
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede');
        }
        return all.sublist(0, 100);
      };
      await controller.load();
      expect(controller.phase, FinancialPhase.error);
      expect(controller.failure!.kind, DataFailureKind.unavailable);
      expect(controller.summary, isNull);
      expect(controller.transactions, isEmpty);
      repo.read = null;
      repo.source = all;
      await controller.retry();
      expect(repo.calls[2].after, isNull);
      expect(controller.summary!.balanceCents, -101);
    },
  );

  test(
    'Não publica página inicial enquanto última página está pendente',
    () async {
      final pending = Completer<List<FinancialTransaction>>();
      repo.read = (after) =>
          after == null ? Future.value(records(100)) : pending.future;
      final loading = controller.load();
      await flushSession();
      expect(controller.phase, FinancialPhase.loading);
      expect(controller.summary, isNull);
      expect(controller.transactions, isEmpty);
      pending.complete([transaction(id: 't100', amount: 1)]);
      await loading;
      expect(controller.transactions, hasLength(101));
    },
  );

  test('Competência alterada durante carga determina resumo final', () async {
    final pending = Completer<List<FinancialTransaction>>();
    repo.read = (_) => pending.future;
    final loading = controller.load();
    controller.selectMonth(FinancialMonth(2026, 10));
    pending.complete(t1());
    await loading;
    expect(controller.summary!.totals.month, FinancialMonth(2026, 10));
    expect(controller.summary!.totals.expenseCents, 5000);
    expect(repo.calls, hasLength(1));
  });

  test(
    'Refresh/load/retry simultâneos compartilham Future e leitura',
    () async {
      final pending = Completer<List<FinancialTransaction>>();
      repo.read = (_) => pending.future;
      final first = controller.refresh();
      expect(identical(first, controller.load()), isTrue);
      expect(identical(first, controller.retry()), isTrue);
      expect(repo.calls, hasLength(1));
      pending.complete(t1());
      await first;
      expect(controller.summary!.balanceCents, 60000);
    },
  );

  test('Refresh reentrante de listener não duplica operação', () async {
    controller.addListener(() {
      if (controller.isLoading) unawaited(controller.refresh());
    });
    await controller.load();
    expect(repo.calls, hasLength(1));
  });

  test(
    'Snapshot anterior é completo e explicitamente stale durante refresh/erro',
    () async {
      repo.source = t1();
      await controller.load();
      final old = controller.summary;
      final pending = Completer<List<FinancialTransaction>>();
      repo.read = (_) => pending.future;
      final loading = controller.refresh();
      expect(controller.phase, FinancialPhase.refreshing);
      expect(controller.isStale, isTrue);
      expect(controller.summary, same(old));
      controller.selectMonth(FinancialMonth(2026, 10));
      expect(controller.summary!.totals.expenseCents, 5000);
      expect(controller.isStale, isTrue);
      pending.completeError(
        const DataFailure(DataFailureKind.unavailable, 'Sem rede'),
      );
      await loading;
      expect(controller.phase, FinancialPhase.error);
      expect(controller.isStale, isTrue);
      expect(controller.transactions, hasLength(4));
      repo.read = null;
      repo.source = [];
      await controller.retry();
      expect(controller.phase, FinancialPhase.empty);
      expect(controller.summary!.balanceCents, 0);
      expect(controller.isStale, isFalse);
    },
  );

  for (final kind in [
    DataFailureKind.permissionDenied,
    DataFailureKind.unauthenticated,
    DataFailureKind.sessionChanged,
  ]) {
    test('Falha $kind remove snapshot privado', () async {
      repo.source = t1();
      await controller.load();
      repo.read = (_) async => throw DataFailure(kind, 'Falha segura');
      await controller.refresh();
      expect(controller.summary, isNull);
      expect(controller.transactions, isEmpty);
      expect(
        controller.phase,
        kind == DataFailureKind.permissionDenied
            ? FinancialPhase.error
            : FinancialPhase.sessionInvalidated,
      );
    });
  }

  for (final action in ['logout', 'B', 'A-B-A', 'dispose']) {
    test('Descarta resposta atrasada após $action', () async {
      final pending = Completer<List<FinancialTransaction>>();
      repo.read = (_) => pending.future;
      var notifications = 0;
      controller.addListener(() => notifications++);
      final loading = controller.load();
      if (action == 'dispose') {
        controller.dispose();
        disposed = true;
      } else if (action == 'logout') {
        await session.controller.signOut();
      } else {
        session.users.profiles['B'] = userProfile('B');
        session.auth.events.add(authUser('B'));
        await flushSession();
        if (action == 'A-B-A') {
          session.auth.events.add(authUser('A'));
          await flushSession();
        }
      }
      final count = notifications;
      pending.complete(t1());
      await loading;
      expect(notifications, count);
      expect(controller.summary, isNull);
      expect(controller.transactions, isEmpty);
      await controller.refresh();
      expect(repo.calls, hasLength(1));
    });
  }

  test('Troca de UID limpa snapshot já publicado imediatamente', () async {
    repo.source = t1();
    await controller.load();
    session.auth.events.add(authUser('B'));
    expect(controller.summary, isNull);
    expect(controller.phase, FinancialPhase.sessionInvalidated);
    await controller.load();
    expect(repo.calls, hasLength(1));
  });

  test('Novo controller B não recebe sucesso/falha antiga de A', () async {
    final pending = Completer<List<FinancialTransaction>>();
    repo.read = (_) => pending.future;
    final first = controller.load();
    session.users.profiles['B'] = userProfile('B');
    session.auth.events.add(authUser('B'));
    await flushSession();
    final bRepo = _Transactions()
      ..uid = 'B'
      ..source = [transaction(userId: 'B', amount: 7)];
    final second = FinancialController(
      transactions: bRepo,
      session: session.controller,
      expectedUserId: 'B',
      initialMonth: FinancialMonth(2026, 11),
    );
    addTearDown(second.dispose);
    await second.load();
    pending.completeError(
      const DataFailure(DataFailureKind.unavailable, 'Antiga'),
    );
    await first;
    expect(second.summary!.balanceCents, -7);
    expect(second.failure, isNull);
    expect(controller.summary, isNull);
  });

  test(
    'SDK em B antes do evento na apresentação é barrado pelo expectedUserId',
    () async {
      repo.uid = 'B';
      await controller.load();
      expect(repo.calls.single.uid, 'A');
      expect(controller.phase, FinancialPhase.sessionInvalidated);
      expect(controller.summary, isNull);
    },
  );

  test('Documento de outro UID nunca é filtrado para fabricar total', () async {
    repo.source = [transaction(userId: 'B')];
    await controller.load();
    expect(controller.phase, FinancialPhase.sessionInvalidated);
    expect(controller.summary, isNull);
  });

  test('Rejeita dinheiro incompatível mesmo se fake ignorar mapper', () async {
    repo.source = [transaction(amount: Money.maxSafeCents + 1)];
    await controller.load();
    expect(controller.phase, FinancialPhase.error);
    expect(controller.failure!.kind, DataFailureKind.invalidData);
    expect(controller.summary, isNull);
  });

  test('Falha desconhecida não expõe mensagem bruta ou vira vazio', () async {
    repo.read = (_) async => throw Exception('mensagem interna');
    await controller.load();
    expect(controller.phase, FinancialPhase.error);
    expect(controller.summary, isNull);
    expect(controller.failure!.kind, DataFailureKind.unknown);
    expect(controller.failure!.message, isNot(contains('interna')));
  });

  test(
    'Controller exige sessão pronta e UID correspondente antes de consulta',
    () async {
      final invalid = FinancialController(
        transactions: repo,
        session: session.controller,
        expectedUserId: 'B',
      );
      addTearDown(invalid.dispose);
      await invalid.load();
      expect(invalid.phase, FinancialPhase.sessionInvalidated);
      expect(repo.calls, isEmpty);
      expect(
        () => FinancialController(
          transactions: repo,
          session: session.controller,
          expectedUserId: ' ',
        ),
        throwsArgumentError,
      );
    },
  );
}
