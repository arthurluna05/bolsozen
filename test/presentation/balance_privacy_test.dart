import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:bolsozen/presentation/widgets/balance_card.dart';
import 'package:bolsozen/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'financial_test_fakes.dart';
import 'main_shell_harness.dart';
import 'session_fakes.dart';

Finder get balanceText => find.byKey(const ValueKey('global-balance'));
Future<void> toggleBalance(WidgetTester tester) async {
  final eye = find.byKey(const ValueKey('balance-visibility'));
  await tester.ensureVisible(eye);
  await tester.tap(eye);
  await tester.pumpAndSettle();
}

String balanceValue(WidgetTester tester) =>
    tester.widget<Text>(balanceText).data!;
Future<MainShellHarness> mountPrivacy(
  WidgetTester tester, {
  bool empty = false,
}) async {
  final h = MainShellHarness();
  h.transactions.source = empty ? [] : financialVisualTransactions('A');
  await h.mount(tester);
  return h;
}

List<FinancialTransaction> recentTiles(WidgetTester tester) => tester
    .widgetList<TransactionTile>(find.byType(TransactionTile))
    .map((w) => w.transaction)
    .toList();

void main() {
  testWidgets(
    'Saldo visível, máscara, ícones e alternância sem leituras ou cálculos',
    (tester) async {
      final h = await mountPrivacy(tester);
      final controller = h.financial(tester);
      final summary = controller.summary;
      expect(balanceValue(tester), Money.formatCents(60000));
      expect(find.byTooltip('Ocultar saldo'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await toggleBalance(tester);
        expect(balanceValue(tester), '••••••');
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
        expect(find.byTooltip('Mostrar saldo'), findsOneWidget);
        await toggleBalance(tester);
        expect(balanceValue(tester), Money.formatCents(60000));
      }
      expect(identical(controller.summary, summary), isTrue);
      expect(h.transactions.reads, 1);
      expect(h.transactions.writes, isEmpty);
    },
  );

  testWidgets(
    'Valor oculto não existe no texto ou semântica do saldo; demais valores continuam',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await mountPrivacy(tester);
        final value = balanceValue(tester);
        await toggleBalance(tester);
        final labels = <String>[];
        void visit(SemanticsNode node) {
          labels.add(node.label);
          labels.add(node.value);
          labels.add(node.tooltip);
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(
          tester
              .binding
              .renderViews
              .single
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
        );
        expect(labels.any((label) => label.contains(value)), isFalse);
        expect(labels.any((label) => label.contains('Saldo oculto')), isTrue);
        expect(labels.any((label) => label.contains('Mostrar saldo')), isTrue);
        expect(find.text(value), findsNothing);
        expect(find.text('••••••'), findsOneWidget);
        expect(find.text('R\$ 1.000,00'), findsOneWidget);
        expect(find.text('R\$ 350,00'), findsOneWidget);
        expect(find.text('71,4%'), findsOneWidget);
        expect(recentTiles(tester).single.id, 'transport');
        await shellTab(tester, 'Transações');
        expect(find.text('− R\$ 250,00'), findsOneWidget);
        expect(find.text('+ R\$ 1.000,00'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Preferência sobrevive abas e refresh sem leitura extra ao alternar',
    (tester) async {
      final h = await mountPrivacy(tester);
      await toggleBalance(tester);
      await shellTab(tester, 'Transações');
      await shellTab(tester, 'Perfil');
      await shellTab(tester, 'Início');
      expect(balanceValue(tester), '••••••');
      expect(h.transactions.reads, 1);
      await h.financial(tester).refresh();
      await tester.pumpAndSettle();
      expect(balanceValue(tester), '••••••');
      expect(h.transactions.reads, 2);
    },
  );

  for (final changeUid in [false, true]) {
    testWidgets('Nova sessão reinicia saldo visível: troca de UID $changeUid', (
      tester,
    ) async {
      final h = await mountPrivacy(tester);
      await toggleBalance(tester);
      if (!changeUid) {
        await h.session.controller.signOut();
        await tester.pumpAndSettle();
        expect(find.byType(BalanceCard), findsNothing);
      }
      final uid = changeUid ? 'B' : 'A';
      h.transactions.uid = uid;
      h.transactions.source = financialVisualTransactions(uid);
      h.session.auth.events.add(authUser(uid));
      await tester.pumpAndSettle();
      expect(balanceValue(tester), Money.formatCents(60000));
      expect(find.byTooltip('Ocultar saldo'), findsOneWidget);
      expect(recentTiles(tester).single.userId, uid);
    });
  }

  testWidgets(
    'Vazio confirmado tem saldo zero ocultável e nenhum recente fictício',
    (tester) async {
      final h = await mountPrivacy(tester, empty: true);
      expect(balanceValue(tester), Money.formatCents(0));
      expect(find.text('Nenhuma transação ainda.'), findsOneWidget);
      expect(recentTiles(tester), isEmpty);
      await toggleBalance(tester);
      expect(balanceValue(tester), '••••••');
      expect(h.transactions.reads, 1);
    },
  );

  testWidgets(
    'Recentes após create/update/delete refletem dados confirmados sem consulta própria',
    (tester) async {
      final h = await mountPrivacy(tester);
      final c = h.financial(tester);
      await toggleBalance(tester);
      expect(recentTiles(tester).single.id, 'transport');
      final created = await c.createTransaction(
        type: TransactionType.income,
        amountCents: 12345,
        category: Category.salary,
        description: 'Receita nova',
        occurredAt: DateTime(2099, 12, 31),
      );
      await tester.pumpAndSettle();
      expect(created.status, TransactionSubmissionStatus.confirmed);
      expect(recentTiles(tester).single.id, created.id);
      expect(h.transactions.reads, 2);
      final original = c.transactionById(created.id!)!;
      final updated = await c.updateTransaction(
        original: original,
        type: TransactionType.expense,
        amountCents: 23456,
        category: Category.shopping,
        description: 'Compra editada',
        occurredAt: original.occurredAt,
      );
      await tester.pumpAndSettle();
      expect(updated.status, TransactionSubmissionStatus.confirmed);
      final recent = recentTiles(tester).single;
      expect(
        (recent.description, recent.type, recent.category, recent.amountCents),
        ('Compra editada', TransactionType.expense, Category.shopping, 23456),
      );
      expect(h.transactions.reads, 3);
      final moved = await c.updateTransaction(
        original: recent,
        type: recent.type,
        amountCents: recent.amountCents,
        category: recent.category,
        description: recent.description,
        occurredAt: DateTime(2020),
      );
      await tester.pumpAndSettle();
      expect(moved.status, TransactionSubmissionStatus.confirmed);
      expect(recentTiles(tester).single.id, 'transport');
      expect(h.transactions.reads, 4);
      final deleted = await c.deleteTransaction(
        c.transactionById('transport')!,
      );
      await tester.pumpAndSettle();
      expect(deleted.status, TransactionSubmissionStatus.confirmed);
      expect(recentTiles(tester).single.id, 'food');
      expect(h.transactions.reads, 5);
      expect(balanceValue(tester), '••••••');
      expect(
        c.transactions.map((t) => t.id).toSet().length,
        c.transactions.length,
      );
    },
  );

  for (final operation in ['create', 'update', 'delete']) {
    testWidgets(
      '$operation confirmado com refresh falho mantém recente antigo e aviso; olho não limpa pendência',
      (tester) async {
        final h = await mountPrivacy(tester);
        final c = h.financial(tester);
        final original = c.transactionById('transport')!;
        h.transactions.read = () async => throw const DataFailure(
          DataFailureKind.unavailable,
          'Rede indisponível.',
        );
        final result = switch (operation) {
          'create' => await c.createTransaction(
            type: TransactionType.income,
            amountCents: 100,
            category: Category.salary,
            description: 'Novo',
            occurredAt: DateTime(2099),
          ),
          'update' => await c.updateTransaction(
            original: original,
            type: original.type,
            amountCents: 12345,
            category: original.category,
            description: 'Modificado',
            occurredAt: original.occurredAt,
          ),
          _ => await c.deleteTransaction(original),
        };
        await tester.pumpAndSettle();
        expect(result.status, TransactionSubmissionStatus.refreshPending);
        expect(c.isStale, isTrue);
        expect(recentTiles(tester).single.description, original.description);
        expect(
          find.text('Dados da última carga; podem estar desatualizados.'),
          findsOneWidget,
        );
        await toggleBalance(tester);
        await toggleBalance(tester);
        expect(c.hasPendingRefresh, isTrue);
        expect(c.phase, FinancialPhase.error);
        expect(
          find.text('Dados da última carga; podem estar desatualizados.'),
          findsOneWidget,
        );
        final writes = (
          h.transactions.writes.length,
          h.transactions.updates.length,
          h.transactions.deletes.length,
        );
        h.transactions.read = null;
        await c.retry();
        await tester.pumpAndSettle();
        expect(c.isStale, isFalse);
        expect((
          h.transactions.writes.length,
          h.transactions.updates.length,
          h.transactions.deletes.length,
        ), writes);
        expect(
          recentTiles(tester).single.id,
          operation == 'create'
              ? result.id
              : operation == 'delete'
              ? 'food'
              : 'transport',
        );
        if (operation == 'update') {
          expect(recentTiles(tester).single.description, 'Modificado');
        }
      },
    );
  }

  testWidgets(
    'Refresh mantém máscara e aviso; logout durante leitura descarta resposta e recentes',
    (tester) async {
      final h = await mountPrivacy(tester);
      final c = h.financial(tester);
      await toggleBalance(tester);
      final pending = Completer<List<FinancialTransaction>>();
      h.transactions.read = () => pending.future;
      final reading = c.refresh();
      await tester.pump();
      expect(c.phase, FinancialPhase.refreshing);
      expect(balanceValue(tester), '••••••');
      expect(find.text('Atualizando dados…'), findsOneWidget);
      expect(recentTiles(tester).single.id, 'transport');
      await h.session.controller.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.byType(TransactionTile), findsNothing);
      pending.complete(financialVisualTransactions('A'));
      await reading;
      await tester.pumpAndSettle();
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.byType(TransactionTile), findsNothing);
      expect(h.transactions.reads, 2);
    },
  );

  testWidgets('Falha inicial não apresenta card, zero confirmado ou recentes', (
    tester,
  ) async {
    final h = MainShellHarness();
    h.transactions.read = () async => throw const DataFailure(
      DataFailureKind.unavailable,
      'Sem conexão para carregar.',
    );
    await h.mount(tester);
    expect(find.text('Sem conexão para carregar.'), findsOneWidget);
    expect(find.byType(BalanceCard), findsNothing);
    expect(find.byType(TransactionTile), findsNothing);
    expect(find.byTooltip('Mostrar saldo'), findsNothing);
    expect(find.byTooltip('Ocultar saldo'), findsNothing);
  });

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Saldo $width dp texto $scale visível/oculto sem overflow', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetDevicePixelRatio();
          tester.view.resetPhysicalSize();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await mountPrivacy(tester);
        await toggleBalance(tester);
        expect(balanceValue(tester), '••••••');
        await toggleBalance(tester);
        expect(balanceValue(tester), Money.formatCents(60000));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
