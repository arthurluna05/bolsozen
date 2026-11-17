import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../domain/models/auth_failure.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/auth_validation.dart';
import '../firebase/auth_error_mapper.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {this.isWeb = kIsWeb});

  final FirebaseAuth _auth;
  final bool isWeb;
  Future<void>? _initialization;

  /// Configura somente a persistência Web. Não inicializa outro FirebaseApp.
  /// Chamadas concorrentes compartilham o mesmo Future, inclusive em falha:
  /// retentar configuração exige nova composição explícita, sem retry oculto.
  Future<void> initialize() => _initialization ??= _configure();

  Future<void> _configure() async {
    try {
      if (isWeb) await _auth.setPersistence(Persistence.LOCAL);
    } catch (error) {
      throw mapAuthError(error, operation: AuthOperation.configuration)!;
    }
  }

  AuthUser _user(User? user) {
    if (user == null ||
        user.uid.trim().isEmpty ||
        user.email == null ||
        AuthValidation.email(user.email!) != null) {
      // Resultado inválido do provedor não é sessão pública nem sucesso.
      throw const AuthFailure(AuthFailureKind.unknown);
    }
    return AuthUser(uid: user.uid, email: user.email!);
  }

  Future<T> _run<T>(AuthOperation operation, Future<T> Function() call) async {
    try {
      await initialize();
      return await call();
    } catch (error) {
      throw mapAuthError(error, operation: operation)!;
    }
  }

  @override
  Stream<AuthUser?> authStateChanges() async* {
    await initialize();
    Stream<User?> changes;
    try {
      changes = _auth.authStateChanges();
    } catch (error) {
      throw mapAuthError(error, operation: AuthOperation.observe)!;
    }
    yield* changes.transform(
      StreamTransformer<User?, AuthUser?>.fromHandlers(
        handleData: (user, sink) {
          try {
            sink.add(user == null ? null : _user(user));
          } catch (error) {
            sink.addError(
              mapAuthError(error, operation: AuthOperation.observe)!,
            );
          }
        },
        handleError: (Object error, StackTrace stack, sink) {
          sink.addError(mapAuthError(error, operation: AuthOperation.observe)!);
        },
      ),
    );
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _run(AuthOperation.login, () async {
        final failure =
            AuthValidation.email(email) ??
            AuthValidation.loginPassword(password);
        if (failure != null) throw failure;
        final result = await _auth.signInWithEmailAndPassword(
          email: AuthValidation.normalizeEmail(email),
          password: password,
        );
        return _user(result.user);
      });

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      _run(AuthOperation.register, () async {
        final failure =
            AuthValidation.email(email) ??
            AuthValidation.registrationPassword(password);
        if (failure != null) throw failure;
        final result = await _auth.createUserWithEmailAndPassword(
          email: AuthValidation.normalizeEmail(email),
          password: password,
        );
        return _user(result.user);
      });

  @override
  Future<void> sendPasswordReset({required String email}) async {
    final failure = AuthValidation.email(email);
    if (failure != null) throw failure;
    // Falhas de configuração de idioma não são confundidas com envio neutro.
    await _run(
      AuthOperation.configuration,
      () => _auth.setLanguageCode('pt-BR'),
    );
    try {
      await _auth.sendPasswordResetEmail(
        email: AuthValidation.normalizeEmail(email),
      );
    } catch (error) {
      final mapped = mapAuthError(
        error,
        operation: AuthOperation.passwordReset,
      );
      if (mapped != null) throw mapped;
    }
  }

  @override
  Future<void> signOut() => _run(AuthOperation.logout, _auth.signOut);
}
