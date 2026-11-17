import '../models/user_profile.dart';

abstract interface class UserRepository {
  Future<UserProfile?> fetch({String? expectedUserId});

  /// Idempotente: cria somente se ausente. UID/e-mail vêm da sessão.
  /// expectedUserId é uma barreira de sessão, nunca escolhe o caminho dos dados.
  Future<void> ensureProfile({
    required String displayName,
    String? expectedUserId,
  });
}
