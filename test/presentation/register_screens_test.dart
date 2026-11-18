import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/presentation/screens/auth/register_screen.dart';
import 'package:bolsozen/presentation/screens/auth/login_screen.dart';
import 'package:bolsozen/presentation/screens/auth/complete_profile_screen.dart';
import 'package:bolsozen/presentation/screens/profile/profile_screen.dart';
import 'package:bolsozen/presentation/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_screens_test.dart' show mountAuth, tapVisible, openProfile;
import 'session_fakes.dart';

Finder field(String key) => find.byKey(ValueKey(key));
Finder passwordInput(String key) =>
    find.descendant(of: field(key), matching: find.byType(TextFormField));
Future<void> fillRegistration(
  WidgetTester tester, {
  String name = '  João Ávila  ',
  String email = 'a@example.test',
  String password = ' senha á ',
  String confirmation = ' senha á ',
}) async {
  await tester.enterText(field('register-name'), name);
  await tester.enterText(field('register-email'), email);
  await tester.enterText(passwordInput('register-password'), password);
  await tester.enterText(passwordInput('register-confirmation'), confirmation);
}

Future<void> openRegistration(WidgetTester tester, SessionHarness h) async {
  await mountAuth(tester, h);
  await tapVisible(tester, find.text('Criar conta'));
}

void successfulRegistration(SessionHarness h) {
  h.auth.registration = () async {
    h.auth.events.add(authUser('a'));
    return authUser('a');
  };
}

