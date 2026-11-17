import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthTestApp extends Fake implements FirebaseApp {
  AuthTestApp({this.name = 'm4-test', String project = 'demo-bolsozen'})
    : options = FirebaseOptions(
        apiKey: 'local-only',
        appId: 'local-only',
        messagingSenderId: '123',
        projectId: project,
      );
  @override
  final String name;
  @override
  final FirebaseOptions options;
}

class AuthTestUser extends Fake implements User {
  AuthTestUser({this.uid = 'uid-m4', this.email = 'ANA@example.com'});
  @override
  final String uid;
  @override
  final String? email;
}

class AuthTestCredential extends Fake implements UserCredential {
  AuthTestCredential(this.user);
  @override
  final User? user;
}

class AuthTestFirestore extends Fake implements FirebaseFirestore {
  AuthTestFirestore(this.app);
  @override
  final FirebaseApp app;
}

/// Fake restrito às chamadas efetivamente usadas pelo adaptador; só em testes.
class AuthTestFirebase extends Fake implements FirebaseAuth {
  AuthTestFirebase() : app = AuthTestApp();
  @override
  final FirebaseApp app;
  User? resultUser = AuthTestUser();
  Object? loginError,
      registerError,
      resetError,
      logoutError,
      languageError,
      persistenceError,
      streamError;
  Future<void>? persistenceWait, logoutWait;
  Stream<User?>? changes;
  int loginCalls = 0,
      registerCalls = 0,
      resetCalls = 0,
      logoutCalls = 0,
      persistenceCalls = 0,
      languageCalls = 0;
  String? receivedEmail, receivedPassword, receivedLanguage;
  Persistence? receivedPersistence;

  @override
  Stream<User?> authStateChanges() {
    if (streamError != null) throw streamError!;
    return changes ?? Stream.value(resultUser);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    receivedEmail = email;
    receivedPassword = password;
    if (loginError != null) throw loginError!;
    return AuthTestCredential(resultUser);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registerCalls++;
    receivedEmail = email;
    receivedPassword = password;
    if (registerError != null) throw registerError!;
    return AuthTestCredential(resultUser);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetCalls++;
    receivedEmail = email;
    if (resetError != null) throw resetError!;
  }

  @override
  Future<void> signOut() async {
    logoutCalls++;
    if (logoutWait != null) await logoutWait;
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {
    languageCalls++;
    receivedLanguage = languageCode;
    if (languageError != null) throw languageError!;
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    persistenceCalls++;
    receivedPersistence = persistence;
    if (persistenceWait != null) await persistenceWait;
    if (persistenceError != null) throw persistenceError!;
  }
}
