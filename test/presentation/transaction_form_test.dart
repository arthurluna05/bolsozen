import 'dart:async';

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/presentation/screens/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'financial_test_fakes.dart';

void main() {
  late FinancialTestHarness h;
  setUp(() async {
    h = FinancialTestHarness();
    await h.start();
  });
  tearDown(() => h.close());

  Future<void> show(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    double keyboard = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BolsoZenApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            child: TransactionFormScreen(
              controller: h.controller,
              clock: () => DateTime(2026, 11, 18),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    bool income = false,
    String amount = '120,50',
    String description = 'Almoço',
  }) async {
    if (income) {
      await tester.tap(find.byKey(const ValueKey('type-income')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-amount')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      amount,
    );
    final category = find.byKey(
      ValueKey('transaction-category-${income ? 'income' : 'expense'}'),
    );
    await tester.ensureVisible(category);
    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.text(income ? 'Salário' : 'Alimentação').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('transaction-description')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-description')),
      description,
    );
  }

  Future<void> save(WidgetTester tester, {bool settle = true}) async {
    final button = find.byKey(const ValueKey('transaction-submit'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  void commit(String id) {
    final draft = h.repository.writes.single;
    h.repository.source = [
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

  testWidgets(
    'Campos vazios validam sem gravar; conta principal não é seletor',
    (tester) async {
      await show(tester);
      await save(tester);
      expect(find.text('Valor monetário inválido'), findsOneWidget);
      expect(find.text('Selecione uma categoria compatível.'), findsOneWidget);
      expect(find.text('Informe a descrição.'), findsOneWidget);
      expect(find.text('Conta principal'), findsOneWidget);
      expect(h.repository.writes, isEmpty);
    },
  );
  for (final income in [false, true]) {
    testWidgets(
      'Salva ${income ? 'receita' : 'despesa'} em centavos e confirma leitura',
      (tester) async {
        await show(tester);
        await fill(
          tester,
          income: income,
          amount: income ? 'R\$ 120,50' : '120,50',
        );
        await save(tester);
        expect(h.repository.writes.single.amountCents, 12050);
        expect(
          h.repository.writes.single.type,
          income ? TransactionType.income : TransactionType.expense,
        );
        expect(h.controller.summary!.balanceCents, income ? 12050 : -12050);
        expect(
          find.text('Movimentação salva e dados atualizados.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('transaction-submit')), findsNothing);
      },
    );
  }
  for (final amount in ['0', '-1', '90071992547409,93']) {
    testWidgets('Valor inválido $amount preserva entrada e impede envio', (
      tester,
    ) async {
      await show(tester);
      await fill(tester, amount: amount);
      await save(tester);
      expect(h.repository.writes, isEmpty);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('transaction-amount')),
            )
            .controller!
            .text,
        amount,
      );
    });
  }
  testWidgets(
    'Troca de tipo limpa categoria incompatível e preserva outros campos',
    (tester) async {
      await show(tester);
      await fill(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('type-income')));
      await tester.tap(find.byKey(const ValueKey('type-income')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<Category>>(
              find.byKey(const ValueKey('transaction-category-income')),
            )
            .initialValue,
        isNull,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('transaction-amount')),
            )
            .controller!
            .text,
        '120,50',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('transaction-description')),
            )
            .controller!
            .text,
        'Almoço',
      );
      expect(h.repository.writes, isEmpty);
    },
  );
  testWidgets('Data futura é permitida e enviada como calendário local', (
    tester,
  ) async {
    await show(tester);
    await fill(tester);
    await tester.tap(find.byKey(const ValueKey('transaction-date')));
    await tester.pumpAndSettle();
    tester
        .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
        .onDateChanged(DateTime(2027, 1, 2));
    await tester.pump();
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    await save(tester);
    expect(h.repository.writes.single.occurredAt, DateTime(2027, 1, 2));
    expect(h.controller.summary!.totals.expenseCents, 0);
  });
  testWidgets(
    'Duplo toque e submit do teclado não duplicam gravação pendente',
    (tester) async {
      await show(tester);
      await fill(tester);
      final pending = Completer<String>();
      h.repository.write = (_) => pending.future;
      await save(tester, settle: false);
      await tester.tap(find.byKey(const ValueKey('transaction-submit')));
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('transaction-description')),
              matching: find.byType(TextField),
            ),
          )
          .onSubmitted!('Almoço');
      expect(h.repository.writes, hasLength(1));
      commit('saved');
      pending.complete('saved');
      await tester.pumpAndSettle();
      expect(h.repository.writes, hasLength(1));
    },
  );
  testWidgets('Erro definido de permissão preserva campos e permite correção', (
    tester,
  ) async {
    h.repository.write = (_) async => throw const DataFailure(
      DataFailureKind.permissionDenied,
      'Você não tem permissão para salvar.',
    );
    await show(tester);
    await fill(tester);
    await save(tester);
    expect(find.text('Você não tem permissão para salvar.'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('transaction-description')),
          )
          .controller!
          .text,
      'Almoço',
    );
    expect(find.byKey(const ValueKey('transaction-submit')), findsOneWidget);
  });
  testWidgets(
    'Falha de rede não vira sucesso nem permite reenviar o mesmo formulário',
    (tester) async {
      h.repository.write = (_) async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      await show(tester);
      await fill(tester);
      await save(tester);
      expect(
        find.textContaining('Não foi possível confirmar a gravação.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('transaction-submit')), findsNothing);
      await tester.ensureVisible(find.text('Atualizar dados'));
      await tester.tap(find.text('Atualizar dados'));
      await tester.pumpAndSettle();
      expect(h.repository.writes, hasLength(1));
      expect(
        find.textContaining(
          'Confira o histórico antes de iniciar outro lançamento.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('transaction-submit')), findsNothing);
    },
  );
  testWidgets(
    'Gravação confirmada com erro de recarga só oferece atualização',
    (tester) async {
      h.repository.write = (_) async {
        commit('saved');
        h.repository.read = () async =>
            throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
        return 'saved';
      };
      await show(tester);
      await fill(tester);
      await save(tester);
      expect(
        find.textContaining('Movimentação salva; não foi possível atualizar'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('transaction-submit')), findsNothing);
      h.repository.read = null;
      await tester.ensureVisible(find.text('Atualizar dados'));
      await tester.tap(find.text('Atualizar dados'));
      await tester.pumpAndSettle();
      expect(
        find.text('Movimentação salva e dados atualizados.'),
        findsOneWidget,
      );
      expect(h.repository.writes, hasLength(1));
    },
  );
  testWidgets('Logout durante envio oculta campos e ignora conclusão tardia', (
    tester,
  ) async {
    await show(tester);
    await fill(tester);
    final pending = Completer<String>();
    h.repository.write = (_) => pending.future;
    await save(tester, settle: false);
    h.session.auth.events.add(null);
    await tester.pump();
    expect(find.byType(TextFormField), findsNothing);
    pending.complete('late');
    await tester.pumpAndSettle();
    expect(find.text('Movimentação salva e dados atualizados.'), findsNothing);
    expect(h.controller.summary, isNull);
  });

  testWidgets('TEL-05: labels, contraste e alvos de toque acessíveis', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await show(tester);
      await fill(tester);
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });

  for (final leaveWhileSaving in [false, true]) {
    testWidgets(
      'Rota isolada: ${leaveWhileSaving ? 'sair não cancela commit confirmado depois' : 'sucesso retorna somente após recarga'}',
      (tester) async {
        final results = <bool?>[];
        await tester.pumpWidget(
          BolsoZenApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    results.add(
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => TransactionFormScreen(
                            controller: h.controller,
                            clock: () => DateTime(2026, 11, 18),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir teste'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir teste'));
        await tester.pumpAndSettle();
        await fill(tester);
        if (leaveWhileSaving) {
          final pending = Completer<String>();
          h.repository.write = (_) => pending.future;
          await save(tester, settle: false);
          await tester.tap(find.byTooltip('Voltar'));
          await tester.pumpAndSettle();
          expect(h.controller.isSubmitting, isTrue);
          commit('late');
          pending.complete('late');
          await tester.pumpAndSettle();
          expect(results, [null]);
        } else {
          await save(tester);
          expect(results, [true]);
        }
        expect(find.text('Abrir teste'), findsOneWidget);
        expect(h.repository.writes, hasLength(1));
        expect(h.controller.summary!.balanceCents, -12050);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'TEL-05 $width dp texto $scale e teclado: campos extensos acessíveis',
        (tester) async {
          await show(
            tester,
            width: width,
            scale: scale,
            keyboard: scale == 2 ? 300 : 0,
          );
          await fill(
            tester,
            amount: '90.071.992.547.409,91',
            description: List.filled(12, 'Descrição').join(' '),
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('transaction-submit')),
          );
          expect(tester.takeException(), isNull);
          expect(h.repository.writes, isEmpty);
        },
      );
    }
  }
}
