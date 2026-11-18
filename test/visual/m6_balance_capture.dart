// Opt-in, somente renderer Flutter e contratos fake; sem Firebase.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bolsozen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/balance_privacy_test.dart' show toggleBalance;
import '../presentation/financial_test_fakes.dart';
import '../presentation/main_shell_harness.dart';
import '../presentation/session_fakes.dart';
import 'visual_fonts.dart';

void main() {
  testWidgets('M6.5 saldo visível e oculto com fixtures identificadas', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale) in [
        (360.0, 1.0),
        (390.0, 1.0),
        (412.0, 1.0),
        (360.0, 2.0),
      ]) {
        final h = MainShellHarness();
        h.transactions.source = financialVisualTransactions('A');
        h.session.users.profiles['A'] = userProfile('A', name: 'Ana (teste)');
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        final key = GlobalKey();
        await tester.pumpWidget(
          BolsoZenApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: key,
                  child: Material(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 24,
                          child: Center(
                            child: Text(
                              'TESTE VISUAL — DADOS NÃO PERSISTIDOS',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        Expanded(child: h.experience()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        h.session.auth.events.add(authUser('A'));
        await tester.pumpAndSettle();
        for (final visible in [true, false]) {
          if (!visible) await toggleBalance(tester);
          // Mesmo enquadramento antes/depois, inclusive quando a máscara reduz
          // a altura do card em texto ampliado. Apenas rolagem da fixture.
          tester
              .state<ScrollableState>(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(h.transactions.reads, 1);
          expect(h.transactions.writes, isEmpty);
          expect(h.transactions.updates, isEmpty);
          expect(h.transactions.deletes, isEmpty);
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('docs/evidencias/m6-5').create(recursive: true);
            await File(
              'docs/evidencias/m6-5/saldo-${visible ? 'visivel' : 'oculto'}-${width.toInt()}-texto-${scale.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.session.auth.events.close);
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDisableShadows = shadows;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, skip: !const bool.fromEnvironment('M6_BALANCE_VISUAL_CAPTURE'));
}
