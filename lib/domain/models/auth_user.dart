import '../services/auth_validation.dart';

/// Identidade autenticada mínima; o nome pertence ao UserProfile separado.
final class AuthUser {
  AuthUser({required this.uid, required String email})
    : email = AuthValidation.normalizeEmail(email) {
    if (uid.trim().isEmpty) {
      // ArgumentError sem o valor de entrada para evitar expor dados em logs.
      throw ArgumentError('UID obrigatório');
    }
    final failure = AuthValidation.email(this.email);
    if (failure != null) throw failure;
  }

  final String uid;
  final String email;
}
