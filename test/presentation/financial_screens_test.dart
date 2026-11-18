import 'dart:async';

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/core/theme/app_colors.dart';
import 'package:bolsozen/core/theme/financial_visual_tokens.dart';
import 'package:bolsozen/presentation/widgets/category_icon.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:bolsozen/presentation/screens/transactions/transactions_screen.dart';
import 'package:bolsozen/presentation/widgets/balance_card.dart';
import 'package:bolsozen/presentation/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'financial_test_fakes.dart';
import 'session_fakes.dart';

void main() {
  late FinancialTestHarness h;
  setUp(() async {
    h = FinancialTestHarness();
    await h.start();
  });
  tearDown(() => h.close());

  Future<void> show(
    WidgetTester tester, {
    bool list = false,
    double width = 390,
    double scale = 1,
    bool wrongProfile = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BolsoZenApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: list
                ? TransactionsScreen(
                    controller: h.controller,
                    today: DateTime(2026, 11, 5),
                  )
                : DashboardScreen(
                    controller: h.controller,
                    clock: () => DateTime(2026, 11, 18),
                    profile: wrongProfile
                        ? userProfile('wrong', name: 'Não exibir')
                        : h.profile,
                  ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final income in [50, 100, 150]) {
    testWidgets(
      'Dashboard saldo ${income - 100}, nome e tema reais da fixture',
      (tester) async {
        h.repository.source = [
          transaction(
            userId: h.repository.uid,
            category: Category.salary,
            amount: income,
          ),
          transaction(id: 'out', userId: h.repository.uid, amount: 100),
        ];
        await h.controller.load();
        await show(tester);
        expect(find.text('Olá, Pessoa de teste 👋'), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('global-balance')))
              .data,
          Money.formatCents(income - 100),
        );
        final card = tester.widget<Card>(
          find.descendant(
            of: find.byType(BalanceCard),
            matching: find.byType(Card),
          ),
        );
        expect(card.color, AppColors.primary);
        final theme = Theme.of(tester.element(find.byType(DashboardScreen)));
        expect(theme.useMaterial3, isTrue);
        expect(theme.textTheme.bodyMedium!.fontFamily, 'Roboto');
        expect(
          tester
              .widget<FloatingActionButton>(find.byType(FloatingActionButton))
              .onPressed,
          isNull,
        );
        expect(find.byType(NavigationBar), findsNothing);
      },
    );
  }

  testWidgets(
    'Dashboard mantém mês atual sem seletor e sem consulta adicional',
    (tester) async {
      h.repository.source = financialVisualTransactions(h.repository.uid);
      await h.controller.load();
      await show(tester);
      expect(find.text('R\$ 1.000,00'), findsOneWidget);
      expect(find.text('R\$ 350,00'), findsOneWidget);
      expect(find.byTooltip('Mês anterior'), findsNothing);
      h.controller.selectMonth(FinancialMonth(2026, 10));
      await tester.pump();
      await tester.pump();
      expect(h.controller.month, FinancialMonth(2026, 11));
      expect(find.text('R\$ 350,00'), findsOneWidget);
      expect(find.text('R\$ 600,00'), findsOneWidget);
      expect(h.repository.reads, 1);
    },
  );

  testWidgets('Lista usa ordem do domínio, sinais, categorias e datas', (
    tester,
  ) async {
    h.repository.source = financialVisualTransactions(h.repository.uid);
    await h.controller.load();
    await show(tester, list: true);
    final visible = tester
        .widgetList<TransactionTile>(find.byType(TransactionTile))
        .map((t) => t.transaction.id)
        .toList();
    expect(
      visible,
      h.controller.transactions.take(visible.length).map((t) => t.id),
    );
    expect(find.text('+ R\$ 1.000,00'), findsOneWidget);
    expect(find.text('− R\$ 250,00'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Hoje, 5 de nov. de 2026'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(
      tester
          .widget<Semantics>(
            find
                .descendant(
                  of: find.byType(TransactionTile).first,
                  matching: find.byType(Semantics),
                )
                .first,
          )
          .properties
          .onTap,
      isNull,
    );
    await tester.scrollUntilVisible(find.byKey(const ValueKey('leisure')), 150);
    expect(find.text('Lazer — teste visual'), findsOneWidget);
  });

  for (final list in [false, true]) {
    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: idle carrega e vazio é confirmado',
      (tester) async {
        await show(tester, list: list);
        expect(find.text('Carregue seus dados financeiros.'), findsOneWidget);
        expect(find.byType(BalanceCard), findsNothing);
        await tester.tap(find.text('Carregar dados'));
        await tester.pumpAndSettle();
        expect(find.text('Nenhuma transação ainda.'), findsOneWidget);
        if (!list) expect(find.text('R\$ 0,00'), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: loading não mostra zero/snapshot parcial',
      (tester) async {
        final pending = Completer<List<FinancialTransaction>>();
        h.repository.read = () => pending.future;
        final loading = h.controller.load();
        await show(tester, list: list);
        expect(find.text('Carregando histórico completo…'), findsOneWidget);
        expect(find.textContaining('R\$'), findsNothing);
        expect(find.byType(TransactionTile), findsNothing);
        pending.complete(financialVisualTransactions(h.repository.uid));
        await loading;
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: erro e retry não fabricam saldo zero',
      (tester) async {
        h.repository.read = () async => throw const DataFailure(
          DataFailureKind.unavailable,
          'Verifique sua conexão.',
        );
        await h.controller.load();
        await show(tester, list: list);
        expect(find.text('Verifique sua conexão.'), findsOneWidget);
        expect(find.textContaining('R\$'), findsNothing);
        h.repository.read = null;
        h.repository.source = financialVisualTransactions(h.repository.uid);
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        expect(find.text('Verifique sua conexão.'), findsNothing);
        expect(h.repository.reads, 2);
      },
    );

    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: refresh distingue snapshot antigo e erro',
      (tester) async {
        h.repository.source = financialVisualTransactions(h.repository.uid);
        await h.controller.load();
        await show(tester, list: list);
        final pending = Completer<List<FinancialTransaction>>();
        h.repository.read = () => pending.future;
        final refresh = h.controller.refresh();
        await tester.pump();
        expect(find.text('Atualizando dados…'), findsOneWidget);
        expect(
          find.text('Dados da última carga; podem estar desatualizados.'),
          findsOneWidget,
        );
        expect(
          list ? find.byType(TransactionTile) : find.byType(BalanceCard),
          list ? findsWidgets : findsOneWidget,
        );
        pending.completeError(
          const DataFailure(DataFailureKind.unavailable, 'Sem rede.'),
        );
        await refresh;
        await tester.pumpAndSettle();
        expect(find.text('Sem rede.'), findsOneWidget);
        expect(
          find.text('Dados da última carga; podem estar desatualizados.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: troca de UID remove dados anteriores',
      (tester) async {
        h.repository.source = financialVisualTransactions(h.repository.uid);
        await h.controller.load();
        await show(tester, list: list);
        h.session.auth.events.add(null);
        await tester.pump();
        expect(find.textContaining('R\$'), findsNothing);
        expect(find.byType(TransactionTile), findsNothing);
        expect(find.textContaining('Pessoa de teste'), findsNothing);
        expect(find.byTooltip('Atualizar dados'), findsNothing);
      },
    );
  }

  testWidgets('Perfil incompatível não mostra nome nem saldo', (tester) async {
    h.repository.source = financialVisualTransactions(h.repository.uid);
    await h.controller.load();
    await show(tester, wrongProfile: true);
    expect(
      find.text('Não foi possível confirmar a identidade desta sessão.'),
      findsOneWidget,
    );
    expect(find.textContaining('Não exibir'), findsNothing);
    expect(find.byType(BalanceCard), findsNothing);
  });

  testWidgets(
    'Composição revisada mantém dados reais e ações futuras desabilitadas',
    (tester) async {
      h.repository.source = financialVisualTransactions(h.repository.uid);
      await h.controller.load();
      await show(tester);
      expect(find.text('Gastos por categoria'), findsOneWidget);
      expect(find.text('71,4%'), findsOneWidget);
      expect(find.text('28,6%'), findsOneWidget);
      expect(find.text('Meta do mês'), findsOneWidget);
      expect(find.text('Em breve'), findsOneWidget);
      expect(find.text('72%'), findsNothing);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.visibility_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widgetList<TextButton>(find.byType(TextButton))
            .every((b) => b.onPressed == null),
        isTrue,
      );
      final icons = tester
          .widgetList<CategoryIcon>(find.byType(CategoryIcon))
          .toList();
      expect(
        icons.firstWhere((i) => i.category == Category.food).foreground,
        FinancialVisualTokens.shopping,
      );
      expect(
        icons.firstWhere((i) => i.category == Category.transport).foreground,
        FinancialVisualTokens.transport,
      );
      expect(h.repository.reads, 1);
    },
  );

  for (final list in [false, true]) {
    testWidgets(
      '${list ? 'Histórico' : 'Dashboard'} atualiza por gesto sem ocupar o sino',
      (tester) async {
        h.repository.source = financialVisualTransactions(h.repository.uid);
        await h.controller.load();
        await show(tester, list: list);
        h.repository.source = [];
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(h.repository.reads, 2);
        expect(find.text('Nenhuma transação ainda.'), findsOneWidget);
        expect(find.byType(TransactionTile), findsNothing);
      },
    );
  }

  for (final list in [false, true]) {
    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: aviso stale permanece visível após rolagem',
      (tester) async {
        h.repository.source = List.generate(
          201,
          (i) => transaction(
            id: 'row${i.toString().padLeft(3, '0')}',
            userId: h.repository.uid,
          ),
        );
        await h.controller.load();
        await show(tester, list: list, scale: 2);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        final pending = Completer<List<FinancialTransaction>>();
        h.repository.read = () => pending.future;
        final refresh = h.controller.refresh();
        await tester.pump();
        expect(
          find
              .text('Dados da última carga; podem estar desatualizados.')
              .hitTestable(),
          findsOneWidget,
        );
        pending.completeError(
          const DataFailure(DataFailureKind.unavailable, 'Sem rede.'),
        );
        await refresh;
        await tester.pumpAndSettle();
        expect(
          find
              .text('Dados da última carga; podem estar desatualizados.')
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Semântica descreve tipo, descrição, data e valor sem ação falsa',
    (tester) async {
      final semantics = tester.ensureSemantics();
      h.repository.source = financialVisualTransactions(h.repository.uid);
      await h.controller.load();
      await show(tester, list: true);
      expect(
        find.bySemanticsLabel(
          'Despesa, Supermercado — teste visual, Alimentação, 04/11/2026, − R\$ 250,00',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Receita, Salário — teste visual, Salário, 03/11/2026, + R\$ 1.000,00',
        ),
        findsOneWidget,
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
      semantics.dispose();
    },
  );

  for (final list in [false, true]) {
    testWidgets(
      '${list ? 'Lista' : 'Dashboard'}: contraste e alvos acessíveis',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          h.repository.source = financialVisualTransactions(h.repository.uid);
          await h.controller.load();
          await show(tester, list: list);
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final list in [false, true]) {
        testWidgets(
          '${list ? 'Lista' : 'Dashboard'} $width dp texto $scale: nomes e valores extensos',
          (tester) async {
            h.repository.source = [
              transaction(
                userId: h.repository.uid,
                category: Category.salary,
                amount: Money.maxSafeCents,
                description: List.filled(12, 'Descrição').join(' '),
              ),
            ];
            await h.controller.load();
            await show(tester, list: list, width: width, scale: scale);
            await tester.pump();
            expect(tester.takeException(), isNull);
            final amount = find.text(
              list
                  ? '+ R\$ 90.071.992.547.409,91'
                  : 'R\$ 90.071.992.547.409,91',
            );
            expect(amount, findsWidgets);
            expect(
              find
                  .byType(Text)
                  .evaluate()
                  .map((e) => (e.widget as Text).overflow)
                  .contains(TextOverflow.ellipsis),
              isFalse,
            );
            if (!list) {
              await tester.scrollUntilVisible(
                find.text('Transações recentes'),
                200,
                scrollable: find.byType(Scrollable).first,
              );
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
}
