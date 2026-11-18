// Opt-in: gate e shell reais com contratos fake. Sem inicialização Firebase.
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
import 'visual_fonts.dart';

void main() {
  testWidgets('MainShell integrado: três abas reais e rota TEL-05', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final output = Directory('docs/evidencias/m5-5');
    final captures = <Map<String, Object>>[];
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale, tab) in [
        (390.0, 1.0, 'Início'),
        (390.0, 1.0, 'Transações'),
        (390.0, 1.0, 'Perfil'),
        (390.0, 1.0, 'Formulário'),
        (360.0, 1.0, 'Início'),
        (412.0, 1.0, 'Início'),
        (360.0, 2.0, 'Início'),
        (360.0, 2.0, 'Transações'),
      ]) {
        final h = MainShellHarness();
        h.transactions.source = financialVisualTransactions('A');
        h.session.users.profiles['A'] = userProfile('A', name: 'Ana (teste)');
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          BolsoZenApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: boundaryKey,
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
        if (tab == 'Formulário') {
          await shellAdd(tester);
          expect(find.byType(NavigationBar), findsNothing);
        } else {
          await shellTab(tester, tab);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(find.byType(NavigationDestination), findsNWidgets(3));
        }
        expect(h.transactions.reads, 1);
        expect(h.transactions.writes, isEmpty);
        expect(tester.takeException(), isNull);
        final addButton = find.byType(FloatingActionButton);
        if (tab == 'Início' || tab == 'Transações') {
          expect(addButton.hitTestable(), findsOneWidget);
        }
        final name = switch (tab) {
          'Início' => 'dashboard',
          'Transações' => 'transacoes',
          'Perfil' => 'perfil',
          _ => 'formulario',
        };
        final file = '$name-${width.toInt()}-texto-${scale.toInt()}.png';
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
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
          'initialReads': h.transactions.reads,
          'writes': 0,
          if (tab == 'Início' || tab == 'Transações')
            'addButtonBounds': tester.getRect(addButton).toString(),
        });
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.session.auth.events.close);
      }
      await tester.runAsync(
        () => File('${output.path}/manifest.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'renderer': 'Flutter test engine, RepaintBoundary.toImage; não Android/Chrome',
            'productionNavigation': true,
            'fixtureDataOnly': true,
            'remoteFirebase': false,
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
  }, skip: !const bool.fromEnvironment('M5_VISUAL_CAPTURE'));
}
