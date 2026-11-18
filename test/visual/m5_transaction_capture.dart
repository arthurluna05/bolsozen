// Captura opt-in TEL-05: SDK cliente Firebase nunca é inicializado.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/presentation/screens/transactions/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/financial_test_fakes.dart';
import 'visual_fonts.dart';

void main() {
  testWidgets('TEL-05 em renderer real, somente dados de teste identificados', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final h = FinancialTestHarness();
    await tester.runAsync(h.start);
    final output = Directory('docs/evidencias/m5-4');
    final manifest = <Map<String, Object>>[];
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale, keyboard, filled) in [
        (360.0, 1.0, 0.0, true),
        (390.0, 1.0, 0.0, true),
        (412.0, 1.0, 0.0, true),
        (360.0, 2.0, 0.0, true),
        (360.0, 1.0, 300.0, true),
        (390.0, 1.0, 0.0, false),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        final key = GlobalKey();
        await tester.pumpWidget(
          BolsoZenApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
                child: RepaintBoundary(
                  key: key,
                  child: Material(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Center(
                            child: Text(
                              'TESTE VISUAL — DADOS NÃO PERSISTIDOS',
                              textScaler: TextScaler.noScaling,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Navigator(
                            onGenerateInitialRoutes: (_, _) => [
                              MaterialPageRoute<void>(
                                builder: (_) => const Scaffold(
                                  body: Center(
                                    child: Text(
                                      'Origem técnica do teste visual',
                                    ),
                                  ),
                                ),
                              ),
                              MaterialPageRoute<void>(
                                builder: (_) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: TextScaler.linear(scale),
                                    viewInsets: EdgeInsets.only(
                                      bottom: keyboard,
                                    ),
                                  ),
                                  child: TransactionFormScreen(
                                    controller: h.controller,
                                    clock: () => DateTime(2026, 11, 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (filled) {
          await tester.enterText(
            find.byKey(const ValueKey('transaction-amount')),
            '120,50',
          );
          final category = find.byKey(
            const ValueKey('transaction-category-expense'),
          );
          await tester.ensureVisible(category);
          await tester.tap(category);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Alimentação').last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('transaction-description')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('transaction-description')),
            'Almoço no restaurante',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }
        if (keyboard > 0) {
          await tester.ensureVisible(
            find.byKey(const ValueKey('transaction-submit')),
          );
        } else {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 2000),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(h.repository.writes, isEmpty);
        final file =
            'nova-transacao-${width.toInt()}-texto-${scale.toInt()}-teclado-${keyboard.toInt()}${filled ? '' : '-vazio'}.png';
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await output.create(recursive: true);
          await File('${output.path}/$file')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        manifest.add({
          'file': file,
          'width': width,
          'height': 844,
          'textScale': scale,
          'simulatedKeyboardInset': keyboard,
          'filledFixture': filled,
        });
      }
      await tester.runAsync(
        () => File('${output.path}/manifest.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'renderer': 'Flutter test engine, RepaintBoundary.toImage; não Android/Chrome',
            'reference': 'TEL-05',
            'remoteFirebase': false,
            'fixtureOnly': true,
            'writes': h.repository.writes.length,
            'clock': '2026-11-18',
            'captures': manifest,
          }),
        ),
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(h.close);
      debugDisableShadows = shadows;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, skip: !const bool.fromEnvironment('M5_VISUAL_CAPTURE'));
}
