import 'dart:async';

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/firebase_startup.dart';
import 'package:bolsozen/app/session_gate.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';

// Todos os destinos técnicos abaixo pertencem exclusivamente aos testes.
Widget testGate(SessionHarness h, {VoidCallback? onPrivateDispose}) =>
    SessionGate(
      createController: () => h.controller,
      publicBuilder: (_, _) => const Text('TECH_PUBLIC'),
      loadingBuilder: (_, _) => const Text('TECH_LOADING'),
      missingProfileBuilder: (_, _) => const Text('TECH_MISSING'),
      errorBuilder: (_, _) => const Text('TECH_ERROR'),
      readyBuilder: (context, session, profile) => _PrivateProbe(
        onDispose: onPrivateDispose,
        child: Column(
          children: [
            Text('TECH_PRIVATE ${profile.userId}'),
            Text(session.isBusy ? 'BUSY' : 'IDLE'),
            GestureDetector(
              key: const ValueKey('detail'),
              onTap: () {
                unawaited(
                  Navigator.of(context).push<void>(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) =>
                          Text('TECH_DETAIL ${profile.userId}'),
                    ),
                  ),
                );
              },
              child: const Text('Abrir detalhe'),
            ),
          ],
        ),
      ),
    );

Future<void> mount(WidgetTester tester, SessionHarness h, Widget home) async {
  await tester.pumpWidget(BolsoZenApp(home: home));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await h.auth.events.close();
  });
}

