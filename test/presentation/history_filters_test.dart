import 'dart:ui' show Tristate;

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/presentation/screens/transactions/transactions_screen.dart';
import 'package:bolsozen/presentation/widgets/history_category_dialog.dart';
import 'package:bolsozen/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'financial_test_fakes.dart';
import 'main_shell_harness.dart';
import 'session_fakes.dart';

Finder historyScroll() => find.descendant(
  of: find.byType(ListView),
  matching: find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  ),
);

Future<void> historyTop(WidgetTester tester) async {
  tester.state<ScrollableState>(historyScroll()).position.jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> historyQuery(WidgetTester tester, String query) async {
  await historyTop(tester);
  await tester.enterText(find.byKey(const ValueKey('history-search')), query);
  await tester.pumpAndSettle();
}

Future<void> historyType(WidgetTester tester, String type) async {
  await historyTop(tester);
  final button = find.byKey(ValueKey('history-type-$type'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> categoryOpen(WidgetTester tester) async {
  await historyTop(tester);
  await tester.tap(find.byKey(const ValueKey('history-category-filter')));
  await tester.pumpAndSettle();
}

Future<void> categoryChoose(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('history-category-choice')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> categoryApply(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('history-category-apply')));
  await tester.pumpAndSettle();
}

void main() {
  Future<MainShellHarness> mount(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool empty = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = MainShellHarness();
    if (!empty) h.transactions.source = financialVisualTransactions('A');
    await h.mount(tester);
    await shellTab(tester, 'Transações');
    return h;
  }

  List<String> visibleIds(WidgetTester tester) => tester
      .widgetList<TransactionTile>(find.byType(TransactionTile))
      .map((t) => t.transaction.id)
      .toList();

  for (final (query, id) in [
    ('  MERCADO  ', 'food'),
    ('alimentacao', 'food'),
    ('SALÁ', 'income'),
    ('trans', 'transport'),
  ]) {
    testWidgets('Pesquisa $query por descrição/categoria sem leituras', (
      tester,
    ) async {
      final h = await mount(tester);
      final summary = h.financial(tester).summary;
      final original = h.financial(tester).transactions;
      await historyQuery(tester, query);
      expect(visibleIds(tester), [id]);
      expect(h.financial(tester).summary, same(summary));
      expect(h.financial(tester).transactions, same(original));
      expect(h.transactions.reads, 1);
      await tester.tap(find.byKey(const ValueKey('history-clear-search')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('history-search')))
            .controller!
            .text,
        isEmpty,
      );
    });
  }
  testWidgets(
    'Chips Todas/Receitas/Despesas preservam pesquisa e semântica selecionada',
    (tester) async {
      final h = await mount(tester);
      final semantics = tester.ensureSemantics();
      try {
        await historyQuery(tester, 'teste visual');
        await historyType(tester, 'income');
        expect(visibleIds(tester), ['income']);
        expect(
          tester
              .getSemantics(find.byKey(const ValueKey('history-type-income')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        await historyType(tester, 'expense');
        expect(visibleIds(tester).every((id) => id != 'income'), isTrue);
        await historyType(tester, 'all');
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('history-search')))
              .controller!
              .text,
          'teste visual',
        );
        expect(h.transactions.reads, 1);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'Modal Aplicar combina tipo/categoria/texto, Cancelar não altera e foco volta',
    (tester) async {
      final h = await mount(tester);
      await historyQuery(tester, 'mercado');
      await historyType(tester, 'expense');
      await categoryOpen(tester);
      await categoryChoose(tester, 'Alimentação');
      await categoryApply(tester);
      expect(visibleIds(tester), ['food']);
      expect(find.text('Categoria: Alimentação'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('history-category-filter')),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await categoryOpen(tester);
      await categoryChoose(tester, 'Transporte');
      await tester.tap(find.byKey(const ValueKey('history-category-cancel')));
      await tester.pumpAndSettle();
      expect(visibleIds(tester), ['food']);
      expect(find.text('Categoria: Alimentação'), findsOneWidget);
      expect(h.transactions.reads, 1);
    },
  );
  testWidgets(
    'Todas mantém categoria/texto; tipo incompatível limpa somente categoria',
    (tester) async {
      final h = await mount(tester);
      await historyType(tester, 'expense');
      await categoryOpen(tester);
      expect(
        tester
            .widget<DropdownButtonFormField<Category>>(
              find.byKey(const ValueKey('history-category-choice')),
            )
            .initialValue,
        isNull,
      );
      await categoryChoose(tester, 'Alimentação');
      await categoryApply(tester);
      await historyQuery(tester, 'teste');
      await historyType(tester, 'all');
      expect(visibleIds(tester), ['food']);
      await historyType(tester, 'income');
      expect(visibleIds(tester), ['income']);
      expect(find.text('Categoria: Alimentação'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('history-search')))
            .controller!
            .text,
        'teste',
      );
      await categoryOpen(tester);
      final field = tester.widget<DropdownButtonFormField<Category>>(
        find.byKey(const ValueKey('history-category-choice')),
      );
      expect(field.initialValue, isNull);
      await tester.tap(find.byKey(const ValueKey('history-category-choice')));
      await tester.pumpAndSettle();
      expect(find.text('Salário'), findsWidgets);
      expect(find.text('Alimentação'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('history-category-cancel')));
      await tester.pumpAndSettle();
      expect(h.transactions.reads, 1);
    },
  );
  testWidgets(
    'Remover categoria em Aplicar preserva demais critérios; Limpar filtros remove todos',
    (tester) async {
      final h = await mount(tester);
      await historyType(tester, 'expense');
      await historyQuery(tester, 'teste');
      await categoryOpen(tester);
      await categoryChoose(tester, 'Alimentação');
      await categoryApply(tester);
      await categoryOpen(tester);
      await categoryChoose(tester, 'Todas');
      await categoryApply(tester);
      expect(find.textContaining('Categoria:'), findsNothing);
      expect(visibleIds(tester), isNot(contains('income')));
      await categoryOpen(tester);
      await tester.tap(find.byKey(const ValueKey('history-clear-all')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('history-search')))
            .controller!
            .text,
        isEmpty,
      );
      expect(h.transactions.reads, 1);
    },
  );
  testWidgets(
    'Nenhum resultado mostra limpar; vazio real mostra adicionar, sem falso erro',
    (tester) async {
      final h = await mount(tester);
      await historyQuery(tester, 'inexistente');
      expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
      expect(find.text('Nenhuma transação ainda.'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('history-clear-results')));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionTile), findsWidgets);
      h.transactions.source = [];
      await h.financial(tester).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma transação ainda.'), findsOneWidget);
      expect(find.text('Adicionar movimentação'), findsOneWidget);
      expect(find.text('Nenhuma transação encontrada'), findsNothing);
    },
  );
  testWidgets(
    'Erro/stale permanece explícito mesmo quando filtro não encontra registros',
    (tester) async {
      final h = await mount(tester);
      await historyQuery(tester, 'inexistente');
      h.transactions.read = () async => throw const DataFailure(
        DataFailureKind.unavailable,
        'Falha de rede.',
      );
      await h.financial(tester).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Falha de rede.'), findsOneWidget);
      expect(
        find.text('Dados da última carga; podem estar desatualizados.'),
        findsOneWidget,
      );
      expect(find.text('Nenhuma transação encontrada'), findsNothing);
      h.transactions.read = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
    },
  );
  testWidgets(
    'Filtro cobre 201 registros após três páginas sem alterar resumo ou consultas',
    (tester) async {
      final h = await mount(tester);
      h.transactions.source = List.generate(
        201,
        (i) => transaction(
          id: 'row-${i.toString().padLeft(3, '0')}',
          userId: 'A',
          description: i == 200 ? 'Único distante' : 'Item',
          date: DateTime(2026, 11, 18).subtract(Duration(minutes: i)),
        ),
      );
      await h.financial(tester).refresh();
      await tester.pumpAndSettle();
      final summary = h.financial(tester).summary;
      final reads = h.transactions.reads;
      expect(reads, 4); // Uma carga inicial + 100/100/1.
      await historyQuery(tester, 'unico');
      expect(visibleIds(tester), ['row-200']);
      expect(h.financial(tester).summary, same(summary));
      expect(h.transactions.reads, reads);
    },
  );
  testWidgets(
    'Edição/exclusão atualizam resultados mantendo critérios entre abas',
    (tester) async {
      final h = await mount(tester);
      await historyQuery(tester, 'mercado');
      await historyType(tester, 'expense');
      await shellTab(tester, 'Início');
      await shellTab(tester, 'Transações');
      expect(visibleIds(tester), ['food']);
      final original = h.financial(tester).transactionById('food')!;
      await h
          .financial(tester)
          .updateTransaction(
            original: original,
            type: original.type,
            amountCents: original.amountCents,
            category: original.category,
            description: 'Feira',
            occurredAt: original.occurredAt,
          );
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
      await historyQuery(tester, 'alimentacao');
      expect(visibleIds(tester), ['food']);
      await h
          .financial(tester)
          .deleteTransaction(h.financial(tester).transactionById('food')!);
      await tester.pumpAndSettle();
      expect(find.text('Nenhuma transação encontrada'), findsOneWidget);
      expect(h.transactions.reads, 3);
    },
  );
  testWidgets('Logout e troca de UID descartam filtros e modal pendente', (
    tester,
  ) async {
    final h = await mount(tester);
    await historyQuery(tester, 'privado');
    await historyType(tester, 'expense');
    await categoryOpen(tester);
    h.transactions.uid = 'B';
    h.transactions.source = financialVisualTransactions('B');
    h.session.auth.events.add(authUser('B'));
    await tester.pumpAndSettle();
    expect(
      find.byType(HistoryCategoryDialog, skipOffstage: false),
      findsNothing,
    );
    await shellTab(tester, 'Transações');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('history-search')))
          .controller!
          .text,
      isEmpty,
    );
    await historyQuery(tester, 'novo');
    await h.session.controller.signOut();
    await tester.pumpAndSettle();
    h.session.auth.events.add(authUser('B'));
    await tester.pumpAndSettle();
    await shellTab(tester, 'Transações');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('history-search')))
          .controller!
          .text,
      isEmpty,
    );
  });
  testWidgets(
    'Cabeçalhos Hoje/Ontem mudam na virada do ano e ao retomar sem rede',
    (tester) async {
      final h = FinancialTestHarness();
      await tester.runAsync(h.start);
      h.repository.source = [
        transaction(userId: h.repository.uid, date: DateTime(2026, 12, 31, 20)),
      ];
      await h.controller.load();
      var now = DateTime(2026, 12, 31, 23, 59);
      await tester.pumpWidget(
        BolsoZenApp(
          home: TransactionsScreen(controller: h.controller, clock: () => now),
        ),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await h.close();
      });
      expect(find.text('Hoje, 31 de dez. de 2026'), findsOneWidget);
      now = DateTime(2027, 1, 1, 0, 1);
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('Ontem, 31 de dez. de 2026'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2027, 1, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('31 de dez. de 2026'), findsOneWidget);
      expect(h.repository.reads, 1);
    },
  );
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Filtros $width dp texto $scale: controles 48dp, modal e acessibilidade',
        (tester) async {
          final h = await mount(tester, width: width, scale: scale);
          final semantics = tester.ensureSemantics();
          try {
            for (final type in ['all', 'income', 'expense']) {
              final button = find.byKey(ValueKey('history-type-$type'));
              await tester.ensureVisible(button);
              expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
              await tester.tap(button);
              await tester.pumpAndSettle();
            }
            await historyTop(tester);
            expect(
              tester.getSize(
                find.byKey(const ValueKey('history-category-filter')),
              ),
              const Size(48, 48),
            );
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('history-search')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await categoryOpen(tester);
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('history-category-cancel')),
            );
            await tester.tap(
              find.byKey(const ValueKey('history-category-cancel')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(h.transactions.reads, 1);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
