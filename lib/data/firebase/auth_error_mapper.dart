import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../../domain/models/auth_failure.dart';

enum AuthOperation {
  configuration,
  observe,
  login,
  register,
  passwordReset,
  logout,
}

/// null representa apenas a resposta pública neutra para condições de conta
/// (inexistente/desabilitada) durante recuperação, nunca falha operacional.
/// Nunca reutiliza mensagens remotas, e-mail, senha ou dados da exceção na UI.
AuthFailure? mapAuthError(Object error, {required AuthOperation operation}) {
  if (error is AuthFailure) return error;
  if (error is! FirebaseException) {
    return const AuthFailure(AuthFailureKind.unknown);
  }
  if (operation == AuthOperation.passwordReset &&
      (error.code == 'user-not-found' || error.code == 'user-disabled')) {
    return null;
  }
  return AuthFailure(switch (error.code) {
    'invalid-credential' ||
    'invalid-login-credentials' ||
    'wrong-password' ||
    'user-not-found' =>
      operation == AuthOperation.login
          ? AuthFailureKind.invalidCredentials
          : AuthFailureKind.unknown,
    'email-already-in-use' =>
      operation == AuthOperation.register
          ? AuthFailureKind.emailAlreadyInUse
          : AuthFailureKind.unknown,
    'weak-password' ||
    'password-does-not-meet-requirements' => AuthFailureKind.weakPassword,
    'invalid-email' || 'missing-email' => AuthFailureKind.invalidEmail,
    'missing-password' => AuthFailureKind.passwordRequired,
    'too-many-requests' || 'quota-exceeded' => AuthFailureKind.tooManyRequests,
    'network-request-failed' => AuthFailureKind.network,
    'unavailable' ||
    'internal-error' ||
    'web-storage-unsupported' ||
    'unsupported-persistence-type' => AuthFailureKind.unavailable,
    'user-disabled' => AuthFailureKind.userDisabled,
    'user-token-expired' ||
    'invalid-user-token' ||
    'unauthenticated' ||
    'requires-recent-login' => AuthFailureKind.unauthenticated,
    'operation-not-allowed' ||
    'app-not-authorized' ||
    'unauthorized-domain' ||
    'invalid-api-key' => AuthFailureKind.operationNotAllowed,
    _ => AuthFailureKind.unknown,
  });
}
