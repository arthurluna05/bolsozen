import 'package:bolsozen/data/firebase/auth_error_mapper.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final code in [
    'invalid-credential',
    'invalid-login-credentials',
    'wrong-password',
    'user-not-found',
  ]) {
    test('Login neutraliza $code', () {
      final value = mapAuthError(
        FirebaseAuthException(code: code, message: 'raw-sensitive'),
        operation: AuthOperation.login,
      )!;
      expect(value.kind, AuthFailureKind.invalidCredentials);
      expect(value.message, 'E-mail ou senha inválidos.');
      expect(value.toString(), isNot(contains('raw-sensitive')));
    });
  }
  test(
    'Cadastro existente tem orientação contextual; login não revela cadastro',
    () {
      final error = FirebaseAuthException(code: 'email-already-in-use');
      expect(
        mapAuthError(error, operation: AuthOperation.register)!.kind,
        AuthFailureKind.emailAlreadyInUse,
      );
      expect(
        mapAuthError(error, operation: AuthOperation.login)!.kind,
        AuthFailureKind.unknown,
      );
    },
  );
  for (final code in ['user-not-found', 'user-disabled']) {
    test(
      'Recuperação neutraliza condição de conta $code, sem silenciar outra operação',
      () {
        final error = FirebaseAuthException(code: code);
        expect(
          mapAuthError(error, operation: AuthOperation.passwordReset),
          isNull,
        );
        expect(
          mapAuthError(error, operation: AuthOperation.configuration),
          isNotNull,
        );
        expect(mapAuthError(error, operation: AuthOperation.logout), isNotNull);
      },
    );
  }
  const cases = {
    'weak-password': AuthFailureKind.weakPassword,
    'password-does-not-meet-requirements': AuthFailureKind.weakPassword,
    'invalid-email': AuthFailureKind.invalidEmail,
    'missing-email': AuthFailureKind.invalidEmail,
    'missing-password': AuthFailureKind.passwordRequired,
    'too-many-requests': AuthFailureKind.tooManyRequests,
    'quota-exceeded': AuthFailureKind.tooManyRequests,
    'network-request-failed': AuthFailureKind.network,
    'unavailable': AuthFailureKind.unavailable,
    'internal-error': AuthFailureKind.unavailable,
    'web-storage-unsupported': AuthFailureKind.unavailable,
    'unsupported-persistence-type': AuthFailureKind.unavailable,
    'user-disabled': AuthFailureKind.userDisabled,
    'user-token-expired': AuthFailureKind.unauthenticated,
    'invalid-user-token': AuthFailureKind.unauthenticated,
    'unauthenticated': AuthFailureKind.unauthenticated,
    'requires-recent-login': AuthFailureKind.unauthenticated,
    'operation-not-allowed': AuthFailureKind.operationNotAllowed,
    'app-not-authorized': AuthFailureKind.operationNotAllowed,
    'unauthorized-domain': AuthFailureKind.operationNotAllowed,
    'invalid-api-key': AuthFailureKind.operationNotAllowed,
    'unexpected': AuthFailureKind.unknown,
  };
  for (final entry in cases.entries) {
    test(
      'Código ${entry.key} vira ${entry.value.name}, sem detalhes do provedor',
      () {
        final error = FirebaseAuthException(
          code: entry.key,
          email: 'private@example.com',
          message: 'raw-sensitive',
        );
        final value = mapAuthError(error, operation: AuthOperation.login)!;
        expect(value.kind, entry.value);
        expect(value.message, isNot(contains('private@example.com')));
        expect(value.message, isNot(contains('raw-sensitive')));
      },
    );
  }
  test('Falhas operacionais na recuperação nunca viram sucesso', () {
    for (final code in [
      'network-request-failed',
      'too-many-requests',
      'unavailable',
      'invalid-api-key',
      'unexpected',
    ]) {
      expect(
        mapAuthError(
          FirebaseAuthException(code: code),
          operation: AuthOperation.passwordReset,
        ),
        isNotNull,
      );
    }
  });
  test('Preserva falha do domínio e sanitiza exceção desconhecida', () {
    const failure = AuthFailure(AuthFailureKind.invalidEmail);
    expect(
      identical(mapAuthError(failure, operation: AuthOperation.login), failure),
      isTrue,
    );
    expect(
      mapAuthError(
        StateError('raw-sensitive'),
        operation: AuthOperation.observe,
      )!.kind,
      AuthFailureKind.unknown,
    );
  });
}
