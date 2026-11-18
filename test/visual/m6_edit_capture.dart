// Opt-in, gate/shell/formulário reais. Apenas fixtures, sem Firebase ou escritas.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bolsozen/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/financial_test_fakes.dart';
import '../presentation/main_shell_harness.dart';
import '../presentation/session_fakes.dart';
import '../presentation/transaction_edit_screens_test.dart'
    show editMenu, editOpen;
import 'visual_fonts.dart';

void main() {
  testWidgets('M6.2 TEL-05 edição e menu Material, dados somente locais', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final output = Directory('docs/evidencias/m6-2');
    final captures = <Map<String, Object>>[];
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale, menu, id, keyboard) in [
        (390.0, 1.0, true, 'food', 0.0),
        (390.0, 1.0, false, 'food', 0.0),
        (390.0, 1.0, false, 'income', 0.0),
        (360.0, 1.0, false, 'food', 0.0),
        (412.0, 1.0, false, 'food', 0.0),
        (360.0, 2.0, true, 'food', 0.0),
        (360.0, 2.0, false, 'food', 0.0),
        (360.0, 1.0, false, 'food', 300.0),
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
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
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
        if (menu) {
          await editMenu(tester, id);
          expect(find.text('Editar').hitTestable(), findsOneWidget);
          expect(find.text('Excluir'), findsOneWidget);
        } else {
          await editOpen(tester, id);
          if (keyboard > 0) {
            await tester.showKeyboard(
              find.byKey(const ValueKey('transaction-description')),
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('transaction-submit')),
            );
            await tester.pumpAndSettle();
          }
          expect(find.byType(NavigationBar), findsNothing);
        }
        expect(tester.takeException(), isNull);
        expect(h.transactions.updates, isEmpty);
        expect(h.transactions.writes, isEmpty);
        expect(h.transactions.reads, 1);
        final name = menu
            ? 'acoes'
            : id == 'income'
            ? 'editar-receita'
            : 'editar-despesa';
        final file =
            '$name-${width.toInt()}-texto-${scale.toInt()}-teclado-${keyboard.toInt()}.png';
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
        captures.add({
          'file': file,
          'width': width,
          'height': 844,
          'textScale': scale,
          'simulatedKeyboardInset': keyboard,
          'reads': 1,
          'writes': 0,
          'updates': 0,
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.session.auth.events.close);
      }
      await tester.runAsync(
        () => File('${output.path}/manifest.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'renderer': 'Flutter test engine, RepaintBoundary.toImage; não Android/Chrome',
            'reference':
                'TEL-05/TEL-06 e Design System; menu complementar Material',
            'remoteFirebase': false,
            'fixtureOnly': true,
            'captures': captures,
          }),
        ),
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDisableShadows = shadows;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }, skip: !const bool.fromEnvironment('M6_VISUAL_CAPTURE'));
}
