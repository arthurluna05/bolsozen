import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/core/theme/app_colors.dart';
import 'package:bolsozen/core/theme/financial_visual_tokens.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:bolsozen/presentation/screens/transactions/transactions_screen.dart';
import 'package:bolsozen/presentation/widgets/category_icon.dart';
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

  testWidgets(
    'Dashboard aberto atravessa mês/ano e retoma competência atual sem logout ou leitura',
    (tester) async {
      var now = DateTime(2026, 12, 31, 23, 59, 59);
      h.repository.source = [
        transaction(
          id: 'dec-income',
          userId: h.repository.uid,
          category: Category.salary,
          amount: 1000,
          date: DateTime(2026, 12, 31),
        ),
        transaction(
          id: 'dec-expense',
          userId: h.repository.uid,
          amount: 100,
          date: DateTime(2026, 12, 31),
        ),
        transaction(
          id: 'jan-income',
          userId: h.repository.uid,
          category: Category.salary,
          amount: 200,
          date: DateTime(2027, 1, 1),
        ),
        transaction(
          id: 'jan-expense',
          userId: h.repository.uid,
          amount: 50,
          date: DateTime(2027, 1, 1),
        ),
      ];
      await h.controller.load();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        BolsoZenApp(
          home: DashboardScreen(
            controller: h.controller,
            profile: h.profile,
            clock: () => now,
          ),
        ),
      );
      await tester.pump();
      expect(h.controller.month, FinancialMonth(2026, 12));
      expect(h.controller.summary!.totals.incomeCents, 1000);
      now = DateTime(2027, 1, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(h.controller.month, FinancialMonth(2027, 1));
      expect(h.controller.summary!.totals.incomeCents, 200);
      expect(h.controller.summary!.totals.expenseCents, 50);
      expect(h.controller.summary!.balanceCents, 1050);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime(2027, 2, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.controller.month, FinancialMonth(2027, 2));
      expect(h.controller.summary!.totals.incomeCents, 0);
      expect(h.repository.reads, 1);
      expect(h.session.auth.logins, 0);
      expect(find.byTooltip('Mês anterior'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Histórico: data 14 semibold textPrimary, título 16 e ícone 28 com pastel preservado',
    (tester) async {
      h.repository.source = financialVisualTransactions(h.repository.uid);
      await h.controller.load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BolsoZenApp(
          home: TransactionsScreen(
            controller: h.controller,
            today: DateTime(2026, 11, 5),
          ),
        ),
      );
      await tester.pump();
      final date = tester.widget<Text>(find.text('Hoje, 5 de nov. de 2026'));
      expect(date.style!.color, AppColors.textPrimary);
      expect(date.style!.fontSize, 14);
      expect(date.style!.fontWeight, FontWeight.w600);
      final title = tester.widget<Text>(find.text('Transporte — teste visual'));
      expect(title.style!.fontSize, 16);
      expect(title.style!.fontWeight, FontWeight.w600);
      final icon = tester
          .widgetList<CategoryIcon>(find.byType(CategoryIcon))
          .firstWhere((i) => i.category == Category.transport);
      expect(icon.size, 28);
      expect(icon.background, FinancialVisualTokens.transportSurface);
      expect(icon.foreground, FinancialVisualTokens.transport);
    },
  );
}
