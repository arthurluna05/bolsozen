// Opt-in: apenas seleção/diálogo reais com fixtures. Nunca confirma exclusão.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/financial_test_fakes.dart';
import '../presentation/main_shell_harness.dart';
import '../presentation/session_fakes.dart';
import '../presentation/transaction_edit_screens_test.dart' show editMenu;
import '../presentation/transaction_delete_screens_test.dart' show deleteOpen;
import 'visual_fonts.dart';

void main() {
  testWidgets('M6.3 menu e confirmação sem escrita ou Firebase', (
    tester,
  ) async {
    await tester.runAsync(loadFinancialVisualFonts);
    final output = Directory('docs/evidencias/m6-3');
    final captures = <Map<String, Object>>[];
    final shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final (width, scale, menu, id, large) in [
        (390.0, 1.0, true, 'food', false),
        (390.0, 1.0, false, 'food', false),
        (360.0, 1.0, false, 'food', false),
        (412.0, 1.0, false, 'food', false),
        (360.0, 2.0, false, 'food', false),
        (390.0, 1.0, false, 'income', false),
        (390.0, 1.0, false, 'income', true),
        (360.0, 2.0, false, 'income', true),
      ]) {
        final h = MainShellHarness();
        h.transactions.source = financialVisualTransactions('A')
            .map(
              (t) => large && t.id == 'income'
                  ? t.copyWith(
                      amountCents: Money.maxSafeCents,
                      description: List.filled(10, 'Descrição').join(' '),
                    )
                  : t,
            )
            .toList();
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
        if (menu) {
          await editMenu(tester, id);
          expect(find.text('Editar').hitTestable(), findsOneWidget);
          expect(find.text('Excluir').hitTestable(), findsOneWidget);
        } else {
          await deleteOpen(tester, id);
          expect(
            find.byKey(const ValueKey('delete-confirm')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('delete-cancel')).hitTestable(),
            findsOneWidget,
          );
        }
        expect(h.transactions.deletes, isEmpty);
        expect(h.transactions.writes, isEmpty);
        expect(h.transactions.updates, isEmpty);
        expect(tester.takeException(), isNull);
        final name = menu
            ? 'acoes'
            : 'confirmar-${id == 'income' ? 'receita' : 'despesa'}';
        final file =
            '$name-${width.toInt()}-texto-${scale.toInt()}${large ? '-valor-extenso' : ''}.png';
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
          'extendedFixture': large,
          'deletes': 0,
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
            'reference': 'TEL-06/Design System e diálogo complementar Material',
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
  }, skip: !const bool.fromEnvironment('M6_DELETE_VISUAL_CAPTURE'));
}
