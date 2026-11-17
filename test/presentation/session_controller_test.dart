import 'dart:async';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:bolsozen/presentation/controllers/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';

void main() {
  late SessionHarness h;
  setUp(() {
    h = SessionHarness();
    h.controller.start();
  });
  tearDown(() => h.close());

  Future<void> ready(String uid) async {
    h.users.profiles[uid] = userProfile(uid);
    h.auth.events.add(authUser(uid));
    await flushSession();
  }

  test('Espera primeiro evento e start é idempotente', () {
    h.controller.start();
    expect(h.auth.listens, 1);
    expect(h.controller.phase, SessionPhase.checking);
    expect(h.controller.isReady, isFalse);
    expect(h.users.reads, isEmpty);
  });
  test('Evento sem autenticação abre somente estado público', () {
    h.auth.events.add(null);
    expect(h.controller.phase, SessionPhase.public);
    expect(h.controller.profile, isNull);
    expect(h.users.reads, isEmpty);
  });
  test('Perfil real correspondente libera sessão', () async {
    await ready('a');
    expect(h.controller.phase, SessionPhase.ready);
    expect(h.controller.isReady, isTrue);
    expect(h.controller.profile!.userId, 'a');
    expect(h.users.reads, ['a']);
  });
  test('Perfil ausente não é erro nem perfil inventado', () async {
    h.auth.events.add(authUser('a'));
    await flushSession();
    expect(h.controller.phase, SessionPhase.missingProfile);
    expect(h.controller.profile, isNull);
    expect(h.users.writes, isEmpty);
  });
  for (final invalid in ['uid', 'email', 'format']) {
    test('Perfil inválido $invalid não abre área privada', () async {
      h.users.read = (_) async => switch (invalid) {
        'uid' => userProfile('b'),
        'email' => UserProfile(
          userId: 'a',
          displayName: 'Nome',
          email: 'outro@example.test',
          createdAt: DateTime(2026),
        ),
        _ => throw const FormatException('conteúdo inválido'),
      };
      h.auth.events.add(authUser('a'));
      await flushSession();
      expect(h.controller.phase, SessionPhase.profileError);
      expect(h.controller.profileFailure!.kind, DataFailureKind.invalidData);
      expect(h.controller.profile, isNull);
    });
  }
  for (final kind in [
    DataFailureKind.unavailable,
    DataFailureKind.permissionDenied,
    DataFailureKind.sessionChanged,
  ]) {
    test(
      'Falha de perfil ${kind.name} é recuperável sem dados privados',
      () async {
        h.users.read = (_) async => throw DataFailure(kind, 'Falha segura');
        h.auth.events.add(authUser('a'));
        await flushSession();
        expect(h.controller.phase, SessionPhase.profileError);
        expect(h.controller.profileFailure!.kind, kind);
        expect(h.controller.profile, isNull);
      },
    );
  }
  test(
    'Retry só recarrega perfil; cliques concorrentes não duplicam leitura',
    () async {
      h.users.read = (_) async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Rede');
      h.auth.events.add(authUser('a'));
      await flushSession();
      final result = Completer<UserProfile?>();
      h.users.read = (_) => result.future;
      final retry = h.controller.retryProfile();
      await h.controller.retryProfile();
      expect(h.users.reads, ['a', 'a']);
      expect(h.auth.logins + h.auth.registrations, 0);
      result.complete(userProfile('a'));
      await retry;
      expect(h.controller.isReady, isTrue);
    },
  );
  test(
    'Logout confirmado limpa identidade e perfil, sem exigir evento adicional',
    () async {
      await ready('a');
      final version = h.controller.navigationVersion;
      await h.controller.signOut();
      expect(h.controller.phase, SessionPhase.public);
      expect(h.controller.user, isNull);
      expect(h.controller.profile, isNull);
      expect(h.controller.navigationVersion, greaterThan(version));
    },
  );
  test(
    'Logout pendente aguarda confirmação e não permite envio duplicado',
    () async {
      await ready('a');
      final result = Completer<void>();
      h.auth.logout = () => result.future;
      final call = h.controller.signOut();
      await h.controller.signOut();
      expect(h.auth.logouts, 1);
      expect(h.controller.isBusy, isTrue);
      expect(h.controller.isReady, isTrue);
      result.complete();
      await call;
      expect(h.controller.phase, SessionPhase.public);
    },
  );
  test(
    'Falha de logout preserva sessão confirmada e expõe erro seguro',
    () async {
      await ready('a');
      h.auth.logout = () async =>
          throw const AuthFailure(AuthFailureKind.network);
      await h.controller.signOut();
      expect(h.controller.isReady, isTrue);
      expect(h.controller.profile!.userId, 'a');
      expect(h.controller.authFailure!.kind, AuthFailureKind.network);
      expect(h.users.reads, ['a']);
    },
  );
  test('Mudança de UID descarta resposta e erro antigos', () async {
    final old = Completer<UserProfile?>();
    h.users.read = (uid) =>
        uid == 'a' ? old.future : Future.value(userProfile('b'));
    h.auth.events.add(authUser('a'));
    h.auth.events.add(authUser('b'));
    await flushSession();
    old.completeError(
      const DataFailure(DataFailureKind.permissionDenied, 'Antigo'),
    );
    await flushSession();
    expect(h.controller.isReady, isTrue);
    expect(h.controller.user!.uid, 'b');
    expect(h.controller.profile!.userId, 'b');
    expect(h.controller.profileFailure, isNull);
  });
  test('Resposta de perfil após logout não reabre sessão', () async {
    final old = Completer<UserProfile?>();
    h.users.read = (_) => old.future;
    h.auth.events.add(authUser('a'));
    await h.controller.signOut();
    old.complete(userProfile('a'));
    await flushSession();
    expect(h.controller.phase, SessionPhase.public);
    expect(h.controller.profile, isNull);
  });
  test('A -> B -> A não reaproveita leitura da sessão A anterior', () async {
    final first = Completer<UserProfile?>();
    var aReads = 0;
    h.users.read = (uid) => uid == 'a' && aReads++ == 0
        ? first.future
        : Future.value(userProfile(uid));
    h.auth.events.add(authUser('a'));
    h.auth.events.add(authUser('b'));
    h.auth.events.add(authUser('a'));
    await flushSession();
    first.complete(userProfile('a', name: 'ANTIGO'));
    await flushSession();
    expect(h.controller.profile!.displayName, 'Nome a');
  });
  test(
    'Dispose cancela assinatura e impede notificação/aplicação tardia',
    () async {
      final old = Completer<UserProfile?>();
      h.users.read = (_) => old.future;
      h.auth.events.add(authUser('a'));
      var notifications = 0;
      h.controller.addListener(() => notifications++);
      h.disposeController();
      expect(h.auth.events.hasListener, isFalse);
      old.complete(userProfile('a'));
      await flushSession();
      expect(notifications, 0);
      expect(h.controller.profile, isNull);
    },
  );
  test('Evento repetido do mesmo UID não duplica fetch', () async {
    await ready('a');
    h.auth.events.add(authUser('a'));
    await flushSession();
    expect(h.users.reads, ['a']);
  });
  test(
    'Cadastro aguarda retorno SDK antes de usar nome do evento auth',
    () async {
      h.auth.events.add(null);
      final account = Completer<AuthUser>();
      h.auth.registration = () => account.future;
      final call = h.controller.signUp(
        displayName: '  Nome real  ',
        email: 'a@example.test',
        password: ' senha  ',
        confirmation: ' senha  ',
      );
      await h.controller.signUp(
        displayName: 'Outro',
        email: 'a@example.test',
        password: 'abcdefgh',
        confirmation: 'abcdefgh',
      );
      h.auth.events.add(authUser('a'));
      expect(h.controller.phase, SessionPhase.authenticating);
      expect(h.users.reads, isEmpty);
      expect(h.users.writes, isEmpty);
      account.complete(authUser('a'));
      await call;
      expect(h.auth.registrations, 1);
      expect(h.users.writes, [('a', 'Nome real')]);
      expect(h.controller.profile!.displayName, 'Nome real');
    },
  );
  test('Retorno SDK sem evento não comprova sessão nem cria perfil', () async {
    h.auth.events.add(null);
    h.auth.registration = () async => authUser('a');
    await h.controller.signUp(
      displayName: 'Nome',
      email: 'a@example.test',
      password: 'abcdefgh',
      confirmation: 'abcdefgh',
    );
    expect(h.controller.phase, SessionPhase.authenticating);
    expect(h.users.writes, isEmpty);
    h.auth.events.add(authUser('a'));
    await flushSession();
    expect(h.controller.isReady, isTrue);
    expect(h.users.writes.single.$1, 'a');
  });
  test('Conta B durante cadastro A nunca recebe o nome de A', () async {
    h.auth.events.add(null);
    final account = Completer<AuthUser>();
    h.auth.registration = () => account.future;
    final call = h.controller.signUp(
      displayName: 'Nome A',
      email: 'a@example.test',
      password: 'abcdefgh',
      confirmation: 'abcdefgh',
    );
    h.auth.events.add(authUser('a'));
    h.auth.events.add(authUser('b'));
    h.users.profiles['b'] = userProfile('b');
    account.complete(authUser('a'));
    await call;
    expect(h.users.writes, isEmpty);
    expect(h.controller.profile!.userId, 'b');
  });
  test(
    'Falha parcial permite retry idempotente de perfil sem recadastro',
    () async {
      h.auth.events.add(null);
      h.auth.registration = () async {
        h.auth.events.add(authUser('a'));
        return authUser('a');
      };
      h.users.write = (_, _) async =>
          throw const DataFailure(DataFailureKind.unavailable, 'Rede');
      await h.controller.signUp(
        displayName: 'Nome',
        email: 'a@example.test',
        password: 'abcdefgh',
        confirmation: 'abcdefgh',
      );
      expect(h.controller.phase, SessionPhase.profileError);
      h.users.write = null;
      await h.controller.retryProfile();
      expect(h.auth.registrations, 1);
      expect(h.users.writes, [('a', 'Nome'), ('a', 'Nome')]);
      expect(h.controller.isReady, isTrue);
    },
  );
  test(
    'Completar perfil valida nome e vincula escrita ao UID esperado',
    () async {
      h.auth.events.add(authUser('a'));
      await flushSession();
      await h.controller.completeProfile(displayName: ' ');
      expect(h.controller.authFailure!.kind, AuthFailureKind.invalidName);
      expect(h.users.writes, isEmpty);
      await h.controller.completeProfile(displayName: '  João  ');
      expect(h.users.writes, [('a', 'João')]);
      expect(h.controller.isReady, isTrue);
    },
  );
  test(
    'Não sobrescreve perfil malformado nem permite completar em estado de erro',
    () async {
      h.users.read = (_) async => throw const FormatException('Inválido');
      h.auth.events.add(authUser('a'));
      await flushSession();
      await h.controller.completeProfile(displayName: 'Nome');
      expect(h.users.writes, isEmpty);
      expect(h.controller.phase, SessionPhase.profileError);
    },
  );
  test(
    'Troca de UID durante escrita não aplica nem consulta perfil antigo',
    () async {
      h.auth.events.add(authUser('a'));
      await flushSession();
      final write = Completer<void>();
      h.users.write = (_, _) => write.future;
      final call = h.controller.completeProfile(displayName: 'Nome A');
      h.users.profiles['b'] = userProfile('b');
      h.auth.events.add(authUser('b'));
      await flushSession();
      write.complete();
      await call;
      expect(h.users.writes, [('a', 'Nome A')]);
      expect(h.users.reads, ['a', 'b']);
      expect(h.controller.profile!.userId, 'b');
    },
  );
  test(
    'Erro de auth limpa área privada e retry de sessão não duplica listeners',
    () async {
      await ready('a');
      h.auth.events.addError(const AuthFailure(AuthFailureKind.network));
      expect(h.controller.phase, SessionPhase.sessionError);
      expect(h.controller.profile, isNull);
      final retry = h.controller.retrySession();
      await h.controller.retrySession();
      await retry;
      expect(h.auth.listens, 2);
      expect(h.controller.phase, SessionPhase.checking);
      h.auth.events.add(null);
      expect(h.controller.phase, SessionPhase.public);
    },
  );
  test('Login falho libera envio novamente com erro tipado', () async {
    h.auth.events.add(null);
    h.auth.login = () async =>
        throw const AuthFailure(AuthFailureKind.invalidCredentials);
    await h.controller.signIn(email: 'a@example.test', password: 'x');
    expect(h.controller.phase, SessionPhase.public);
    expect(h.controller.authFailure!.kind, AuthFailureKind.invalidCredentials);
    expect(h.controller.isBusy, isFalse);
    expect(h.users.reads, isEmpty);
  });
  test(
    'Recuperação valida e-mail antes de enviar sem consultar perfil',
    () async {
      h.auth.events.add(null);
      expect(await h.controller.sendPasswordReset(email: 'inválido'), isFalse);
      expect(
        h.controller.passwordResetFailure!.kind,
        AuthFailureKind.invalidEmail,
      );
      expect(h.auth.resets, 0);
      expect(
        await h.controller.sendPasswordReset(email: 'a@example.test'),
        isTrue,
      );
      expect(h.users.reads, isEmpty);
    },
  );
  test(
    'Recuperação compartilha bloqueio entre rotas e impede login concorrente',
    () async {
      h.auth.events.add(null);
      final result = Completer<void>();
      h.auth.reset = () => result.future;
      final call = h.controller.sendPasswordReset(email: 'a@example.test');
      expect(
        await h.controller.sendPasswordReset(email: 'a@example.test'),
        isFalse,
      );
      await h.controller.signIn(email: 'a@example.test', password: 'fixture');
      expect(h.auth.resets, 1);
      expect(h.auth.logins, 0);
      result.complete();
      expect(await call, isTrue);
      expect(h.controller.isBusy, isFalse);
    },
  );
  test('Recuperação de rede falha sem sucesso falso e pode ser repetida explicitamente', () async {
    h.auth.events.add(null);
    h.auth.reset = () async => throw const AuthFailure(AuthFailureKind.network);
    expect(
      await h.controller.sendPasswordReset(email: 'a@example.test'),
      isFalse,
    );
    expect(h.controller.passwordResetFailure!.kind, AuthFailureKind.network);
    h.auth.reset = null;
    expect(
      await h.controller.sendPasswordReset(email: 'a@example.test'),
      isTrue,
    );
    expect(h.controller.passwordResetFailure, isNull);
    expect(h.auth.resets, 2);
  });
  test('Erro de recuperação antigo não é aplicado à nova sessão', () async {
    h.auth.events.add(null);
    final result = Completer<void>();
    h.auth.reset = () => result.future;
    final call = h.controller.sendPasswordReset(email: 'a@example.test');
    await ready('b');
    result.completeError(const AuthFailure(AuthFailureKind.network));
    expect(await call, isFalse);
    expect(h.controller.passwordResetFailure, isNull);
    expect(h.controller.profile!.userId, 'b');
  });
  test(
    'Dispose durante recuperação ignora conclusão e notificações tardias',
    () async {
      h.auth.events.add(null);
      final result = Completer<void>();
      h.auth.reset = () => result.future;
      final call = h.controller.sendPasswordReset(email: 'a@example.test');
      var notices = 0;
      h.controller.addListener(() => notices++);
      h.disposeController();
      result.complete();
      expect(await call, isFalse);
      expect(notices, 0);
    },
  );
  test('Conclusão de logout antigo não apaga perfil de nova conta', () async {
    await ready('a');
    final result = Completer<void>();
    h.auth.logout = () => result.future;
    final call = h.controller.signOut();
    await ready('b');
    result.complete();
    await call;
    expect(h.controller.user!.uid, 'b');
    expect(h.controller.profile!.userId, 'b');
  });
  test('Logout falho durante leitura não fica em loading eterno', () async {
    final old = Completer<UserProfile?>();
    h.users.read = (_) => old.future;
    h.auth.events.add(authUser('a'));
    h.auth.logout = () async =>
        throw const AuthFailure(AuthFailureKind.network);
    await h.controller.signOut();
    old.complete(userProfile('a'));
    await flushSession();
    expect(h.controller.phase, SessionPhase.profileError);
    expect(h.controller.profile, isNull);
    h.users.read = null;
    h.users.profiles['a'] = userProfile('a');
    await h.controller.retryProfile();
    expect(h.controller.isReady, isTrue);
  });
}
