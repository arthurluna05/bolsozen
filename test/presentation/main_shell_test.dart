import 'dart:async';

import 'package:bolsozen/app/main_shell.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:bolsozen/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:bolsozen/presentation/screens/profile/profile_screen.dart';
import 'package:bolsozen/presentation/screens/transactions/transaction_form_screen.dart';
import 'package:bolsozen/presentation/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'main_shell_harness.dart';
import 'session_fakes.dart';

void main() {
  testWidgets('Login confirmado abre Início e Voltar não recupera login', (
    tester,
  ) async {
    final h = MainShellHarness();
    await h.mount(tester, uid: null);
    h.session.auth.login = () async {
      h.session.auth.events.add(authUser('A'));
      return authUser('A');
    };
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'a@example.test',
    );
    await tester.enterText(find.byType(TextFormField).last, 'senha teste');
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Olá, Ana (teste) 👋'), findsOneWidget);
    expect(h.transactions.reads, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Entrar no BolsoZen'), findsNothing);
  });

  for (final missing in [true, false]) {
    testWidgets(
      'Sem perfil confirmado ($missing) não cria shell nem lê finanças',
      (tester) async {
        final h = MainShellHarness();
        final pending = Completer<UserProfile?>();
        h.session.users.read = (_) =>
            missing ? Future.value(null) : pending.future;
        // pumpAndSettle não termina enquanto há spinner; montar manualmente.
        await tester.pumpWidget(MaterialApp(home: h.experience()));
        h.session.auth.events.add(authUser('A'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.byType(MainShell), findsNothing);
        expect(h.transactions.reads, 0);
        if (!missing) pending.complete(null);
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await h.session.auth.events.close();
      },
    );
  }

  testWidgets(
    'Três destinos reais compartilham controller e uma carga inicial',
    (tester) async {
      final h = MainShellHarness();
      h.transactions.source = List.generate(
        30,
        (i) => transaction(
          id: 'row-$i',
          userId: 'A',
          date: DateTime.now().subtract(Duration(minutes: i)),
        ),
      );
      await h.mount(tester);
      final financial = h.financial(tester);
      final dashboardState = tester.state(find.byType(DashboardScreen));
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Orçamento'), findsNothing);
      expect(find.text('Relatórios'), findsNothing);
      for (final tab in [
        'Transações',
        'Perfil',
        'Início',
        'Transações',
        'Início',
      ]) {
        await shellTab(tester, tab);
        expect(h.financial(tester), same(financial));
      }
      final history = tester.widget<TransactionsScreen>(
        find.byType(TransactionsScreen, skipOffstage: false),
      );
      expect(history.controller, same(financial));
      expect(tester.state(find.byType(DashboardScreen)), same(dashboardState));
      await shellTab(tester, 'Transações');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      final offset = scroll.position.pixels;
      expect(offset, greaterThan(0));
      await shellTab(tester, 'Perfil');
      await shellTab(tester, 'Transações');
      expect(scroll.position.pixels, offset);
      expect(h.transactions.reads, 1);
      expect(h.session.users.reads, ['A']);
    },
  );

  testWidgets('Ver todas abre aba real sem nova consulta', (tester) async {
    final h = MainShellHarness();
    await h.mount(tester);
    await tester.ensureVisible(find.text('Ver todas ›'));
    await tester.tap(find.text('Ver todas ›'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(h.transactions.reads, 1);
  });

  for (final origin in ['Início', 'Transações']) {
    testWidgets(
      'Adicionar em $origin usa mesmo controller, confirma e retorna à origem',
      (tester) async {
        final h = MainShellHarness();
        await h.mount(tester);
        final financial = h.financial(tester);
        if (origin != 'Início') await shellTab(tester, origin);
        await shellAdd(tester);
        expect(find.byType(NavigationBar), findsNothing);
        expect(
          tester
              .widget<TransactionFormScreen>(find.byType(TransactionFormScreen))
              .controller,
          same(financial),
        );
        expect(h.transactions.reads, 1);
        await shellFill(tester);
        await shellSave(tester);
        expect(find.byType(TransactionFormScreen), findsNothing);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          origin == 'Início' ? 0 : 1,
        );
        expect(h.transactions.writes.single.uid, 'A');
        expect(financial.summary!.balanceCents, -12050);
        expect(financial.transactions.single.description, 'Almoço de teste');
        expect(h.transactions.reads, 2);
        await shellTab(tester, 'Início');
        expect(find.text(Money.formatCents(-12050)), findsOneWidget);
        await shellTab(tester, 'Transações');
        expect(find.text('Almoço de teste'), findsOneWidget);
        expect(h.transactions.reads, 2);
      },
    );
  }

  testWidgets('Abrir formulário duas vezes simultâneas mantém uma única rota', (
    tester,
  ) async {
    final h = MainShellHarness();
    await h.mount(tester);
    final add = tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!;
    add();
    add();
    await tester.pumpAndSettle();
    expect(
      find.byType(TransactionFormScreen, skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(
      find.byType(TransactionFormScreen, skipOffstage: false),
      findsNothing,
    );
    expect(h.transactions.reads, 1);
  });

  testWidgets('Voltar do formulário sem salvar não consulta nem perde aba', (
    tester,
  ) async {
    final h = MainShellHarness();
    await h.mount(tester);
    await shellTab(tester, 'Transações');
    await shellAdd(tester);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(h.transactions.reads, 1);
    expect(h.transactions.writes, isEmpty);
  });

  testWidgets('Falha de recarga após commit mantém formulário, retry só lê', (
    tester,
  ) async {
    final h = MainShellHarness();
    await h.mount(tester);
    await shellAdd(tester);
    await shellFill(tester);
    h.transactions.read = () async =>
        throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
    await shellSave(tester);
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(h.financial(tester).hasPendingRefresh, isTrue);
    expect(h.transactions.writes.length, 1);
    h.transactions.read = null;
    await tester.ensureVisible(find.text('Atualizar dados'));
    await tester.tap(find.text('Atualizar dados'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormScreen), findsNothing);
    expect(h.financial(tester).hasPendingRefresh, isFalse);
    expect(h.transactions.writes.length, 1);
    expect(h.transactions.reads, 3);
  });

  testWidgets(
    'Sair do formulário com atualização pendente mantém aviso no shell',
    (tester) async {
      final h = MainShellHarness();
      h.transactions.source = [transaction(userId: 'A')];
      await h.mount(tester);
      await shellAdd(tester);
      await shellFill(tester);
      h.transactions.read = () async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Sem rede.');
      await shellSave(tester);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(h.financial(tester).hasPendingRefresh, isTrue);
      expect(
        find.text('Dados da última carga; podem estar desatualizados.'),
        findsOneWidget,
      );
      await shellTab(tester, 'Transações');
      expect(
        find.text('Dados da última carga; podem estar desatualizados.'),
        findsOneWidget,
      );
      expect(h.transactions.writes.length, 1);
    },
  );

  testWidgets(
    'Logout pelo Perfil destrói controller e Voltar não recupera privado',
    (tester) async {
      final h = MainShellHarness();
      await h.mount(tester);
      final old = h.financial(tester);
      await shellTab(tester, 'Perfil');
      expect(find.text('a@example.test'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('logout-submit')));
      await tester.pumpAndSettle();
      expect(old.phase, FinancialPhase.sessionInvalidated);
      expect(old.transactions, isEmpty);
      expect(() => old.addListener(() {}), throwsFlutterError);
      expect(find.byType(MainShell, skipOffstage: false), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar, skipOffstage: false), findsNothing);
      expect(find.text('Ana (teste)'), findsNothing);
    },
  );

  testWidgets(
    'UID novo remove formulário e snapshot, cria um controller novo',
    (tester) async {
      final h = MainShellHarness();
      h.transactions.source = [
        transaction(userId: 'A', description: 'Privado A'),
      ];
      await h.mount(tester);
      final old = h.financial(tester);
      await shellAdd(tester);
      h.transactions.uid = 'B';
      h.transactions.source = [
        transaction(userId: 'B', description: 'Privado B'),
      ];
      h.session.auth.events.add(authUser('B'));
      await tester.pumpAndSettle();
      expect(old.phase, FinancialPhase.sessionInvalidated);
      expect(old.summary, isNull);
      expect(h.financial(tester), isNot(same(old)));
      expect(h.financial(tester).expectedUserId, 'B');
      expect(find.text('Olá, Bruno (teste) 👋'), findsOneWidget);
      expect(find.text('Privado A', skipOffstage: false), findsNothing);
      expect(
        find.byType(TransactionFormScreen, skipOffstage: false),
        findsNothing,
      );
      expect(h.transactions.reads, 2);
    },
  );

  testWidgets(
    'Leitura atrasada após logout não recria shell nem publica dados',
    (tester) async {
      final h = MainShellHarness();
      final pending = Completer<List<FinancialTransaction>>();
      h.transactions.read = () => pending.future;
      // Não esperar animação infinita de carregamento.
      await tester.pumpWidget(MaterialApp(home: h.experience()));
      h.session.users.profiles['A'] = userProfile('A');
      h.session.auth.events.add(authUser('A'));
      await tester.pump();
      await tester.pump();
      final old = h.financial(tester);
      await h.session.controller.signOut();
      await tester.pumpAndSettle();
      pending.complete([transaction(userId: 'A', description: 'Tardio')]);
      await tester.pumpAndSettle();
      expect(old.summary, isNull);
      expect(find.byType(MainShell), findsNothing);
      expect(find.text('Tardio', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await h.session.auth.events.close();
    },
  );

  testWidgets('Commit atrasado após logout não retorna ao shell removido', (
    tester,
  ) async {
    final h = MainShellHarness();
    await h.mount(tester);
    final old = h.financial(tester);
    final pending = Completer<String>();
    h.transactions.write = (_) => pending.future;
    await shellAdd(tester);
    await shellFill(tester);
    await shellSave(tester, settle: false);
    await h.session.controller.signOut();
    await tester.pumpAndSettle();
    pending.complete('late-id');
    await tester.pumpAndSettle();
    expect(old.phase, FinancialPhase.sessionInvalidated);
    expect(find.byType(MainShell, skipOffstage: false), findsNothing);
    expect(
      find.byType(TransactionFormScreen, skipOffstage: false),
      findsNothing,
    );
    expect(h.transactions.reads, 1);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Shell $width dp fonte $scale: abas, safe area e semântica', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final semantics = tester.ensureSemantics();
        final h = MainShellHarness();
        h.transactions.source = [
          transaction(
            userId: 'A',
            category: Category.salary,
            date: DateTime.now(),
          ),
        ];
        await h.mount(tester);
        for (final tab in ['Início', 'Transações', 'Perfil']) {
          await shellTab(tester, tab);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(
            find.widgetWithText(NavigationDestination, tab).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
        expect(h.transactions.reads, 1);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      });
    }
  }
}
