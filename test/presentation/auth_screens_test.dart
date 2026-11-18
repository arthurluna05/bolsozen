import 'dart:async';

import 'package:bolsozen/app/app.dart';
import 'package:bolsozen/app/auth_experience.dart';
import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:bolsozen/presentation/screens/auth/login_screen.dart';
import 'package:bolsozen/presentation/screens/auth/register_screen.dart';
import 'package:bolsozen/presentation/screens/auth/password_reset_screen.dart';
import 'package:bolsozen/presentation/screens/profile/profile_screen.dart';
import 'package:bolsozen/presentation/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';
import 'financial_test_fakes.dart';

Future<void> mountAuth(
  WidgetTester tester,
  SessionHarness h, {
  String? uid,
}) async {
  final transactions = FinancialTransactionsFake();
  void syncUid() => transactions.uid = h.controller.user?.uid ?? 'a';
  h.controller.addListener(syncUid);
  await tester.pumpWidget(
    BolsoZenApp(
      home: AuthExperience(
        createController: () => h.controller,
        transactions: transactions,
      ),
    ),
  );
  h.auth.events.add(uid == null ? null : authUser(uid));
  await tester.pumpAndSettle();
  // Estes casos históricos verificam o Perfil; a chegada no Início é coberta
  // pela suíte de integração MainShell, usando a mesma árvore de produção.
  if (uid != null && h.controller.isReady) await openProfile(tester);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await h.auth.events.close();
  });
}

Future<void> openProfile(WidgetTester tester) =>
    tapVisible(tester, find.widgetWithText(NavigationDestination, 'Perfil'));

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openLogin(WidgetTester tester) =>
    tapVisible(tester, find.text('Entrar'));
Future<void> fillLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('login-email')),
    'a@example.test',
  );
  await tester.enterText(
    find.descendant(
      of: find.byType(PasswordField),
      matching: find.byType(TextFormField),
    ),
    ' senha  ',
  );
}

