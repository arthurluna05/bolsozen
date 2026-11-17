import 'dart:async';

import 'package:bolsozen/data/repositories/firebase_auth_repository.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_fakes.dart';

Matcher failure(AuthFailureKind kind) =>
    isA<AuthFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  late AuthTestFirebase auth;
  late FirebaseAuthRepository repository;
  setUp(() {
    auth = AuthTestFirebase();
    repository = FirebaseAuthRepository(auth, isWeb: false);
  });

  test('Login retorna só AuthUser, normaliza e-mail e preserva senha curta/espaços', () async {
    final user = await repository.signIn(
      email: '  ANA@EXAMPLE.COM  ',
      password: ' a ',
    );
    expect(user, isA<AuthUser>());
    expect(user.uid, 'uid-m4');
    expect(user.email, 'ana@example.com');
    expect(auth.receivedEmail, 'ana@example.com');
    expect(auth.receivedPassword, ' a ');
    expect(auth.loginCalls, 1);
  });
  test('Cadastro preserva senha inteira inclusive espaços/Unicode', () async {
    const password = ' 🪷Abcdefgh  ';
    final user = await repository.signUp(
      email: ' ANA@EXAMPLE.COM ',
      password: password,
    );
    expect(user.email, 'ana@example.com');
    expect(auth.receivedEmail, 'ana@example.com');
    expect(auth.receivedPassword, password);
    expect(auth.registerCalls, 1);
  });
  test('Validação local bloqueia chamadas inválidas ao SDK', () async {
    await expectLater(
      repository.signIn(email: 'invalid', password: 'a'),
      throwsA(failure(AuthFailureKind.invalidEmail)),
    );
    await expectLater(
      repository.signIn(email: 'a@example.com', password: ''),
      throwsA(failure(AuthFailureKind.passwordRequired)),
    );
    await expectLater(
      repository.signUp(email: 'a@example.com', password: 'curta'),
      throwsA(failure(AuthFailureKind.weakPassword)),
    );
    await expectLater(
      repository.signUp(email: 'invalid', password: 'abcdefgh'),
      throwsA(failure(AuthFailureKind.invalidEmail)),
    );
    await expectLater(
      repository.sendPasswordReset(email: 'invalid'),
      throwsA(failure(AuthFailureKind.invalidEmail)),
    );
    expect(
      [
        auth.loginCalls,
        auth.registerCalls,
        auth.resetCalls,
        auth.languageCalls,
      ],
      [0, 0, 0, 0],
    );
  });
  test('Erros de login/cadastro são tipados e não provocam retry', () async {
    auth.loginError = FirebaseAuthException(
      code: 'wrong-password',
      message: 'raw-sensitive',
    );
    auth.registerError = FirebaseAuthException(code: 'email-already-in-use');
    await expectLater(
      repository.signIn(email: 'a@example.com', password: 'a'),
      throwsA(failure(AuthFailureKind.invalidCredentials)),
    );
    await expectLater(
      repository.signUp(email: 'a@example.com', password: 'abcdefgh'),
      throwsA(failure(AuthFailureKind.emailAlreadyInUse)),
    );
    expect(auth.loginCalls, 1);
    expect(auth.registerCalls, 1);
  });
  for (final kind in [
    'null-user',
    'null-email',
    'empty-email',
    'invalid-email',
    'empty-uid',
  ]) {
    test(
      'Resultado de credencial $kind nunca é sucesso nem objeto Firebase',
      () async {
        auth.resultUser = switch (kind) {
          'null-user' => null,
          'null-email' => AuthTestUser(email: null),
          'empty-email' => AuthTestUser(email: ''),
          'invalid-email' => AuthTestUser(email: 'invalid'),
          _ => AuthTestUser(uid: ''),
        };
        await expectLater(
          repository.signIn(email: 'a@example.com', password: 'a'),
          throwsA(failure(AuthFailureKind.unknown)),
        );
        await expectLater(
          repository.signUp(email: 'a@example.com', password: 'abcdefgh'),
          throwsA(failure(AuthFailureKind.unknown)),
        );
      },
    );
  }
  test('Stream distingue sessão ausente de usuário válido', () async {
    auth.changes = Stream.fromIterable([null, AuthTestUser(), null]);
    final users = await repository.authStateChanges().toList();
    expect(users.length, 3);
    expect(users.first, isNull);
    expect(users[1]!.email, 'ana@example.com');
    expect(users.last, isNull);
  });
  test(
    'Stream sanitiza erro/usuário inválido e continua recebendo eventos',
    () async {
      final controller = StreamController<User?>();
      auth.changes = controller.stream;
      final users = <AuthUser?>[];
      final errors = <Object>[];
      final subscription = repository.authStateChanges().listen(
        users.add,
        onError: errors.add,
      );
      await Future<void>.delayed(Duration.zero);
      controller.add(AuthTestUser(email: null));
      controller.addError(
        FirebaseAuthException(
          code: 'network-request-failed',
          message: 'raw-sensitive',
        ),
      );
      controller.add(AuthTestUser());
      await Future<void>.delayed(Duration.zero);
      expect(errors, [
        failure(AuthFailureKind.unknown),
        failure(AuthFailureKind.network),
      ]);
      expect(users.single!.uid, 'uid-m4');
      await subscription.cancel();
      expect(controller.hasListener, isFalse);
      await controller.close();
    },
  );
  test(
    'Falha síncrona ao observar sessão não expõe exceção Firebase',
    () async {
      auth.streamError = FirebaseAuthException(code: 'unavailable');
      await expectLater(
        repository.authStateChanges().first,
        throwsA(failure(AuthFailureKind.unavailable)),
      );
    },
  );
  test(
    'Recuperação configura pt-BR e e-mail normalizado antes do envio único',
    () async {
      await repository.sendPasswordReset(email: ' ANA@EXAMPLE.COM ');
      expect(auth.receivedLanguage, 'pt-BR');
      expect(auth.receivedEmail, 'ana@example.com');
      expect(auth.languageCalls, 1);
      expect(auth.resetCalls, 1);
    },
  );
  for (final code in ['user-not-found', 'user-disabled']) {
    test('Recuperação de $code conclui com a mesma resposta pública', () async {
      auth.resetError = FirebaseAuthException(code: code);
      await repository.sendPasswordReset(email: 'a@example.com');
      expect(auth.resetCalls, 1);
      expect(
        AuthFailure.passwordResetConfirmation,
        startsWith('Se houver uma conta'),
      );
    });
  }
  for (final operation in ['login', 'register', 'reset', 'logout']) {
    test(
      'Falha de rede em $operation não vira sucesso nem repetição',
      () async {
        final error = FirebaseAuthException(code: 'network-request-failed');
        auth.loginError = auth.registerError = auth.resetError =
            auth.logoutError = error;
        final call = switch (operation) {
          'login' => repository.signIn(email: 'a@example.com', password: 'a'),
          'register' => repository.signUp(
            email: 'a@example.com',
            password: 'abcdefgh',
          ),
          'reset' => repository.sendPasswordReset(email: 'a@example.com'),
          _ => repository.signOut(),
        };
        await expectLater(call, throwsA(failure(AuthFailureKind.network)));
        expect(
          auth.loginCalls +
              auth.registerCalls +
              auth.resetCalls +
              auth.logoutCalls,
          1,
        );
      },
    );
  }
  test(
    'Erro de idioma impede envio e não é mascarado pela neutralidade',
    () async {
      auth.languageError = FirebaseAuthException(code: 'user-not-found');
      await expectLater(
        repository.sendPasswordReset(email: 'a@example.com'),
        throwsA(failure(AuthFailureKind.unknown)),
      );
      expect(auth.resetCalls, 0);
    },
  );
  test('Logout aguarda confirmação real do provedor', () async {
    final completed = Completer<void>();
    auth.logoutWait = completed.future;
    var returned = false;
    final call = repository.signOut().then((_) => returned = true);
    await Future<void>.delayed(Duration.zero);
    expect(returned, isFalse);
    completed.complete();
    await call;
    expect(returned, isTrue);
    expect(auth.logoutCalls, 1);
  });
  test('Exceções desconhecidas de SDK não escapam ao domínio', () async {
    auth.loginError = StateError('raw-sensitive');
    await expectLater(
      repository.signIn(email: 'a@example.com', password: 'a'),
      throwsA(failure(AuthFailureKind.unknown)),
    );
  });
  test('Android não chama API de persistência exclusiva Web', () async {
    await repository.initialize();
    await repository.signOut();
    expect(auth.persistenceCalls, 0);
  });
  test('Web configura LOCAL uma vez e aguarda antes de autenticar', () async {
    final completed = Completer<void>();
    auth.persistenceWait = completed.future;
    final web = FirebaseAuthRepository(auth, isWeb: true);
    final setup = web.initialize();
    final login = web.signIn(email: 'a@example.com', password: 'a');
    await Future<void>.delayed(Duration.zero);
    expect(auth.persistenceCalls, 1);
    expect(auth.receivedPersistence, Persistence.LOCAL);
    expect(auth.loginCalls, 0);
    completed.complete();
    await setup;
    await login;
    await web.signOut();
    expect(auth.persistenceCalls, 1);
  });
  test(
    'Falha de persistência Web bloqueia SDK, sem fallback ou retry automático',
    () async {
      auth.persistenceError = FirebaseAuthException(
        code: 'web-storage-unsupported',
      );
      final web = FirebaseAuthRepository(auth, isWeb: true);
      await expectLater(
        web.initialize(),
        throwsA(failure(AuthFailureKind.unavailable)),
      );
      await expectLater(
        web.signIn(email: 'a@example.com', password: 'a'),
        throwsA(failure(AuthFailureKind.unavailable)),
      );
      await expectLater(
        web.authStateChanges().first,
        throwsA(failure(AuthFailureKind.unavailable)),
      );
      expect(auth.persistenceCalls, 1);
      expect(auth.loginCalls, 0);
    },
  );
}
