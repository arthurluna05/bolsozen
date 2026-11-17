/// Códigos do domínio; não dependem dos códigos ou exceções do Firebase.
enum AuthFailureKind {
  invalidName,
  invalidEmail,
  passwordRequired,
  weakPassword,
  confirmationRequired,
  passwordMismatch,
  invalidCredentials,
  emailAlreadyInUse,
  network,
  unavailable,
  tooManyRequests,
  userDisabled,
  unauthenticated,
  operationNotAllowed,
  unknown,
}

/// Não recebe mensagens remotas, credenciais ou dados digitados pelo usuário.
final class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;
  String get code => kind.name;

  static const passwordResetConfirmation =
      'Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.';

  String get message => switch (kind) {
    AuthFailureKind.invalidName => 'Informe um nome com 2 a 80 caracteres e pelo menos dois caracteres não brancos.',
    AuthFailureKind.invalidEmail => 'Informe um e-mail válido.',
    AuthFailureKind.passwordRequired => 'Informe sua senha.',
    AuthFailureKind.weakPassword => 'Use uma senha com pelo menos 8 caracteres e que atenda à política exigida.',
    AuthFailureKind.confirmationRequired => 'Confirme sua senha.',
    AuthFailureKind.passwordMismatch => 'As senhas não coincidem.',
    AuthFailureKind.invalidCredentials => 'E-mail ou senha inválidos.',
    AuthFailureKind.emailAlreadyInUse => 'Não foi possível criar a conta com este e-mail. Tente entrar ou recuperar sua senha.',
    AuthFailureKind.network =>
      'Não foi possível conectar. Verifique sua conexão e tente novamente.',
    AuthFailureKind.unavailable =>
      'O serviço está indisponível. Tente novamente mais tarde.',
    AuthFailureKind.tooManyRequests =>
      'Muitas tentativas. Aguarde um pouco antes de tentar novamente.',
    AuthFailureKind.userDisabled =>
      'Não foi possível acessar sua conta. Tente entrar novamente.',
    AuthFailureKind.unauthenticated => 'Entre na sua conta para continuar.',
    AuthFailureKind.operationNotAllowed =>
      'Não foi possível concluir esta operação no serviço de autenticação.',
    AuthFailureKind.unknown =>
      'Não foi possível concluir a operação. Tente novamente.',
  };

  @override
  String toString() => message;
}
