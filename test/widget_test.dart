import 'package:bolsozen/app/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  testWidgets('Marca, tema e localização brasileira', (tester) async {
    await tester.pumpWidget(const BolsoZenApp());
    await tester.pumpAndSettle();
    expect(
      find.image(const AssetImage('assets/branding/bolsozen_logo.png')),
      findsOneWidget,
    );
    expect(find.text('BolsoZen'), findsNothing);
    expect(find.text('Suas finanças com mais tranquilidade'), findsNothing);
    final context = tester.element(find.byType(Scaffold));
    expect(Localizations.localeOf(context), const Locale('pt', 'BR'));
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Cancelar');
    expect(CupertinoLocalizations.of(context).selectAllButtonLabel, isNotEmpty);
    expect(Theme.of(context).useMaterial3, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Carrossel desliza pelas três ilustrações e atualiza os pontos', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const BolsoZenApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(PageView));
      for (var page = 0; page < 3; page++) {
        expect(
          find.bySemanticsLabel('Ilustração ${page + 1} de 3'),
          findsOneWidget,
        );
        expect(
          find
              .image(
                AssetImage('assets/illustrations/onboarding0${page + 1}.png'),
              )
              .hitTestable(),
          findsOneWidget,
        );
        for (var dot = 0; dot < 3; dot++) {
          expect(find.byKey(ValueKey('onboarding-dot-$dot')), findsOneWidget);
        }
        if (page < 2) {
          await tester.drag(find.byType(PageView), const Offset(-500, 0));
          await tester.pumpAndSettle();
        }
      }
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ilustração 2 de 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  for (final label in ['Entrar', 'Criar conta']) {
    testWidgets('$label informa etapa posterior sem navegar', (tester) async {
      await tester.pumpWidget(const BolsoZenApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.text('$label estará disponível em uma etapa posterior.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  }
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Layout $width dp, texto $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 640);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(const BolsoZenApp());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Criar conta'));
        await tester.tap(find.text('Criar conta'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  test('Intl preparado para BRL', () {
    final text = NumberFormat.currency(
      locale: 'pt_BR',
      name: 'BRL',
      symbol: r'R$',
    ).format(1234);
    expect(text.replaceAll('\u00a0', ' '), r'R$ 1.234,00');
  });
}
