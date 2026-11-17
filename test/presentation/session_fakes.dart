import 'dart:async';

import 'package:bolsozen/domain/models/auth_user.dart';
import 'package:bolsozen/domain/models/user_profile.dart';
import 'package:bolsozen/domain/repositories/auth_repository.dart';
import 'package:bolsozen/domain/repositories/user_repository.dart';
import 'package:bolsozen/presentation/controllers/session_controller.dart';

AuthUser authUser(String uid) => AuthUser(uid: uid, email: '$uid@example.test');
UserProfile userProfile(String uid, {String? name}) => UserProfile(
  userId: uid,
  displayName: name ?? 'Nome $uid',
  email: '$uid@example.test',
  createdAt: DateTime(2026),
);

class SessionAuthFake implements AuthRepository {
  final events = StreamController<AuthUser?>.broadcast(sync: true);
  int listens = 0, logins = 0, registrations = 0, logouts = 0;
  int resets = 0;
  Future<AuthUser> Function()? login, registration;
  Future<void> Function()? logout;
  Future<void> Function()? reset;

  @override
  Stream<AuthUser?> authStateChanges() {
    listens++;
    return events.stream;
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) {
    logins++;
    return login!();
  }

  @override
  Future<AuthUser> signUp({required String email, required String password}) {
    registrations++;
    return registration!();
  }

  @override
  Future<void> signOut() async {
    logouts++;
    await logout?.call();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    resets++;
    await reset?.call();
  }
}

class SessionUsersFake implements UserRepository {
  final profiles = <String, UserProfile>{};
  final reads = <String>[];
  final writes = <(String, String)>[];
  Future<UserProfile?> Function(String uid)? read;
  Future<void> Function(String uid, String name)? write;

  @override
  Future<UserProfile?> fetch({String? expectedUserId}) async {
    final uid = expectedUserId!;
    reads.add(uid);
    return read == null ? profiles[uid] : read!(uid);
  }

  @override
  Future<void> ensureProfile({
    required String displayName,
    String? expectedUserId,
  }) async {
    final uid = expectedUserId!;
    writes.add((uid, displayName));
    if (write != null) {
      await write!(uid, displayName);
    } else {
      profiles.putIfAbsent(uid, () => userProfile(uid, name: displayName));
    }
  }
}

Future<void> flushSession() => Future<void>.delayed(Duration.zero);

class SessionHarness {
  final auth = SessionAuthFake();
  final users = SessionUsersFake();
  late final controller = SessionController(auth: auth, users: users);
  bool disposed = false;
  void disposeController() {
    if (!disposed) {
      controller.dispose();
      disposed = true;
    }
  }

  Future<void> close() async {
    disposeController();
    await auth.events.close();
  }
}
