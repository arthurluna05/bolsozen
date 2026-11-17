import 'dart:async';

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/firebase_startup.dart';
import 'package:bolsozen/presentation/screens/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Carregamento, falha explícita e retry antes de liberar boas-vindas',
    (tester) async {
      var calls = 0;
      final first = Completer<void>();
      await tester.pumpWidget(
        BolsoZenApp(
          home: FirebaseStartup(
            initialize: () {
              calls++;
              return calls == 1 ? first.future : Future.value();
            },
            child: const WelcomeScreen(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      first.completeError(StateError('erro técnico privado'));
      await tester.pumpAndSettle();
      expect(find.text('Não foi possível iniciar o BolsoZen'), findsOneWidget);
      expect(find.textContaining('erro técnico privado'), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    },
  );
}
