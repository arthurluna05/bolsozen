import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../firebase/data_failure.dart';
import '../firebase/firebase_session.dart';
import '../mappers/firestore_mappers.dart';

final class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this.session);
  final FirebaseSession session;

  @override
  Future<UserProfile?> fetch() => guardData(() async {
    final uid = session.uid;
    final snapshot = await session
        .user(uid)
        .get(const GetOptions(source: Source.server));
    session.verify(uid);
    return snapshot.exists
        ? FirestoreMappers.profile(uid, snapshot.data()!)
        : null;
  });

  @override
  Future<void> ensureProfile({required String displayName}) =>
      guardData(() async {
        final uid = session.uid;
        final value = UserProfile(
          userId: uid,
          displayName: displayName,
          email: session.auth.currentUser?.email ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
        final ref = session.user(uid);
        await session.firestore.runTransaction((tx) async {
          session.verify(uid);
          final snapshot = await tx.get(ref);
          if (snapshot.exists) {
            FirestoreMappers.profile(uid, snapshot.data()!);
          } else {
            session.verify(uid);
            tx.set(ref, {
              'displayName': value.displayName,
              'email': value.email,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        });
        session.verify(uid);
      });
}