void main() {
  testWidgets('Welcome abre login real e Voltar preserva marca/carrossel', (
    tester,
  ) async {
    final h = SessionHarness();
    await mountAuth(tester, h);
    await openLogin(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Entrar no BolsoZen'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login-email')))
          .controller!
          .text,
      isEmpty,
    );
    await tapVisible(tester, find.byTooltip('Voltar'));
    expect(find.byType(PageView), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/branding/bolsozen_logo.png')),
      findsOneWidget,
    );
  });
  testWidgets('Login vazio e e-mail inválido bloqueiam o provedor', (
    tester,
  ) async {
    final h = SessionHarness();
    await mountAuth(tester, h);
    await openLogin(tester);
    await tapVisible(tester, find.byKey(const ValueKey('login-submit')));
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'invalido',
    );
    await tapVisible(tester, find.byKey(const ValueKey('login-submit')));
    expect(h.auth.logins, 0);
  });
  testWidgets('Senha alterna visibilidade com rótulos acessíveis', (
    tester,
  ) async {
    final h = SessionHarness();
    await mountAuth(tester, h);
    await openLogin(tester);
    final editable = find.descendant(
      of: find.byType(PasswordField),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).obscureText, isTrue);
    await tapVisible(tester, find.byTooltip('Mostrar senha'));
    expect(tester.widget<EditableText>(editable).obscureText, isFalse);
    await tapVisible(tester, find.byTooltip('Ocultar senha'));
    expect(tester.widget<EditableText>(editable).obscureText, isTrue);
  });
  for (final kind in [
    AuthFailureKind.invalidCredentials,
    AuthFailureKind.userDisabled,
    AuthFailureKind.network,
  ]) {
    testWidgets(
      'Login falho ${kind.name} mantém formulário/valores e mensagem segura',
      (tester) async {
        final h = SessionHarness();
        h.auth.login = () async => throw AuthFailure(kind);
        await mountAuth(tester, h);
        await openLogin(tester);
        await fillLogin(tester);
        await tapVisible(tester, find.byKey(const ValueKey('login-submit')));
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('login-email')))
              .controller!
              .text,
          'a@example.test',
        );
        expect(
          tester
              .widget<PasswordField>(find.byType(PasswordField))
              .controller
              .text,
          ' senha  ',
        );
        final message = kind == AuthFailureKind.network
            ? const AuthFailure(AuthFailureKind.network).message
            : 'E-mail ou senha inválidos.';
        expect(find.text(message), findsOneWidget);
        expect(h.auth.logins, 1);
      },
    );
  }
  testWidgets(
    'Login impede toque/submit duplicado e só abre perfil confirmado',
    (tester) async {
      final h = SessionHarness();
      final login = Completer<AuthUser>();
      final profile = Completer<UserProfile?>();
      h.auth.login = () => login.future;
      h.users.read = (_) => profile.future;
      await mountAuth(tester, h);
      await openLogin(tester);
      await fillLogin(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(PasswordField),
              matching: find.byType(TextField),
            ),
          )
          .onSubmitted
          ?.call(' senha  ');
      expect(h.auth.logins, 1);
      h.auth.events.add(authUser('a'));
      login.complete(authUser('a'));
      await tester.pump();
      expect(find.byType(ProfileScreen), findsNothing);
      profile.complete(userProfile('a', name: 'Nome do Firestore'));
      await tester.pumpAndSettle();
      await openProfile(tester);
      expect(find.text('Nome do Firestore'), findsOneWidget);
      expect(find.text('a@example.test'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );
  testWidgets(
    'Login válido via gate permite Perfil e logout elimina rotas anteriores',
    (tester) async {
      final h = SessionHarness();
      h.users.profiles['a'] = userProfile('a', name: 'João Real');
      h.auth.login = () async {
        h.auth.events.add(authUser('a'));
        return authUser('a');
      };
      await mountAuth(tester, h);
      await openLogin(tester);
      await fillLogin(tester);
      await tapVisible(tester, find.byKey(const ValueKey('login-submit')));
      await openProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('João Real'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('logout-submit')));
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(PageView), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );
  for (final action in ['success', 'network']) {
    testWidgets(
      'Recuperação $action valida e-mail e apresenta resposta correta',
      (tester) async {
        final h = SessionHarness();
        h.auth.reset = () async {
          if (action == 'network') {
            throw const AuthFailure(AuthFailureKind.network);
          }
        };
        await mountAuth(tester, h);
        await openLogin(tester);
        await tapVisible(tester, find.text('Esqueci minha senha'));
        expect(find.byType(PasswordResetScreen), findsOneWidget);
        await tapVisible(tester, find.byKey(const ValueKey('reset-submit')));
        expect(h.auth.resets, 0);
        expect(find.text('Informe um e-mail válido.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('reset-email')),
          'teste@example.test',
        );
        await tapVisible(tester, find.byKey(const ValueKey('reset-submit')));
        expect(h.auth.resets, 1);
        expect(
          find.text(
            action == 'success'
                ? AuthFailure.passwordResetConfirmation
                : const AuthFailure(AuthFailureKind.network).message,
          ),
          findsOneWidget,
        );
        expect(h.users.reads, isEmpty);
        await tapVisible(tester, find.text('Voltar para entrar'));
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  }
  testWidgets('Recuperação bloqueia envios duplicados mesmo por teclado', (
    tester,
  ) async {
    final h = SessionHarness();
    final send = Completer<void>();
    h.auth.reset = () => send.future;
    await mountAuth(tester, h);
    await openLogin(tester);
    await tapVisible(tester, find.text('Esqueci minha senha'));
    await tester.enterText(
      find.byKey(const ValueKey('reset-email')),
      'teste@example.test',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('reset-submit')));
    await tester.tap(find.byKey(const ValueKey('reset-submit')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reset-submit')));
    tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const ValueKey('reset-email')),
            matching: find.byType(TextField),
          ),
        )
        .onSubmitted
        ?.call('teste@example.test');
    expect(h.auth.resets, 1);
    send.complete();
    await tester.pumpAndSettle();
    expect(find.text(AuthFailure.passwordResetConfirmation), findsOneWidget);
  });
  testWidgets(
    'Perfil ausente oferece completar sem criar dados automaticamente',
    (tester) async {
      final h = SessionHarness();
      await mountAuth(tester, h, uid: 'a');
      expect(find.text('Completar perfil'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(h.users.writes, isEmpty);
      await tapVisible(tester, find.byKey(const ValueKey('status-logout')));
      expect(find.byType(PageView), findsOneWidget);
    },
  );
  testWidgets(
    'Erro de perfil permite retry sem login; UID incompatível não vaza',
    (tester) async {
      final h = SessionHarness();
      h.users.profiles['a'] = userProfile('b');
      await mountAuth(tester, h, uid: 'a');
      expect(find.text('Não foi possível carregar sua conta'), findsOneWidget);
      expect(find.text('Nome b'), findsNothing);
      h.users.profiles['a'] = userProfile('a');
      await tapVisible(tester, find.text('Tentar novamente'));
      await openProfile(tester);
      expect(find.text('Nome a'), findsOneWidget);
      expect(h.auth.logins, 0);
    },
  );
  testWidgets(
    'Logout falho mantém perfil real e oferece tentar Sair novamente',
    (tester) async {
      final h = SessionHarness();
      h.users.profiles['a'] = userProfile('a');
      h.auth.logout = () async =>
          throw const AuthFailure(AuthFailureKind.network);
      await mountAuth(tester, h, uid: 'a');
      await tapVisible(tester, find.byKey(const ValueKey('logout-submit')));
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(
        find.text(const AuthFailure(AuthFailureKind.network).message),
        findsOneWidget,
      );
      h.auth.logout = null;
      await tapVisible(tester, find.byKey(const ValueKey('logout-submit')));
      expect(find.byType(PageView), findsOneWidget);
    },
  );
  for (final kind in [
    DataFailureKind.unavailable,
    DataFailureKind.permissionDenied,
  ]) {
    testWidgets(
      'Falha de perfil ${kind.name} mostra recuperação sem identidade privada',
      (tester) async {
        final h = SessionHarness();
        h.users.read = (_) async =>
            throw DataFailure(kind, 'Não foi possível confirmar seu perfil.');
        await mountAuth(tester, h, uid: 'a');
        expect(find.text('Tentar novamente'), findsOneWidget);
        expect(find.byType(ProfileScreen), findsNothing);
        expect(find.text('a@example.test'), findsNothing);
        expect(h.users.writes, isEmpty);
      },
    );
  }
  testWidgets('Troca de conta remove nome e e-mail anteriores na UI real', (
    tester,
  ) async {
    final h = SessionHarness();
    h.users.profiles['a'] = userProfile('a');
    h.users.profiles['b'] = userProfile('b');
    await mountAuth(tester, h, uid: 'a');
    h.auth.events.add(authUser('b'));
    await tester.pumpAndSettle();
    await openProfile(tester);
    expect(find.text('Nome b'), findsOneWidget);
    expect(find.text('b@example.test'), findsOneWidget);
    expect(find.text('Nome a'), findsNothing);
    expect(find.text('a@example.test'), findsNothing);
  });
  testWidgets('Criar conta abre cadastro real pela boas-vindas e pelo login', (
    tester,
  ) async {
    final h = SessionHarness();
    await mountAuth(tester, h);
    await tapVisible(tester, find.text('Criar conta'));
    expect(find.byType(RegisterScreen), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Voltar'));
    await openLogin(tester);
    await tapVisible(tester, find.text('Criar conta'));
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(h.auth.registrations, 0);
  });
  for (final screen in ['login', 'reset', 'profile']) {
    for (final width in [360.0, 390.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$screen responsivo $width dp texto $scale e teclado quando aplicável',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 640);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetViewInsets);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final h = SessionHarness();
            h.users.profiles['a'] = userProfile('a');
            await mountAuth(tester, h, uid: screen == 'profile' ? 'a' : null);
            if (screen != 'profile') {
              await openLogin(tester);
              if (screen == 'reset') {
                await tapVisible(tester, find.text('Esqueci minha senha'));
              }
              final key = screen == 'login' ? 'login-email' : 'reset-email';
              await tester.showKeyboard(find.byKey(ValueKey(key)));
              tester.view.viewInsets = const FakeViewPadding(bottom: 300);
              await tester.pump();
            }
            final key = screen == 'login'
                ? 'login-submit'
                : screen == 'reset'
                ? 'reset-submit'
                : 'logout-submit';
            await tester.ensureVisible(find.byKey(ValueKey(key)));
            await tester.pump();
            expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
