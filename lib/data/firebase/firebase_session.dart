import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_failure.dart';

/// Nunca recebe UID da apresentação: cada operação usa a sessão Firebase atual.
final class FirebaseSession {
  FirebaseSession({required this.auth, required this.firestore});
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  String get uid {
    final user = auth.currentUser;
    if (user == null) {
      throw const DataFailure(
        DataFailureKind.unauthenticated,
        'Entre na sua conta para continuar.',
      );
    }
    return user.uid;
  }

  void verify(String expected) {
    if (auth.currentUser?.uid != expected) {
      throw const DataFailure(
        DataFailureKind.sessionChanged,
        'Sua sessão mudou. Carregue os dados novamente.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>> user(String uid) =>
      firestore.collection('users').doc(uid);

  static void validateId(String id) {
    if (id.trim().isEmpty || id.contains('/') || id == '.' || id == '..') {
      throw ArgumentError('Identificador inválido');
    }
  }
}
