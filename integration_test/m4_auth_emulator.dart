// Entry point de integração local: não importar main.dart/firebase_options.dart.
// Executado no Chrome pelo supervisor; não é tela nem fluxo do aplicativo.
import 'dart:convert';
import 'dart:math';

import 'package:bolsozen/app/app_dependencies.dart';
import 'package:bolsozen/domain/models/auth_failure.dart';
import 'package:bolsozen/domain/repositories/auth_repository.dart';
import 'package:bolsozen/presentation/controllers/session_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const _enabled = bool.fromEnvironment('M4_AUTH_EMULATOR');
const _project = 'demo-bolsozen';
int _checks = 0;

void _record(Map<String, Object?> fields) =>
    debugPrintSynchronously('M4_EMULATOR ${jsonEncode(fields)}');

void _check(bool condition, String name) {
  if (!condition) throw StateError('INTEGRATION_CHECK_FAILED');
  _checks++;
  _record({'check': name, 'passed': true});
}

Future<void> _waitPhase(SessionController session, SessionPhase phase) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (session.phase != phase) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('SESSION_PHASE_TIMEOUT');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> main() async {
  if (!_enabled) {
    _record({'disabled': true});
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp? app;
  FirebaseFirestore? firestore;
  AuthRepository? repository;
  SessionController? coordinatedSession;
  var success = false;
  String? failureCode;
  try {
    if (!kIsWeb ||
        const String.fromEnvironment('M4_EMULATOR_PROJECT') != _project ||
        const String.fromEnvironment('M4_AUTH_ENDPOINT') != '127.0.0.1:9099' ||
        const String.fromEnvironment('M4_FIRESTORE_ENDPOINT') !=
            '127.0.0.1:8080') {
      throw StateError('LOCAL_ENDPOINT_GUARD');
    }
    app = await Firebase.initializeApp(
      name: 'm4-local-auth',
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:web:m4local',
        messagingSenderId: '1234567890',
        projectId: _project,
        authDomain: 'localhost',
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    firestore = FirebaseFirestore.instanceFor(app: app);
    // Primeiras chamadas aos clientes: redirecionar AMBOS antes da composição.
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    firestore.settings = const Settings(persistenceEnabled: false);
    firestore.useFirestoreEmulator(
      '127.0.0.1',
      8080,
      automaticHostMapping: false,
    );
    _check(
      app.options.projectId == _project,
      'demo_project_and_local_endpoints_configured',
    );
    _record({
      'project': _project,
      'authEndpoint': '127.0.0.1:9099',
      'firestoreEndpoint': '127.0.0.1:8080',
      'productionConfigImported': false,
    });
    final dependencies = await AppDependencies.create(
      auth: auth,
      firestore: firestore,
    );
    repository = dependencies.auth;
    _check(
      await repository.authStateChanges().first == null,
      'initial_signed_out',
    );
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final email = 'm4-local-$suffix@example.test';
    final random = Random.secure();
    final password =
        ' M4a!${List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join()} ';
    final user = await repository.signUp(
      email: '  ${email.toUpperCase()}  ',
      password: password,
    );
    _check(
      user.uid.isNotEmpty && user.email == email,
      'signup_and_email_normalization',
    );
    _check(
      (await repository.authStateChanges().first)?.uid == user.uid,
      'auth_stream_signed_in',
    );
    await dependencies.users.ensureProfile(displayName: 'TESTE LOCAL M4');
    final profile = (await dependencies.users.fetch())!;
    _check(
      profile.userId == user.uid &&
          profile.email == email &&
          profile.displayName == 'TESTE LOCAL M4',
      'profile_repository_server_read',
    );
    await dependencies.users.ensureProfile(displayName: 'TESTE LOCAL M4');
    _check(
      (await dependencies.users.fetch())!.createdAt == profile.createdAt,
      'profile_idempotence',
    );
    try {
      await repository.signUp(email: email, password: password);
      throw StateError('DUPLICATE_ACCEPTED');
    } on AuthFailure catch (error) {
      _check(
        error.kind == AuthFailureKind.emailAlreadyInUse,
        'duplicate_signup_typed_failure',
      );
    }
    await repository.signOut();
    _check(
      await repository.authStateChanges().first == null,
      'logout_stream_signed_out',
    );
    final login = await repository.signIn(email: email, password: password);
    _check(login.uid == user.uid, 'login_same_uid_password_spaces_preserved');
    try {
      await repository.signIn(email: email, password: password.trim());
      throw StateError('MODIFIED_PASSWORD_ACCEPTED');
    } on AuthFailure catch (error) {
      _check(
        error.kind == AuthFailureKind.invalidCredentials,
        'incorrect_password_neutral_failure',
      );
    }
    // Ausente: não gera e-mail nem links/códigos de recuperação nos logs locais.
    await repository.sendPasswordReset(
      email: 'm4-missing-$suffix@example.test',
    );
    _check(
      AuthFailure.passwordResetConfirmation.startsWith('Se houver uma conta'),
      'missing_email_reset_neutral',
    );
    await repository.signOut();
    _check(
      await repository.authStateChanges().first == null,
      'final_logout_confirmed',
    );
    // M4.5: mesmo controller/composição/repositórios usados pelas telas reais.
    final session = dependencies.createSessionController();
    coordinatedSession = session;
    session.start();
    await _waitPhase(session, SessionPhase.public);
    await session.signUp(
      displayName: 'TESTE LOCAL CADASTRO',
      email: 'm45-register-$suffix@example.test',
      password: password,
      confirmation: password,
    );
    await _waitPhase(session, SessionPhase.ready);
    _check(
      session.isReady &&
          session.profile!.userId == session.user!.uid &&
          session.profile!.displayName == 'TESTE LOCAL CADASTRO',
      'controller_signup_identity_and_profile_confirmed',
    );
    final original = session.profile!;
    await dependencies.users.ensureProfile(
      displayName: 'NÃO SUBSTITUIR',
      expectedUserId: original.userId,
    );
    final preserved = (await dependencies.users.fetch(
      expectedUserId: original.userId,
    ))!;
    _check(
      preserved.displayName == original.displayName &&
          preserved.createdAt == original.createdAt,
      'idempotent_profile_preserves_name_and_created_at',
    );
    await session.signOut();
    await _waitPhase(session, SessionPhase.public);
    _check(
      session.user == null && session.profile == null,
      'controller_logout_clears_state',
    );
    final incomplete = await repository.signUp(
      email: 'm45-incomplete-$suffix@example.test',
      password: password,
    );
    await _waitPhase(session, SessionPhase.missingProfile);
    _check(
      session.user!.uid == incomplete.uid &&
          session.profile == null &&
          !session.isReady,
      'existing_auth_without_profile_is_missing',
    );
    await session.completeProfile(displayName: ' ');
    _check(
      session.authFailure?.kind == AuthFailureKind.invalidName &&
          session.phase == SessionPhase.missingProfile,
      'complete_profile_rejects_invalid_name',
    );
    await session.completeProfile(displayName: '  TESTE LOCAL CONCLUSÃO  ');
    await _waitPhase(session, SessionPhase.ready);
    final completed = (await dependencies.users.fetch(
      expectedUserId: incomplete.uid,
    ))!;
    _check(
      session.user!.uid == incomplete.uid &&
          completed.userId == incomplete.uid &&
          completed.displayName == 'TESTE LOCAL CONCLUSÃO',
      'complete_profile_server_confirmed_without_second_account',
    );
    await session.signOut();
    await _waitPhase(session, SessionPhase.public);
    _check(session.profile == null, 'completed_profile_logout_clears_state');
    success = true;
  } catch (error) {
    failureCode = error is AuthFailure
        ? error.code
        : error.runtimeType.toString();
  } finally {
    coordinatedSession?.dispose();
    try {
      if (repository != null) await repository.signOut();
      if (firestore != null) await firestore.terminate();
      if (app != null) await app.delete();
    } catch (_) {
      success = false;
      failureCode ??= 'local_cleanup_failed';
    }
    _record({
      'result': true,
      'success': success,
      'checksPassed': _checks,
      'failureCode': failureCode,
      'project': _project,
    });
  }
}
