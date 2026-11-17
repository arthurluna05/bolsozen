import '../models/auth_failure.dart';

/// Validações síncronas, sem SDK, efeitos colaterais ou armazenamento de dados.
abstract final class AuthValidation {
  static String normalizeEmail(String input) => input.trim().toLowerCase();

  static AuthFailure? name(String input) {
    final value = input.trim();
    final useful = value.replaceAll(RegExp(r'\s', unicode: true), '');
    return value.runes.length > 80 || useful.runes.length < 2
        ? const AuthFailure(AuthFailureKind.invalidName)
        : null;
  }

  /// Formato básico compatível com o perfil existente, sem pretensão de RFC.
  static AuthFailure? email(String input) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizeEmail(input))
      ? null
      : const AuthFailure(AuthFailureKind.invalidEmail);

  /// Login aceita senhas antigas/curtas e preserva todos os espaços.
  static AuthFailure? loginPassword(String password) => password.isEmpty
      ? const AuthFailure(AuthFailureKind.passwordRequired)
      : null;

  /// Conta caracteres Unicode (runes), sem trim, corte ou transformação.
  static AuthFailure? registrationPassword(String password) => password.isEmpty
      ? const AuthFailure(AuthFailureKind.passwordRequired)
      : password.runes.length < 8
      ? const AuthFailure(AuthFailureKind.weakPassword)
      : null;

  static AuthFailure? passwordConfirmation(
    String password,
    String confirmation,
  ) => confirmation.isEmpty
      ? const AuthFailure(AuthFailureKind.confirmationRequired)
      : password != confirmation
      ? const AuthFailure(AuthFailureKind.passwordMismatch)
      : null;
}