Future<void> signIn(WidgetTester tester, SessionHarness h, String uid) async {
  h.users.profiles[uid] = userProfile(uid);
  h.auth.events.add(authUser(uid));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Gate aguarda primeiro evento antes de renderizar área pública', (
    tester,
  ) async {
    final h = SessionHarness();
    await mount(tester, h, testGate(h));
    expect(find.text('TECH_LOADING'), findsOneWidget);
    expect(find.text('TECH_PUBLIC'), findsNothing);
    h.auth.events.add(null);
    await tester.pumpAndSettle();
    expect(find.text('TECH_PUBLIC'), findsOneWidget);
    expect(find.textContaining('TECH_PRIVATE'), findsNothing);
  });
  testWidgets('Área privada somente depois do perfil confirmado', (
    tester,
  ) async {
    final h = SessionHarness();
    final profile = Completer<UserProfile?>();
    h.users.read = (_) => profile.future;
    await mount(tester, h, testGate(h));
    h.auth.events.add(authUser('a'));
    await tester.pumpAndSettle();
    expect(find.text('TECH_LOADING'), findsOneWidget);
    expect(find.textContaining('TECH_PRIVATE'), findsNothing);
    profile.complete(userProfile('a'));
    await tester.pumpAndSettle();
    expect(find.text('TECH_PRIVATE a'), findsOneWidget);
  });
  testWidgets('Perfil ausente é separado de pronto e pode ser completado', (
    tester,
  ) async {
    final h = SessionHarness();
    await mount(tester, h, testGate(h));
    h.auth.events.add(authUser('a'));
    await tester.pumpAndSettle();
    expect(find.text('TECH_MISSING'), findsOneWidget);
    expect(find.textContaining('TECH_PRIVATE'), findsNothing);
    await h.controller.completeProfile(displayName: 'Nome real');
    await tester.pumpAndSettle();
    expect(find.text('TECH_PRIVATE a'), findsOneWidget);
  });
  testWidgets('Perfil de outro UID só apresenta erro, nunca a árvore privada', (
    tester,
  ) async {
    final h = SessionHarness();
    h.users.profiles['a'] = userProfile('b');
    await mount(tester, h, testGate(h));
    h.auth.events.add(authUser('a'));
    await tester.pumpAndSettle();
    expect(find.text('TECH_ERROR'), findsOneWidget);
    expect(find.textContaining('TECH_PRIVATE'), findsNothing);
  });
  testWidgets('Logout destrói rotas privadas; Voltar não as restaura', (
    tester,
  ) async {
    final h = SessionHarness();
    var disposals = 0;
    await mount(tester, h, testGate(h, onPrivateDispose: () => disposals++));
    await signIn(tester, h, 'a');
    await tester.tap(find.byKey(const ValueKey('detail')));
    await tester.pumpAndSettle();
    expect(find.text('TECH_DETAIL a'), findsOneWidget);
    await h.controller.signOut();
    await tester.pumpAndSettle();
    expect(disposals, 1);
    expect(find.text('TECH_PUBLIC'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('TECH_DETAIL'), findsNothing);
    expect(find.textContaining('TECH_PRIVATE'), findsNothing);
  });
  testWidgets('Troca de UID destrói inclusive a pilha sobre o perfil antigo', (
    tester,
  ) async {
    final h = SessionHarness();
    var disposals = 0;
    await mount(tester, h, testGate(h, onPrivateDispose: () => disposals++));
    await signIn(tester, h, 'a');
    await tester.tap(find.byKey(const ValueKey('detail')));
    await tester.pumpAndSettle();
    await signIn(tester, h, 'b');
    expect(disposals, 1);
    expect(find.text('TECH_PRIVATE b'), findsOneWidget);
    expect(find.textContaining('TECH_DETAIL'), findsNothing);
    expect(find.text('TECH_PRIVATE a'), findsNothing);
  });
  testWidgets('Falha de logout mantém pilha válida; erro de sessão a destrói', (
    tester,
  ) async {
    final h = SessionHarness();
    await mount(tester, h, testGate(h));
    await signIn(tester, h, 'a');
    await tester.tap(find.byKey(const ValueKey('detail')));
    await tester.pumpAndSettle();
    h.auth.logout = () async =>
        throw const AuthFailure(AuthFailureKind.network);
    await h.controller.signOut();
    await tester.pumpAndSettle();
    expect(find.text('TECH_DETAIL a'), findsOneWidget);
    h.auth.events.addError(const AuthFailure(AuthFailureKind.unauthenticated));
    await tester.pumpAndSettle();
    expect(find.text('TECH_ERROR'), findsOneWidget);
    expect(find.textContaining('TECH_DETAIL'), findsNothing);
    // Cancelamento/reassinatura executados fora do relógio simulado do widget.
    await tester.runAsync(h.controller.retrySession);
    await tester.pumpAndSettle();
    expect(find.text('TECH_LOADING'), findsOneWidget);
    h.auth.events.add(null);
    await tester.pumpAndSettle();
    expect(find.text('TECH_PUBLIC'), findsOneWidget);
  });
  testWidgets(
    'Retorno e evento de login antes de perfil não liberam conteúdo',
    (tester) async {
      final h = SessionHarness();
      final login = Completer<AuthUser>();
      final profile = Completer<UserProfile?>();
      h.auth.login = () => login.future;
      h.users.read = (_) => profile.future;
      await mount(tester, h, testGate(h));
      h.auth.events.add(null);
      await tester.pumpAndSettle();
      final call = h.controller.signIn(
        email: 'a@example.test',
        password: 'fixture',
      );
      h.auth.events.add(authUser('a'));
      await tester.pumpAndSettle();
      expect(find.text('TECH_LOADING'), findsOneWidget);
      login.complete(authUser('a'));
      await tester.pumpAndSettle();
      expect(find.text('TECH_LOADING'), findsOneWidget);
      profile.complete(userProfile('a'));
      await call;
      await tester.pumpAndSettle();
      expect(find.text('TECH_PRIVATE a'), findsOneWidget);
    },
  );
  testWidgets('Bootstrap constrói gate somente após inicialização confirmada', (
    tester,
  ) async {
    final h = SessionHarness();
    final initialized = Completer<void>();
    var builds = 0;
    await mount(
      tester,
      h,
      FirebaseStartup(
        initialize: () => initialized.future,
        childBuilder: (_) {
          builds++;
          return testGate(h);
        },
      ),
    );
    expect(builds, 0);
    expect(h.auth.listens, 0);
    initialized.complete();
    await tester.pumpAndSettle();
    expect(builds, 1);
    expect(h.auth.listens, 1);
    expect(find.text('TECH_LOADING'), findsOneWidget);
  });
  testWidgets('Gate descarta controller e assinatura ao sair da árvore', (
    tester,
  ) async {
    final h = SessionHarness();
    await mount(tester, h, testGate(h));
    expect(h.auth.events.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(h.auth.events.hasListener, isFalse);
  });
  testWidgets('Rebuild do gate não duplica controller nem assinatura', (
    tester,
  ) async {
    final h = SessionHarness();
    await mount(tester, h, testGate(h));
    await tester.pumpWidget(BolsoZenApp(home: testGate(h)));
    expect(h.auth.listens, 1);
  });
}

class _PrivateProbe extends StatefulWidget {
  const _PrivateProbe({required this.child, this.onDispose});
  final Widget child;
  final VoidCallback? onDispose;
  @override
  State<_PrivateProbe> createState() => _PrivateProbeState();
}

class _PrivateProbeState extends State<_PrivateProbe> {
  @override
  Widget build(BuildContext context) => widget.child;
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }
}
