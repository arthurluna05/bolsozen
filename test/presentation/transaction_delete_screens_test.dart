import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/widgets/delete_transaction_dialog.dart';
import 'package:bolsozen/presentation/widgets/transaction_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'financial_test_fakes.dart';
import 'main_shell_harness.dart';
import 'session_fakes.dart';
import 'transaction_edit_screens_test.dart' show editMenu;

Future<void> deleteOpen(WidgetTester tester, String id) async {
  await editMenu(tester, id);
  await tester.tap(find.text('Excluir'));
  await tester.pumpAndSettle();
}

void main() {
  Future<MainShellHarness> mount(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool large = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = MainShellHarness();
    h.transactions.source = financialVisualTransactions('A')
        .map(
          (t) => t.id == 'income' && large
              ? t.copyWith(
                  amountCents: Money.maxSafeCents,
                  description: List.filled(10, 'Descrição').join(' '),
                )
              : t,
        )
        .toList();
    await h.mount(tester);
    return h;
  }

  Future<void> confirm(WidgetTester tester, {bool settle = true}) async {
    final button = find.byKey(const ValueKey('delete-confirm'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> read(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('delete-read'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Menu mantém Editar e oferece Excluir, confirmação ainda não grava',
    (tester) async {
      final h = await mount(tester);
      await editMenu(tester, 'food');
      expect(find.byType(TransactionActionsSheet), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionActionsSheet), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Excluir transação?'), findsOneWidget);
      expect(find.text('Supermercado — teste visual'), findsNWidgets(2));
      expect(find.text(Money.formatCents(25000)), findsOneWidget);
      expect(find.text('A exclusão não poderá ser desfeita.'), findsOneWidget);
      expect(h.transactions.deletes, isEmpty);
    },
  );
  for (final back in [false, true]) {
    testWidgets(
      'Cancelar exclusão por ${back ? 'Voltar' : 'botão'} não altera saldo/lista',
      (tester) async {
        final h = await mount(tester);
        await deleteOpen(tester, 'food');
        if (back) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byKey(const ValueKey('delete-cancel')));
        }
        await tester.pumpAndSettle();
        expect(find.byType(DeleteTransactionDialog), findsNothing);
        expect(h.transactions.deletes, isEmpty);
        expect(h.financial(tester).summary!.balanceCents, 60000);
        expect(h.financial(tester).transactions.length, 4);
        expect(h.transactions.reads, 1);
      },
    );
  }
  for (final income in [false, true]) {
    testWidgets(
      'Confirma exclusão de ${income ? 'receita' : 'despesa'} e atualiza dados compartilhados',
      (tester) async {
        final h = await mount(tester);
        final id = income ? 'income' : 'transport';
        await deleteOpen(tester, id);
        await confirm(tester);
        expect(find.byType(DeleteTransactionDialog), findsNothing);
        expect(h.transactions.deletes, [(id, 'A')]);
        expect(h.financial(tester).transactionById(id), isNull);
        expect(
          h.financial(tester).summary!.balanceCents,
          income ? -40000 : 70000,
        );
        expect(h.transactions.reads, 2);
        await shellTab(tester, 'Início');
        expect(
          find.text(Money.formatCents(income ? -40000 : 70000)),
          findsOneWidget,
        );
        if (!income) {
          expect(h.financial(tester).transactions.first.id, 'food');
          expect(h.financial(tester).summary!.expensesByCategory, {
            Category.food: 25000,
          });
          expect(find.text('Supermercado — teste visual'), findsOneWidget);
        }
      },
    );
  }
  testWidgets(
    'CA-07 após edição/mês exclui Transporte, saldo 750 e despesas mês zero',
    (tester) async {
      final h = await mount(tester);
      final original = h.financial(tester).transactionById('food')!;
      await h
          .financial(tester)
          .updateTransaction(
            original: original,
            type: original.type,
            amountCents: 20000,
            category: original.category,
            description: original.description,
            occurredAt: DateTime(2026, 10, 14),
          );
      await tester.pumpAndSettle();
      await deleteOpen(tester, 'transport');
      await confirm(tester);
      expect(h.financial(tester).summary!.balanceCents, 75000);
      expect(h.financial(tester).summary!.totals.expenseCents, 0);
      expect(h.financial(tester).summary!.previousExpenseCents, 25000);
      expect(h.transactions.deletes.length, 1);
      expect(h.transactions.updates.length, 1);
    },
  );
  testWidgets('Confirmações repetidas bloqueadas e andamento explícito', (
    tester,
  ) async {
    final h = await mount(tester);
    final done = Completer<void>();
    h.transactions.deleteCall = (id) async {
      await done.future;
      h.transactions.source = h.transactions.source
          .where((t) => t.id != id)
          .toList();
    };
    await deleteOpen(tester, 'food');
    final callback = tester
        .widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')))
        .onPressed!;
    callback();
    callback();
    await tester.pump();
    expect(h.transactions.deletes.length, 1);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('delete-confirm')))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('Exclusão em andamento.'), findsOneWidget);
    done.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DeleteTransactionDialog), findsNothing);
  });
  testWidgets(
    'Fechar durante operação não cancela/reenvia e dados só mudam após commit',
    (tester) async {
      final h = await mount(tester);
      final done = Completer<void>();
      h.transactions.deleteCall = (id) async {
        await done.future;
        h.transactions.source = h.transactions.source
            .where((t) => t.id != id)
            .toList();
      };
      await deleteOpen(tester, 'food');
      await confirm(tester, settle: false);
      await tester.tap(find.byKey(const ValueKey('delete-cancel')));
      await tester.pumpAndSettle();
      expect(h.financial(tester).transactionById('food'), isNotNull);
      done.complete();
      await tester.pumpAndSettle();
      expect(h.financial(tester).transactionById('food'), isNull);
      expect(h.transactions.deletes.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Recarga falha após delete: aviso confirmado e retry somente de leitura',
    (tester) async {
      final h = await mount(tester);
      await deleteOpen(tester, 'food');
      h.transactions.read = () async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      await confirm(tester);
      expect(
        find.text(
          'Transação excluída; não foi possível atualizar o histórico. Atualize sem excluir novamente.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delete-confirm')), findsNothing);
      expect(h.financial(tester).isStale, isTrue);
      expect(h.financial(tester).transactionById('food'), isNotNull);
      h.transactions.read = null;
      await read(tester);
      expect(find.byType(DeleteTransactionDialog), findsNothing);
      expect(h.transactions.deletes.length, 1);
      expect(h.transactions.reads, 3);
    },
  );
  testWidgets('Fechar após recarga falha conserva aviso stale no Histórico', (
    tester,
  ) async {
    final h = await mount(tester);
    await deleteOpen(tester, 'food');
    h.transactions.read = () async =>
        throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
    await confirm(tester);
    await tester.tap(find.byKey(const ValueKey('delete-cancel')));
    await tester.pumpAndSettle();
    expect(
      find.text('Dados da última carga; podem estar desatualizados.'),
      findsOneWidget,
    );
    expect(h.transactions.deletes.length, 1);
    await shellAdd(tester);
    await shellFill(tester);
    await shellSave(tester);
    expect(h.transactions.writes, isEmpty);
    expect(
      find.text(
        'Há uma alteração confirmada aguardando atualização. Atualize os dados antes de iniciar outro lançamento.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    h.transactions.read = null;
    await h.financial(tester).refresh();
    await tester.pumpAndSettle();
    expect(h.financial(tester).transactionById('food'), isNull);
  });
  for (final persisted in [false, true]) {
    testWidgets(
      'Exclusão incerta persistida=$persisted exige leitura e não repete',
      (tester) async {
        final h = await mount(tester);
        h.transactions.deleteCall = (id) async {
          if (persisted) {
            h.transactions.source = h.transactions.source
                .where((t) => t.id != id)
                .toList();
          }
          throw const DataFailure(
            DataFailureKind.unavailable,
            'Sem confirmação.',
          );
        };
        await deleteOpen(tester, 'food');
        await confirm(tester);
        expect(
          find.textContaining('Não foi possível confirmar a exclusão.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('delete-confirm')), findsNothing);
        await read(tester);
        expect(
          find.byType(DeleteTransactionDialog),
          persisted ? findsNothing : findsOneWidget,
        );
        expect(h.transactions.deletes.length, 1);
      },
    );
  }
  testWidgets(
    'Permissão negada mantém item e permite correção explícita sem falso sucesso',
    (tester) async {
      final h = await mount(tester);
      h.transactions.deleteCall = (_) async => throw const DataFailure(
        DataFailureKind.permissionDenied,
        'Exclusão negada.',
      );
      await deleteOpen(tester, 'food');
      await confirm(tester);
      expect(find.text('Exclusão negada.'), findsOneWidget);
      expect(h.financial(tester).transactionById('food'), isNotNull);
      expect(h.transactions.deletes.length, 1);
    },
  );
  testWidgets('notFound específico atualiza mas não vira sucesso automático', (
    tester,
  ) async {
    final h = await mount(tester);
    await deleteOpen(tester, 'food');
    h.transactions.source = h.transactions.source
        .where((t) => t.id != 'food')
        .toList();
    await confirm(tester);
    expect(find.text('Transação não encontrada.'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-confirm')), findsNothing);
    await read(tester);
    expect(find.byType(DeleteTransactionDialog), findsOneWidget);
    expect(h.transactions.deletes.length, 1);
    expect(h.financial(tester).transactionById('food'), isNull);
  });
  testWidgets('Snapshot alterado depois da abertura do diálogo é revalidado', (
    tester,
  ) async {
    final h = await mount(tester);
    await deleteOpen(tester, 'food');
    h.transactions.source = h.transactions.source
        .map((t) => t.id == 'food' ? t.copyWith(amountCents: 1) : t)
        .toList();
    await h.financial(tester).refresh();
    await tester.pumpAndSettle();
    await confirm(tester);
    expect(h.transactions.deletes, isEmpty);
    expect(find.textContaining('A transação mudou.'), findsOneWidget);
  });
  for (final sending in [false, true]) {
    for (final logout in [false, true]) {
      testWidgets(
        'Identidade muda com diálogo, enviando=$sending logout=$logout remove privado',
        (tester) async {
          final h = await mount(tester);
          final done = Completer<void>();
          h.transactions.deleteCall = (_) => done.future;
          await deleteOpen(tester, 'food');
          if (sending) await confirm(tester, settle: false);
          if (logout) {
            await h.session.controller.signOut();
          } else {
            h.transactions.uid = 'B';
            h.transactions.source = [];
            h.session.auth.events.add(authUser('B'));
          }
          await tester.pumpAndSettle();
          done.complete();
          await tester.pumpAndSettle();
          expect(
            find.byType(DeleteTransactionDialog, skipOffstage: false),
            findsNothing,
          );
          expect(
            find.text('Supermercado — teste visual', skipOffstage: false),
            findsNothing,
          );
          expect(h.transactions.deletes.length, sending ? 1 : 0);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byType(DeleteTransactionDialog, skipOffstage: false),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Confirmação $width dp fonte $scale: texto extenso, valor e acessibilidade',
        (tester) async {
          final h = await mount(
            tester,
            width: width,
            scale: scale,
            large: true,
          );
          final semantics = tester.ensureSemantics();
          try {
            await deleteOpen(tester, 'income');
            await tester.ensureVisible(
              find.byKey(const ValueKey('delete-confirm')),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('delete-confirm')).hitTestable(),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('delete-cancel')).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            expect(h.transactions.deletes, isEmpty);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
