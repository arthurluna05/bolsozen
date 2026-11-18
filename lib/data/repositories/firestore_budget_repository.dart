import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/category.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/monthly_budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/services/money.dart';
import '../firebase/data_failure.dart';
import '../firebase/firebase_session.dart';
import '../mappers/firestore_mappers.dart';

final class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository(this.session);
  final FirebaseSession session;

  @override
  Future<List<MonthlyBudget>> fetchMonth(
    FinancialMonth month, {
    String? expectedUserId,
  }) => guardData(() async {
    final uid = session.uid;
    if (expectedUserId != null) session.verify(expectedUserId);
    final snapshot = await session
        .user(uid)
        .collection('budgets')
        .where('monthKey', isEqualTo: month.key)
        .get(const GetOptions(source: Source.server));
    session.verify(uid);
    return List.unmodifiable(
      snapshot.docs.map(
        (doc) => FirestoreMappers.budget(doc.id, uid, doc.data()),
      ),
    );
  });

  @override
  Future<void> save({
    required FinancialMonth month,
    required Category category,
    required int limitCents,
    String? expectedUserId,
  }) => guardData(() async {
    final uid = session.uid;
    if (expectedUserId != null) session.verify(expectedUserId);
    Money.requireSafeCents(limitCents);
    final value = MonthlyBudget(
      userId: uid,
      month: month,
      category: category,
      limitCents: limitCents,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    final ref = session.user(uid).collection('budgets').doc(value.id);
    await session.firestore.runTransaction((tx) async {
      session.verify(uid);
      final stored = await tx.get(ref);
      session.verify(uid);
      if (stored.exists) FirestoreMappers.budget(ref.id, uid, stored.data()!);
      session.verify(uid);
      if (stored.exists) {
        tx.update(ref, {
          'limitCents': limitCents,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.set(ref, {
          ...FirestoreMappers.budgetFields(value),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    session.verify(uid);
  });

  @override
  Future<void> remove({
    required FinancialMonth month,
    required Category category,
    String? expectedUserId,
  }) => guardData(() async {
    final uid = session.uid;
    if (expectedUserId != null) session.verify(expectedUserId);
    if (category.type != TransactionType.expense) {
      throw ArgumentError('Categoria inválida');
    }
    final ref = session
        .user(uid)
        .collection('budgets')
        .doc('${month.key}_${category.id}');
    await session.firestore.runTransaction((tx) async {
      session.verify(uid);
      final stored = await tx.get(ref);
      session.verify(uid);
      if (stored.exists) {
        FirestoreMappers.budget(ref.id, uid, stored.data()!);
        session.verify(uid);
        tx.delete(ref);
      }
    });
    session.verify(uid);
  });
}
