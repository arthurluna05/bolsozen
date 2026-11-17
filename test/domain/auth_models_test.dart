import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthUser preserva UID e normaliza e-mail sem incluir perfil/senha', () {
    final user = AuthUser(uid: 'UID-M4', email: '  JOÃO@EXAMPLE.COM  ');
    expect(user.uid, 'UID-M4');
    expect(user.email, 'joão@example.com');
  });

  test('AuthUser rejeita UID vazio e e-mail inválido sem divulgar entrada', () {
    expect(
      () => AuthUser(uid: '  ', email: 'ana@example.com'),
      throwsArgumentError,
    );
    expect(
      () => AuthUser(uid: '', email: 'ana@example.com'),
      throwsArgumentError,
    );
    expect(
      () => AuthUser(uid: 'uid', email: 'entrada-invalida'),
      throwsA(
        isA<AuthFailure>()
            .having((e) => e.kind, 'kind', AuthFailureKind.invalidEmail)
            .having(
              (e) => e.toString().contains('entrada-invalida'),
              'sem entrada',
              isFalse,
            ),
      ),
    );
  });

  test('Identidade e falha não possuem setters públicos', () {
    final user = AuthUser(uid: 'uid', email: 'ana@example.com');
    final dynamic reference = user;
    expect(() => reference.uid = 'outro', throwsNoSuchMethodError);
    expect(
      () => reference.email = 'outro@example.com',
      throwsNoSuchMethodError,
    );
    final dynamic failure = const AuthFailure(AuthFailureKind.network);
    expect(
      () => failure.kind = AuthFailureKind.unknown,
      throwsNoSuchMethodError,
    );
    expect(user.uid, 'uid');
    expect(user.email, 'ana@example.com');
  });

  test('Falhas tipadas possuem códigos estáveis e mensagens pt-BR seguras', () {
    expect(AuthFailureKind.values.map((k) => AuthFailure(k).code), [
      'invalidName',
      'invalidEmail',
      'passwordRequired',
      'weakPassword',
      'confirmationRequired',
      'passwordMismatch',
      'invalidCredentials',
      'emailAlreadyInUse',
      'network',
      'unavailable',
      'tooManyRequests',
      'userDisabled',
      'unauthenticated',
      'operationNotAllowed',
      'unknown',
    ]);
    for (final kind in AuthFailureKind.values) {
      final failure = AuthFailure(kind);
      expect(failure, isA<Exception>());
      expect(failure.message, isNotEmpty);
      expect(failure.toString(), failure.message);
      expect(failure.message, isNot(contains('FirebaseException')));
    }
    expect(
      const AuthFailure(AuthFailureKind.invalidCredentials).message,
      'E-mail ou senha inválidos.',
    );
    expect(
      const AuthFailure(AuthFailureKind.emailAlreadyInUse).message,
      contains('entrar ou recuperar'),
    );
    expect(
      AuthFailure.passwordResetConfirmation,
      'Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.',
    );
  });

  test('Contrato tem identidade e stream nulos para sessão ausente, sem SDK', () async {
    final AuthRepository repository = _ContractProbe();
    expect(await repository.authStateChanges().first, isNull);
    final Future<AuthUser> Function({
      required String email,
      required String password,
    })
    login = repository.signIn;
    final Future<AuthUser> Function({
      required String email,
      required String password,
    })
    register = repository.signUp;
    final Future<void> Function({required String email}) reset =
        repository.sendPasswordReset;
    final Future<void> Function() logout = repository.signOut;
    // Verifica as assinaturas e propagação de falha do contrato, não autentica.
    await expectLater(
      login(email: 'a@example.com', password: 'fixture'),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      register(email: 'a@example.com', password: 'fixture'),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      reset(email: 'a@example.com'),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(logout(), throwsA(isA<AuthFailure>()));
  });
}

/// Somente prova de contrato em teste, não implementação de autenticação.
final class _ContractProbe implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);
  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => throw const AuthFailure(AuthFailureKind.unavailable);
  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async => throw const AuthFailure(AuthFailureKind.unavailable);
  @override
  Future<void> sendPasswordReset({required String email}) async =>
      throw const AuthFailure(AuthFailureKind.unavailable);
  @override
  Future<void> signOut() async =>
      throw const AuthFailure(AuthFailureKind.unavailable);
}
