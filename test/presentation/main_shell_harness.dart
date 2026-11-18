// Composição real do gate/shell; somente contratos externos usam fakes locais.
import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/auth_experience.dart';
import 'package:bolsozen/presentation/controllers/financial_controller.dart';
import 'package:bolsozen/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'financial_test_fakes.dart';
import 'session_fakes.dart';

class MainShellHarness {
  final session = SessionHarness();
  final transactions = FinancialTransactionsFake()..uid = 'A';

  Widget experience() => AuthExperience(
    createController: () => session.controller,
    transactions: transactions,
  );

  FinancialController financial(WidgetTester tester) => tester
      .widget<DashboardScreen>(
        find.byType(DashboardScreen, skipOffstage: false),
      )
      .controller;

  Future<void> mount(WidgetTester tester, {String? uid = 'A'}) async {
    session.users.profiles['A'] = userProfile('A', name: 'Ana (teste)');
    session.users.profiles['B'] = userProfile('B', name: 'Bruno (teste)');
    await tester.pumpWidget(BolsoZenApp(home: experience()));
    session.auth.events.add(uid == null ? null : authUser(uid));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.auth.events.close();
    });
  }
}

Future<void> shellTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

Future<void> shellAdd(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> shellFill(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('transaction-amount')),
    '120,50',
  );
  final category = find.byKey(const ValueKey('transaction-category-expense'));
  await tester.ensureVisible(category);
  await tester.tap(category);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Alimentação').last);
  await tester.pumpAndSettle();
  final description = find.byKey(const ValueKey('transaction-description'));
  await tester.ensureVisible(description);
  await tester.enterText(description, 'Almoço de teste');
}

Future<void> shellSave(WidgetTester tester, {bool settle = true}) async {
  final submit = find.byKey(const ValueKey('transaction-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
