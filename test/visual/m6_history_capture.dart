// Captura opt-in: SDK cliente remoto nunca é inicializado.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolsozen/app/app.dart';

import '../presentation/main_shell_harness.dart';
import '../presentation/financial_test_fakes.dart';
import '../presentation/session_fakes.dart';
import '../presentation/history_filters_test.dart'
    show historyQuery, historyType, categoryOpen, categoryChoose, categoryApply;
import 'visual_fonts.dart';

void main() {
  testWidgets('M6.4 capturas reais do renderer com fixtures locais', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final oldShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale, mode) in [
        (360.0, 1.0, 'historico'),
        (390.0, 1.0, 'historico'),
        (412.0, 1.0, 'historico'),
        (360.0, 2.0, 'historico'),
        (390.0, 1.0, 'combinados'),
        (390.0, 1.0, 'modal'),
        (360.0, 2.0, 'modal'),
        (390.0, 1.0, 'sem-resultados'),
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
        await shellTab(tester, 'Transações');
        if (mode == 'combinados') {
          await historyType(tester, 'expense');
          await historyQuery(tester, 'alimentacao');
          await categoryOpen(tester);
          await categoryChoose(tester, 'Alimentação');
          await categoryApply(tester);
        } else if (mode == 'modal') {
          await categoryOpen(tester);
        } else if (mode == 'sem-resultados') {
          await historyQuery(tester, 'inexistente');
        }
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
          await Directory('docs/evidencias/m6-4').create(recursive: true);
          await File(
            'docs/evidencias/m6-4/$mode-${width.toInt()}-texto-${scale.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.session.auth.events.close);
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDisableShadows = oldShadows;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, skip: !const bool.fromEnvironment('M6_HISTORY_VISUAL_CAPTURE'));
}
