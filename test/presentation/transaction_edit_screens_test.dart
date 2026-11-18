import 'dart:async';

import 'package:bolsozen/app/main_shell.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/screens/transactions/transaction_form_screen.dart';
import 'package:bolsozen/presentation/widgets/transaction_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'financial_test_fakes.dart';
import 'main_shell_harness.dart';
import 'session_fakes.dart';

Future<void> editMenu(WidgetTester tester, String id) async {
  await shellTab(tester, 'Transações');
  final row = find.byKey(ValueKey(id));
  await tester.scrollUntilVisible(
    row,
    250,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Um card com fonte/descrição extensas pode ser maior que a viewport; tocar
  // no topo visível, em vez do centro geométrico fora da área rolável.
  await tester.tapAt(tester.getTopLeft(row) + const Offset(32, 24));
  await tester.pumpAndSettle();
}

Future<void> editOpen(WidgetTester tester, String id) async {
  await editMenu(tester, id);
  await tester.tap(find.text('Editar'));
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
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = MainShellHarness();
    h.transactions.source = financialVisualTransactions('A')
        .map(
          (t) => t.id == 'income' && large
              ? t.copyWith(
                  amountCents: Money.maxSafeCents,
                  description: List.filled(8, 'Descrição').join(' '),
                )
              : t.id == 'food'
              ? t.copyWith(
                  occurredAt: DateTime.utc(2026, 11, 4, 14, 35, 27, 123, 456),
                )
              : t,
        )
        .toList();
    await h.mount(tester);
    return h;
  }

  Future<void> amount(WidgetTester tester, String value) =>
      tester.enterText(find.byKey(const ValueKey('transaction-amount')), value);
  Future<void> retryRead(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Atualizar dados'));
    await tester.tap(find.text('Atualizar dados'));
    await tester.pumpAndSettle();
  }

  for (final id in ['income', 'food']) {
    testWidgets(
      'Abrir $id preserva Editar no menu, preenche TEL-05 e cancelar não grava',
      (tester) async {
        final h = await mount(tester);
        final original = h.financial(tester).transactionById(id)!;
        await editMenu(tester, id);
        expect(find.byType(TransactionActionsSheet), findsOneWidget);
        expect(find.text('Editar'), findsOneWidget);
        expect(find.text('Excluir'), findsOneWidget);
        await tester.tap(find.text('Editar'));
        await tester.pumpAndSettle();
        expect(find.text('Editar transação'), findsOneWidget);
        expect(find.text('Salvar alterações'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        final form = tester.widget<TransactionFormScreen>(
          find.byType(TransactionFormScreen),
        );
        expect(form.transaction, same(original));
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('transaction-amount')),
              )
              .controller!
              .text,
          Money.formatCents(original.amountCents),
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('transaction-description')),
              )
              .controller!
              .text,
          original.description,
        );
        expect(find.text(original.category.label), findsOneWidget);
        await amount(tester, '999,99');
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
        expect(h.transactions.updates, isEmpty);
        expect(h.transactions.writes, isEmpty);
        expect(h.transactions.reads, 1);
      },
    );
  }
  testWidgets('Fechar menu pelo Voltar não abre formulário nem grava', (
    tester,
  ) async {
    final h = await mount(tester);
    await editMenu(tester, 'food');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TransactionActionsSheet), findsNothing);
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(h.transactions.updates, isEmpty);
  });
  testWidgets('Preenchimento e edição fracionária preservam cada centavo', (
    tester,
  ) async {
    final h = await mount(tester);
    h.transactions.source = h.transactions.source
        .map((t) => t.id == 'food' ? t.copyWith(amountCents: 12345) : t)
        .toList();
    await h.financial(tester).refresh();
    await tester.pumpAndSettle();
    await editOpen(tester, 'food');
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('transaction-amount')),
          )
          .controller!
          .text,
      Money.formatCents(12345),
    );
    await amount(tester, '123,46');
    await shellSave(tester);
    expect(h.transactions.updates.single.$1.amountCents, 12346);
  });
  testWidgets(
    'Recente do Dashboard reflete a edição confirmada do mesmo controller',
    (tester) async {
      final h = await mount(tester);
      await editOpen(tester, 'transport');
      await amount(tester, '99,99');
      await shellSave(tester);
      await shellTab(tester, 'Início');
      await tester.ensureVisible(find.text('Transações recentes'));
      expect(find.text('− ${Money.formatCents(9999)}'), findsOneWidget);
      expect(h.transactions.reads, 2);
    },
  );
  testWidgets(
    'CA-07 salvar valor 200 atualiza histórico/saldo e mantém instante original',
    (tester) async {
      final h = await mount(tester);
      final original = h.financial(tester).transactionById('food')!;
      await editOpen(tester, 'food');
      await amount(tester, '200,00');
      await shellSave(tester);
      expect(find.byType(TransactionFormScreen), findsNothing);
      expect(h.financial(tester).summary!.balanceCents, 65000);
      final updated = h.transactions.updates.single;
      expect(updated.$1.id, original.id);
      expect(updated.$1.userId, original.userId);
      expect(updated.$1.createdAt, original.createdAt);
      expect(updated.$1.occurredAt, original.occurredAt);
      expect(updated.$1.occurredAt.isUtc, isTrue);
      expect(updated.$2, 'A');
      expect(h.transactions.writes, isEmpty);
      expect(h.transactions.reads, 2);
      await shellTab(tester, 'Início');
      expect(find.text(Money.formatCents(65000)), findsOneWidget);
    },
  );
  testWidgets(
    'Editar tipo limpa categoria, nova categoria/descrição e data são salvas',
    (tester) async {
      final h = await mount(tester);
      await editOpen(tester, 'food');
      await tester.tap(find.byKey(const ValueKey('type-income')));
      await tester.pumpAndSettle();
      expect(find.text('Selecione'), findsOneWidget);
      final category = find.byKey(
        const ValueKey('transaction-category-income'),
      );
      await tester.tap(category);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Outras receitas').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('transaction-description')),
        'Receita ajustada',
      );
      await tester.tap(find.byKey(const ValueKey('transaction-date')));
      await tester.pumpAndSettle();
      tester
          .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
          .onDateChanged(DateTime(2026, 10, 3));
      await tester.pump();
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      await shellSave(tester);
      final updated = h.transactions.updates.single.$1;
      expect(updated.type, TransactionType.income);
      expect(updated.category, Category.otherIncome);
      expect(updated.description, 'Receita ajustada');
      expect(updated.occurredAt, DateTime(2026, 10, 3));
    },
  );
  testWidgets(
    'Confirmar mesmo dia no calendário conserva hora, UTC e microssegundos',
    (tester) async {
      final h = await mount(tester);
      final original = h.financial(tester).transactionById('food')!;
      await editOpen(tester, 'food');
      await tester.tap(find.byKey(const ValueKey('transaction-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      await shellSave(tester);
      expect(h.transactions.updates.single.$1.occurredAt, original.occurredAt);
    },
  );
  testWidgets('Edição inválida bloqueia envio e preserva rascunho', (
    tester,
  ) async {
    final h = await mount(tester);
    await editOpen(tester, 'food');
    await amount(tester, '0');
    await tester.enterText(
      find.byKey(const ValueKey('transaction-description')),
      '',
    );
    await shellSave(tester);
    expect(h.transactions.updates, isEmpty);
    expect(find.byType(TransactionFormScreen), findsOneWidget);
  });
  testWidgets(
    'Permissão negada mantém campos preenchidos e não inventa sucesso',
    (tester) async {
      final h = await mount(tester);
      h.transactions.updateCall = (_) async => throw const DataFailure(
        DataFailureKind.permissionDenied,
        'Edição negada.',
      );
      await editOpen(tester, 'food');
      await amount(tester, '200,00');
      await shellSave(tester);
      expect(find.text('Edição negada.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('transaction-amount')),
            )
            .controller!
            .text,
        '200,00',
      );
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(h.financial(tester).summary!.balanceCents, 60000);
    },
  );
  testWidgets('Duplo envio e teclado editam somente uma vez', (tester) async {
    final h = await mount(tester);
    final done = Completer<void>();
    h.transactions.updateCall = (value) async {
      await done.future;
      h.transactions.source = h.transactions.source
          .map((t) => t.id == value.id ? value : t)
          .toList();
    };
    await editOpen(tester, 'food');
    final submit = tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const ValueKey('transaction-description')),
            matching: find.byType(TextField),
          ),
        )
        .onSubmitted!;
    await shellSave(tester, settle: false);
    submit('Texto');
    await tester.tap(find.byKey(const ValueKey('transaction-submit')));
    expect(h.transactions.updates.length, 1);
    done.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormScreen), findsNothing);
  });
  testWidgets(
    'Commit com falha de recarga permite somente leitura e retorno após confirmar',
    (tester) async {
      final h = await mount(tester);
      await editOpen(tester, 'food');
      await amount(tester, '200');
      h.transactions.read = () async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      await shellSave(tester);
      expect(
        find.text(
          'Edição salva; não foi possível atualizar os dados. Atualize sem salvar novamente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Salvar alterações'), findsNothing);
      expect(h.financial(tester).isStale, isTrue);
      h.transactions.read = null;
      await retryRead(tester);
      expect(find.byType(TransactionFormScreen), findsNothing);
      expect(h.transactions.updates.length, 1);
      expect(h.transactions.reads, 3);
    },
  );
  for (final persisted in [true, false]) {
    testWidgets(
      'Edição com resultado incerto persistido=$persisted reconcilia por leitura',
      (tester) async {
        final h = await mount(tester);
        h.transactions.updateCall = (value) async {
          if (persisted) {
            h.transactions.source = h.transactions.source
                .map((t) => t.id == value.id ? value : t)
                .toList();
          }
          throw const DataFailure(
            DataFailureKind.unavailable,
            'Sem confirmação.',
          );
        };
        await editOpen(tester, 'food');
        await amount(tester, '200');
        await shellSave(tester);
        expect(
          find.textContaining('Não foi possível confirmar a edição.'),
          findsOneWidget,
        );
        expect(find.text('Salvar alterações'), findsNothing);
        await retryRead(tester);
        expect(
          find.byType(TransactionFormScreen),
          persisted ? findsNothing : findsOneWidget,
        );
        expect(h.transactions.updates.length, 1);
        expect(h.transactions.writes, isEmpty);
        if (!persisted) expect(find.text('Salvar alterações'), findsNothing);
      },
    );
  }
  testWidgets(
    'Registro remoto ausente oferece leitura e nunca create/reenvio',
    (tester) async {
      final h = await mount(tester);
      await editOpen(tester, 'food');
      h.transactions.source = h.transactions.source
          .where((t) => t.id != 'food')
          .toList();
      await shellSave(tester);
      expect(find.text('Transação não encontrada.'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsNothing);
      await retryRead(tester);
      expect(h.financial(tester).transactionById('food'), isNull);
      expect(h.transactions.updates.length, 1);
      expect(h.transactions.writes, isEmpty);
    },
  );
  for (final inMenu in [true, false]) {
    testWidgets(
      'Troca de UID remove ${inMenu ? 'menu' : 'edição'} e dados anteriores',
      (tester) async {
        final h = await mount(tester);
        if (inMenu) {
          await editMenu(tester, 'food');
        } else {
          await editOpen(tester, 'food');
        }
        h.transactions.uid = 'B';
        h.transactions.source = [];
        h.session.auth.events.add(authUser('B'));
        await tester.pumpAndSettle();
        expect(
          find.byType(TransactionActionsSheet, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.byType(TransactionFormScreen, skipOffstage: false),
          findsNothing,
        );
        expect(find.text('Olá, Bruno (teste) 👋'), findsOneWidget);
        expect(h.transactions.updates, isEmpty);
      },
    );
  }
  testWidgets(
    'Logout durante update destrói formulário; resposta tardia não navega',
    (tester) async {
      final h = await mount(tester);
      final pending = Completer<void>();
      h.transactions.updateCall = (_) => pending.future;
      await editOpen(tester, 'food');
      await shellSave(tester, settle: false);
      await h.session.controller.signOut();
      await tester.pumpAndSettle();
      pending.complete();
      await tester.pumpAndSettle();
      expect(
        find.byType(TransactionFormScreen, skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(PageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Formulário com original adulterado não exibe dados nem permite criar',
    (tester) async {
      final h = await mount(tester);
      final financial = h.financial(tester);
      final forged = financial
          .transactionById('food')!
          .copyWith(description: 'Texto adulterado');
      unawaited(
        Navigator.of(tester.element(find.byType(MainShell))).push<void>(
          MaterialPageRoute(
            builder: (_) => TransactionFormScreen(
              controller: financial,
              transaction: forged,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Texto adulterado'), findsNothing);
      expect(find.text('Salvar alterações'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(h.transactions.updates, isEmpty);
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Editar $width dp texto $scale: menu, valor extenso e teclado',
        (tester) async {
          final h = await mount(
            tester,
            width: width,
            scale: scale,
            large: true,
          );
          final semantics = tester.ensureSemantics();
          try {
            await editMenu(tester, 'income');
            expect(find.text('Editar').hitTestable(), findsOneWidget);
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await tester.tap(find.text('Editar'));
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<TextFormField>(
                    find.byKey(const ValueKey('transaction-amount')),
                  )
                  .controller!
                  .text,
              Money.formatCents(Money.maxSafeCents),
            );
            await tester.showKeyboard(
              find.byKey(const ValueKey('transaction-description')),
            );
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pump();
            await tester.ensureVisible(
              find.byKey(const ValueKey('transaction-submit')),
            );
            await tester.pump();
            expect(
              find.byKey(const ValueKey('transaction-submit')).hitTestable(),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            expect(h.transactions.updates, isEmpty);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
