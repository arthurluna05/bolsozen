import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/category.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../firebase/data_failure.dart';
import '../firebase/firebase_session.dart';
import '../mappers/firestore_mappers.dart';

final class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository(this.session);
  final FirebaseSession session;

  @override
  Future<List<FinancialTransaction>> fetchPage({
    FinancialTransaction? after,
    int limit = 100,
  }) => guardData(() async {
    final uid = session.uid;
    if (limit < 1 || limit > 100 || (after != null && after.userId != uid)) {
      throw ArgumentError('Página inválida');
    }
    Query<Map<String, dynamic>> query = session
        .user(uid)
        .collection('transactions')
        .orderBy('occurredAt', descending: true)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId)
        .limit(limit);
    if (after != null) {
      FirebaseSession.validateId(after.id);
      query = query.startAfter([
        Timestamp.fromDate(after.occurredAt),
        Timestamp.fromDate(after.createdAt),
        after.id,
      ]);
    }
    final snapshot = await query.get(const GetOptions(source: Source.server));
    session.verify(uid);
    return List.unmodifiable(
      snapshot.docs.map(
        (doc) => FirestoreMappers.transaction(doc.id, uid, doc.data()),
      ),
    );
  });

  @override
  Future<String> create({
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  }) => guardData(() async {
    final uid = session.uid;
    final ref = session.user(uid).collection('transactions').doc();
    final value = FinancialTransaction(
      id: ref.id,
      userId: uid,
      type: type,
      amountCents: amountCents,
      category: category,
      description: description,
      occurredAt: occurredAt,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    await session.firestore.runTransaction((tx) async {
      session.verify(uid);
      // Leitura garante semântica online e ausência de sobrescrita.
      final existing = await tx.get(ref);
      if (existing.exists) {
        throw const DataFailure(
          DataFailureKind.invalidData,
          'Identificador já existente.',
        );
      }
      session.verify(uid);
      tx.set(ref, {
        ...FirestoreMappers.transactionFields(value),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    session.verify(uid);
    return ref.id;
  });

  @override
  Future<void> update(FinancialTransaction transaction) => guardData(() async {
    final uid = session.uid;
    FirebaseSession.validateId(transaction.id);
    if (transaction.userId != uid) {
      throw const DataFailure(
        DataFailureKind.permissionDenied,
        'Registro de outro usuário.',
      );
    }
    final ref = session
        .user(uid)
        .collection('transactions')
        .doc(transaction.id);
    await session.firestore.runTransaction((tx) async {
      session.verify(uid);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw const DataFailure(
          DataFailureKind.notFound,
          'Registro não encontrado.',
        );
      }
      final stored = FirestoreMappers.transaction(
        ref.id,
        uid,
        snapshot.data()!,
      );
      if (stored.createdAt != transaction.createdAt) {
        throw ArgumentError('Criação imutável');
      }
      session.verify(uid);
      tx.update(ref, {
        ...FirestoreMappers.transactionFields(transaction),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    session.verify(uid);
  });

  @override
  Future<void> delete(String id) => guardData(() async {
    final uid = session.uid;
    FirebaseSession.validateId(id);
    final ref = session.user(uid).collection('transactions').doc(id);
    await session.firestore.runTransaction((tx) async {
      session.verify(uid);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) {
        throw const DataFailure(
          DataFailureKind.notFound,
          'Registro não encontrado.',
        );
      }
      FirestoreMappers.transaction(id, uid, snapshot.data()!);
      session.verify(uid);
      tx.delete(ref);
    });
    session.verify(uid);
  });
}
