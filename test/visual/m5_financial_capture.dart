// Execução opt-in, somente Flutter test renderer e fixtures locais.
// Não inicia Firebase, Chrome, Android ou a navegação normal do aplicativo.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/core/theme/app_spacing.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:bolsozen/presentation/screens/transactions/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/financial_test_fakes.dart';
import '../domain/fixtures.dart';
import 'visual_fonts.dart';

void main() {
  const enabled = bool.fromEnvironment('M5_VISUAL_CAPTURE');
  testWidgets(
    'Capturas reais do renderer Flutter com Roboto e fixtures identificadas',
    (tester) async {
      await tester.runAsync(loadFinancialVisualFonts);
      final h = FinancialTestHarness();
      await tester.runAsync(() => h.start(name: 'Ana (teste)'));
      h.repository.source = financialVisualTransactions(h.repository.uid)
          .map(
            (t) => t.copyWith(
              description: t.description.replaceFirst(' — teste visual', ''),
            ),
          )
          .toList();
      await h.controller.load();
      final manifest = <Map<String, Object>>[];
      final output = Directory('docs/evidencias/m5-3');
      final previousShadowSetting = debugDisableShadows;
      debugDisableShadows = false;
      try {
        for (final settings in [
          (360.0, 1.0, false, false),
          (390.0, 1.0, false, false),
          (412.0, 1.0, false, false),
          (360.0, 2.0, false, false),
          (360.0, 2.0, true, false),
          (390.0, 1.0, false, true),
        ]) {
          final (width, scale, largeValue, compositionFixture) = settings;
          if (largeValue) {
            h.repository.source = [
              transaction(
                userId: h.repository.uid,
                category: Category.salary,
                amount: Money.maxSafeCents,
                description: List.filled(10, 'Descrição').join(' '),
              ),
            ];
            await h.controller.refresh();
          }
          if (compositionFixture) {
            h.repository.source = financialVisualTransactions(h.repository.uid)
                .map(
                  (t) => t.copyWith(
                    occurredAt: DateTime(
                      2026,
                      11,
                      t.id == 'food' || t.id == 'transport' ? 5 : 4,
                    ),
                    description: t.description.replaceFirst(
                      ' — teste visual',
                      '',
                    ),
                  ),
                )
                .toList();
            await h.controller.refresh();
          }
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          for (final list in [false, true]) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            final key = GlobalKey();
            final name = list ? 'transacoes' : 'dashboard';
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
                            SizedBox(
                              height: AppSpacing.lg,
                              child: Center(
                                child: Text(
                                  'TESTE VISUAL — FIXTURE SEM NAVEGAÇÃO',
                                  textScaler: TextScaler.noScaling,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                            Expanded(
                              child: list
                                  ? TransactionsScreen(
                                      controller: h.controller,
                                      today: DateTime(2026, 11, 5),
                                    )
                                  : DashboardScreen(
                                      controller: h.controller,
                                      clock: () => DateTime(2026, 11, 18),
                                      profile: h.profile,
                                    ),
                            ),
                            ExcludeSemantics(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    for (final (label, icon) in [
                                      ('Início', Icons.home_outlined),
                                      (
                                        'Transações',
                                        Icons.receipt_long_outlined,
                                      ),
                                      ('Orçamento', Icons.pie_chart_outline),
                                      ('Relatórios', Icons.bar_chart),
                                      ('Perfil', Icons.person_outline),
                                    ])
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                label ==
                                                    (list
                                                        ? 'Transações'
                                                        : 'Início')
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.field,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.xs,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                label == 'Início' && !list
                                                    ? Icons.home
                                                    : label == 'Transações' &&
                                                          list
                                                    ? Icons.receipt_long
                                                    : icon,
                                                color:
                                                    label ==
                                                        (list
                                                            ? 'Transações'
                                                            : 'Início')
                                                    ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                size: 24,
                                              ),
                                              Text(
                                                label,
                                                textScaler:
                                                    TextScaler.noScaling,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
            expect(tester.takeException(), isNull);
            final file =
                '$name-${width.toInt()}-texto-${scale.toInt()}${largeValue ? '-valor-longo' : ''}${compositionFixture ? '-composicao' : ''}.png';
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await output.create(recursive: true);
              await File('${output.path}/$file')
                  .writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
            manifest.add({
              'file': file,
              'width': width,
              'height': 844,
              'textScale': scale,
              'largeValue': largeValue,
              'compositionFixture': compositionFixture,
              'reference': list ? 'TEL-06' : 'TEL-04',
            });
          }
        }
        await tester.runAsync(
          () => File('${output.path}/manifest.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'renderer': 'Flutter test engine, RepaintBoundary.toImage; não Chrome/Android',
              'fonts':
                  'Roboto regular/medium/bold e MaterialIcons do SDK local',
              'remoteFirebase': false,
              'fixtureOnly': true,
              'navigationBar': 'Somente desenho de teste, cinco destinos sem ações; não é navegação de produção.',
              'todayForGrouping': '2026-11-05',
              'dashboardCurrentMonthClock': '2026-11-18',
              'captures': manifest,
            }),
          ),
        );
      } finally {
        debugDisableShadows = previousShadowSetting;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(h.close);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
    skip: !enabled,
  );
}
