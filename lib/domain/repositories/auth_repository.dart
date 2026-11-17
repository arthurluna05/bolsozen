import '../models/auth_user.dart';

/// Autenticação por e-mail/senha, independente do provedor de infraestrutura.
/// Implementações traduzem erros em AuthFailure; não persistem credenciais.
abstract interface class AuthRepository {
  /// Emite o estado inicial (inclusive null) e alterações posteriores da sessão.
  /// A identidade da sessão, não um indicador local, governa a navegação.
  Stream<AuthUser?> authStateChanges();

  /// E-mail normalizado; senha entregue integralmente ao provedor, sem trim.
  Future<AuthUser> signIn({required String email, required String password});

  /// Cria apenas a identidade autenticada. Perfil é responsabilidade separada.
  Future<AuthUser> signUp({required String email, required String password});

  /// Sucesso e conta inexistente devem ter a mesma confirmação pública.
  /// Falhas de rede/serviço devem continuar sendo reportadas como falhas.
  Future<void> sendPasswordReset({required String email});

  /// Só anuncia saída concluída depois da confirmação do provedor.
  Future<void> signOut();
}
