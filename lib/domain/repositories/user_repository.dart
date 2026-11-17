import '../models/user_profile.dart';

abstract interface class UserRepository {
  Future<UserProfile?> fetch();

  /// Idempotente: cria somente se ausente. UID/e-mail vêm da sessão.
  Future<void> ensureProfile({required String displayName});
}