void main() {
  for (final invalid in [
    'empty',
    'name',
    'email',
    'password',
    'confirmation',
  ]) {
    testWidgets('Cadastro rejeita $invalid antes do provedor', (tester) async {
      final h = SessionHarness();
      await openRegistration(tester, h);
      if (invalid != 'empty') {
        await fillRegistration(
          tester,
          name: invalid == 'name' ? ' ' : 'João',
          email: invalid == 'email' ? 'invalido' : 'a@example.test',
          password: invalid == 'password' ? '1234567' : '12345678',
          confirmation: invalid == 'confirmation'
              ? '12345679'
              : invalid == 'password'
              ? '1234567'
              : '12345678',
        );
      }
      await tapVisible(tester, field('register-submit'));
      expect(h.auth.registrations, 0);
      expect(h.users.writes, isEmpty);
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('register-name')).controller!.text,
        invalid == 'empty'
            ? ''
            : invalid == 'name'
            ? ' '
            : 'João',
      );
      expect(
        find.text(switch (invalid) {
          'email' => const AuthFailure(AuthFailureKind.invalidEmail).message,
          'password' => const AuthFailure(AuthFailureKind.weakPassword).message,
          'confirmation' => const AuthFailure(
            AuthFailureKind.passwordMismatch,
          ).message,
          _ => const AuthFailure(AuthFailureKind.invalidName).message,
        }),
        findsOneWidget,
      );
    });
  }
  for (final kind in [
    AuthFailureKind.emailAlreadyInUse,
    AuthFailureKind.network,
  ]) {
    testWidgets('Cadastro traduz ${kind.name} e preserva campos', (
      tester,
    ) async {
      final h = SessionHarness();
      h.auth.registration = () async => throw AuthFailure(kind);
      await openRegistration(tester, h);
      await fillRegistration(tester);
      await tapVisible(tester, field('register-submit'));
      expect(find.text(AuthFailure(kind).message), findsOneWidget);
      expect(h.auth.registrations, 1);
      expect(h.users.writes, isEmpty);
      expect(
        tester
            .widget<TextFormField>(passwordInput('register-password'))
            .controller!
            .text,
        ' senha á ',
      );
    });
  }
  testWidgets(
    'Senha e confirmação têm visibilidade independente e autofill de senha nova',
    (tester) async {
      final h = SessionHarness();
      await openRegistration(tester, h);
      await fillRegistration(tester);
      await tapVisible(
        tester,
        find.descendant(
          of: field('register-password'),
          matching: find.byTooltip('Mostrar senha'),
        ),
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field('register-password'),
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isFalse,
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field('register-confirmation'),
                matching: find.byType(EditableText),
              ),
            )
            .obscureText,
        isTrue,
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: field('register-confirmation'),
                matching: find.byType(TextField),
              ),
            )
            .autofillHints,
        [AutofillHints.newPassword],
      );
    },
  );
  for (final eventFirst in [true, false]) {
    testWidgets(
      'Cadastro confirma perfil e identidade, evento primeiro $eventFirst',
      (tester) async {
        final h = SessionHarness();
        final account = Completer<AuthUser>();
        final write = Completer<void>();
        h.auth.registration = () => account.future;
        h.users.write = (uid, name) async {
          await write.future;
          h.users.profiles.putIfAbsent(uid, () => userProfile(uid, name: name));
        };
        await openRegistration(tester, h);
        await fillRegistration(tester);
        await tester.ensureVisible(field('register-submit'));
        await tester.tap(field('register-submit'));
        await tester.pump();
        if (eventFirst) {
          h.auth.events.add(authUser('a'));
          await tester.pump();
          expect(h.users.writes, isEmpty);
          account.complete(authUser('a'));
        } else {
          account.complete(authUser('a'));
          await tester.pump();
          expect(h.users.writes, isEmpty);
          h.auth.events.add(authUser('a'));
        }
        await tester.pump();
        expect(find.byType(ProfileScreen), findsNothing);
        expect(h.users.writes, [('a', 'João Ávila')]);
        write.complete();
        await tester.pumpAndSettle();
        await openProfile(tester);
        expect(find.text('João Ávila'), findsOneWidget);
        expect(find.text('a@example.test'), findsOneWidget);
        expect(h.auth.registrations, 1);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );
  }
  testWidgets('Cadastro bloqueia toque e submit de teclado duplicados', (
    tester,
  ) async {
    final h = SessionHarness();
    final account = Completer<AuthUser>();
    h.auth.registration = () => account.future;
    await openRegistration(tester, h);
    await fillRegistration(tester);
    final submitted = tester
        .widget<TextField>(
          find.descendant(
            of: field('register-confirmation'),
            matching: find.byType(TextField),
          ),
        )
        .onSubmitted!;
    await tester.ensureVisible(field('register-submit'));
    await tester.tap(field('register-submit'));
    submitted(' senha á ');
    await tester.pump();
    expect(h.auth.registrations, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: field('register-submit'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    account.completeError(const AuthFailure(AuthFailureKind.network));
    await tester.pumpAndSettle();
  });
  testWidgets('Conta criada com falha de perfil permite retry sem recadastro', (
    tester,
  ) async {
    final h = SessionHarness();
    successfulRegistration(h);
    h.users.write = (_, _) async => throw const DataFailure(
      DataFailureKind.unavailable,
      'Falha de rede no perfil.',
    );
    await openRegistration(tester, h);
    await fillRegistration(tester);
    await tapVisible(tester, field('register-submit'));
    expect(find.text('Tentar salvar perfil novamente'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    h.users.write = null;
    await tapVisible(tester, find.text('Tentar salvar perfil novamente'));
    await openProfile(tester);
    expect(find.text('João Ávila'), findsOneWidget);
    expect(h.auth.registrations, 1);
    expect(h.users.writes.length, 2);
  });
  testWidgets('Perfil existente é reutilizado sem alterar nome ou createdAt', (
    tester,
  ) async {
    final h = SessionHarness();
    final original = userProfile('a', name: 'Nome existente');
    successfulRegistration(h);
    await openRegistration(tester, h);
    h.users.profiles['a'] = original;
    await fillRegistration(tester);
    await tapVisible(tester, field('register-submit'));
    await openProfile(tester);
    expect(identical(h.users.profiles['a'], original), isTrue);
    expect(find.text('Nome existente'), findsOneWidget);
  });
  testWidgets(
    'Perfil ausente após restauração solicita só nome e permite concluir',
    (tester) async {
      final h = SessionHarness();
      await mountAuth(tester, h, uid: 'a');
      expect(find.byType(CompleteProfileScreen), findsOneWidget);
      expect(find.byType(PasswordField), findsNothing);
      expect(h.users.writes, isEmpty);
      final email = tester.widget<TextFormField>(field('complete-email-a'));
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: field('complete-email-a'),
                matching: find.byType(TextField),
              ),
            )
            .readOnly,
        isTrue,
      );
      expect(email.initialValue, 'a@example.test');
      await tapVisible(tester, field('complete-submit'));
      expect(h.users.writes, isEmpty);
      await tester.enterText(field('complete-name'), '  Érica  ');
      await tapVisible(tester, field('complete-submit'));
      await openProfile(tester);
      expect(find.text('Érica'), findsOneWidget);
      expect(h.auth.registrations, 0);
      expect(h.auth.logins, 0);
    },
  );
  testWidgets(
    'Gravação confirmada mas leitura falha: retry idempotente conserva perfil',
    (tester) async {
      final h = SessionHarness();
      await mountAuth(tester, h, uid: 'a');
      h.users.read = (_) async => throw const DataFailure(
        DataFailureKind.unavailable,
        'Falha de leitura.',
      );
      await tester.enterText(field('complete-name'), 'Nome salvo');
      await tapVisible(tester, field('complete-submit'));
      final original = h.users.profiles['a'];
      expect(original, isNotNull);
      expect(find.byType(ProfileScreen), findsNothing);
      h.users.read = null;
      await tapVisible(tester, find.text('Tentar salvar perfil novamente'));
      await openProfile(tester);
      expect(identical(h.users.profiles['a'], original), isTrue);
      expect(find.text('Nome salvo'), findsOneWidget);
      expect(h.auth.registrations, 0);
    },
  );
  for (final kind in [
    DataFailureKind.invalidData,
    DataFailureKind.permissionDenied,
  ]) {
    testWidgets(
      'Erro ${kind.name} nunca oferece formulário para sobrescrever',
      (tester) async {
        final h = SessionHarness();
        h.users.read = (_) async =>
            throw DataFailure(kind, 'Perfil não confirmado.');
        await mountAuth(tester, h, uid: 'a');
        expect(find.byType(CompleteProfileScreen), findsNothing);
        expect(find.text('Perfil não confirmado.'), findsOneWidget);
        expect(h.users.writes, isEmpty);
      },
    );
  }
  testWidgets(
    'Logout durante gravação impede resposta tardia de reabrir privado',
    (tester) async {
      final h = SessionHarness();
      final write = Completer<void>();
      h.users.write = (_, _) => write.future;
      await mountAuth(tester, h, uid: 'a');
      await tester.enterText(field('complete-name'), 'Nome A');
      await tester.ensureVisible(field('complete-submit'));
      await tester.tap(field('complete-submit'));
      await tester.pump();
      await tapVisible(tester, field('status-logout'));
      expect(find.byType(PageView), findsOneWidget);
      write.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsNothing);
      expect(h.users.reads, ['a']);
    },
  );
  testWidgets('Troca de UID descarta nome e resposta de conclusão anterior', (
    tester,
  ) async {
    final h = SessionHarness();
    final write = Completer<void>();
    h.users.write = (_, _) => write.future;
    await mountAuth(tester, h, uid: 'a');
    await tester.enterText(field('complete-name'), 'Nome A');
    await tester.ensureVisible(field('complete-submit'));
    await tester.tap(field('complete-submit'));
    await tester.pump();
    h.auth.events.add(authUser('b'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(field('complete-name')).controller!.text,
      isEmpty,
    );
    expect(find.text('a@example.test'), findsNothing);
    write.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsNothing);
    expect(h.users.writes, [('a', 'Nome A')]);
    expect(h.users.reads, ['a', 'b']);
  });
  testWidgets(
    'Alternar login e cadastro não empilha formulários; Voltar retorna à marca',
    (tester) async {
      final h = SessionHarness();
      await openRegistration(tester, h);
      for (var i = 0; i < 3; i++) {
        await tapVisible(tester, find.text('Já tenho conta'));
        expect(find.byType(LoginScreen), findsOneWidget);
        await tapVisible(tester, find.text('Criar conta'));
        expect(find.byType(RegisterScreen), findsOneWidget);
      }
      await tapVisible(tester, find.byTooltip('Voltar'));
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(h.auth.registrations, 0);
    },
  );
  for (final screen in ['register', 'complete']) {
    for (final width in [360.0, 390.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$screen responsivo $width texto $scale teclado aberto', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 640);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final h = SessionHarness();
          if (screen == 'register') {
            await openRegistration(tester, h);
          } else {
            await mountAuth(tester, h, uid: 'a');
          }
          await tester.showKeyboard(
            field(screen == 'register' ? 'register-name' : 'complete-name'),
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump();
          await tester.ensureVisible(field('$screen-submit'));
          await tester.pump();
          expect(field('$screen-submit').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
