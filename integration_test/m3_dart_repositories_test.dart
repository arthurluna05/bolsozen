// Execução remota aprovada em firebase/DART_ANDROID_TEST_PLAN.md.
import 'dart:convert';
import 'dart:math';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/data/firebase/firebase_session.dart';
import 'package:bolsozen/data/repositories/firestore_budget_repository.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/data/repositories/firestore_user_repository.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show debugPrintSynchronously, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _run = 'm3dart20261117c01';
const _email = 'bolsozen-$_run-c@example.com';
const _approved = bool.fromEnvironment('M3_DART_REMOTE_APPROVED');
const _monthKey = '2099-12_food';
int _checks = 0;

void _event(String event, [Map<String, Object?> fields = const {}]) {
  debugPrintSynchronously(jsonEncode({'run': _run, 'event': event, ...fields}));
}

void _passed(String check) {
  _checks++;
  _event('check_passed', {'check': check, 'count': _checks});
}

Future<void> _denied(String name, Future<void> Function() operation) async {
  try {
    await guardData(() async {
      try {
        await operation();
      } on FirebaseException catch (error) {
        expect(error.code, 'permission-denied');
        rethrow;
      }
    });
  } on DataFailure catch (error) {
    expect(error.kind, DataFailureKind.permissionDenied);
    _passed(name);
    return;
  }
  _event('SECURITY_FAILURE_STOP', {'operation': name});
  fail('Acesso não autorizado permitido; interromper execução.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'M3 Dart Android: repositórios reais',
    (tester) async {
      expect(const bool.fromEnvironment('M3_ALLOW_PROFILE_REMAINDER'), isTrue);
      expect(const bool.fromEnvironment('M3_INDEX_READY'), isTrue);
      expect(kIsWeb, isFalse);
      expect(defaultTargetPlatform, TargetPlatform.android);
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options.projectId, 'bolsozen-f2f35');
      expect(options.appId, '1:691532851056:android:de5076a8ee9cd05dc0d1b5');
      final apps = <FirebaseApp>[];
      final auths = <FirebaseAuth>[];
      final stores = <FirebaseFirestore>[];
      final ids = <String>{};
      final remaining = <String>{};
      String? uid;
      bool budgetTracked = false;
      bool success = false;
      try {
        for (final role in ['c', 'guest']) {
          final app = await Firebase.initializeApp(
            name: '$_run-$role',
            options: options,
          );
          apps.add(app);
          final auth = FirebaseAuth.instanceFor(app: app);
          final store = FirebaseFirestore.instanceFor(app: app);
          auths.add(auth);
          stores.add(store);
          store.settings = const Settings(persistenceEnabled: false);
          expect(
            auth.currentUser,
            isNull,
            reason: 'Não reutilizar sessão existente.',
          );
        }
        _passed('firebase_android_initialization');
        final auth = auths.first;
        final store = stores.first;
        final random = Random.secure();
        final password =
            'C!9a_${List.generate(40, (_) => random.nextInt(16).toRadixString(16)).join()}';
        _event('account_creation_start', {'email': _email});
        uid = (await auth.createUserWithEmailAndPassword(
          email: _email,
          password: password,
        )).user!.uid;
        _event('account_created', {'uid': uid, 'email': _email});
        await auth.signOut();
        expect(
          (await auth.signInWithEmailAndPassword(
            email: _email,
            password: password,
          )).user!.uid,
          uid,
        );
        expect(auths.last.currentUser, isNull);
        _passed('authentication_login_same_uid');
        final session = FirebaseSession(auth: auth, firestore: store);
        final users = FirestoreUserRepository(session);
        final transactions = FirestoreTransactionRepository(session);
        final budgets = FirestoreBudgetRepository(session);
        final root = 'users/$uid';
        expect(await users.fetch(), isNull);
        _event('profile_creation_start', {'path': root});
        await users.ensureProfile(displayName: 'TESTE M3 DART $_run');
        final profile = (await users.fetch())!;
        expect(profile.userId, uid);
        expect(profile.email, _email);
        expect(profile.displayName, 'TESTE M3 DART $_run');
        await users.ensureProfile(displayName: 'TESTE M3 DART $_run');
        expect((await users.fetch())!.createdAt, profile.createdAt);
        _passed('profile_repository_create_read_idempotence');
        for (var i = 1; i <= 3; i++) {
          final id = await transactions.create(
            type: TransactionType.income,
            amountCents: i * 101,
            category: Category.salary,
            description: 'TESTE_M3_DART $_run receita $i',
            occurredAt: DateTime(2099, 12, 10),
          );
          ids.add(id);
          _event('transaction_created', {'path': '$root/transactions/$id'});
        }
        final all = await transactions.fetchPage();
        expect(all.length, 3);
        for (final item in all) {
          expect(item.userId, uid);
          expect(item.type, TransactionType.income);
          expect(item.category, Category.salary);
          expect(item.occurredAt, DateTime(2099, 12, 10));
          expect(item.amountCents, (ids.toList().indexOf(item.id) + 1) * 101);
          expect(item.updatedAt.isBefore(item.createdAt), isFalse);
        }
        _passed('transactions_create_server_read_model_round_trip');
        final expected = [...all]
          ..sort((a, b) {
            final occurred = b.occurredAt.compareTo(a.occurredAt);
            if (occurred != 0) return occurred;
            final created = b.createdAt.compareTo(a.createdAt);
            return created != 0 ? created : a.id.compareTo(b.id);
          });
        final first = await transactions.fetchPage(limit: 2);
        final second = await transactions.fetchPage(
          after: first.last,
          limit: 2,
        );
        expect(first.length, 2);
        expect(second.length, 1);
        expect(
          [...first, ...second].map((t) => t.id).toList(),
          expected.map((t) => t.id).toList(),
        );
        expect(
          await transactions.fetchPage(after: second.last, limit: 2),
          isEmpty,
        );
        _passed('pagination_order_cursor_2_1_0');
        final original = all.singleWhere((t) => t.id == ids.first);
        await transactions.update(
          original.copyWith(
            amountCents: 111,
            description: 'TESTE_M3_DART $_run atualizada',
          ),
        );
        final updated = (await transactions.fetchPage()).singleWhere(
          (t) => t.id == original.id,
        );
        expect(updated.amountCents, 111);
        expect(updated.description, 'TESTE_M3_DART $_run atualizada');
        expect(updated.createdAt, original.createdAt);
        expect(updated.updatedAt.isBefore(original.updatedAt), isFalse);
        _passed('transaction_update_server_persistence_audit');
        final month = FinancialMonth(2099, 12);
        expect(await budgets.fetchMonth(month), isEmpty);
        budgetTracked = true;
        _event('budget_creation_start', {'path': '$root/budgets/$_monthKey'});
        await budgets.save(
          month: month,
          category: Category.food,
          limitCents: 1000,
        );
        final budget = (await budgets.fetchMonth(month)).single;
        expect(budget.limitCents, 1000);
        expect(budget.userId, uid);
        expect(budget.id, _monthKey);
        _passed('budget_create_read_model_round_trip');
        await budgets.save(
          month: month,
          category: Category.food,
          limitCents: 1200,
        );
        final changed = (await budgets.fetchMonth(month)).single;
        expect(changed.limitCents, 1200);
        expect(changed.createdAt, budget.createdAt);
        expect(changed.updatedAt.isBefore(budget.updatedAt), isFalse);
        _passed('budget_update_server_persistence_audit');
        final guest = stores.last;
        final primaryPath = '$root/transactions/${ids.first}';
        await _denied('guest_read_permission_denied', () async {
          await guest
              .doc(primaryPath)
              .get(const GetOptions(source: Source.server));
        });
        await _denied(
          'guest_update_permission_denied',
          () => guest.doc(primaryPath).update({
            'amountCents': 222,
            'updatedAt': FieldValue.serverTimestamp(),
          }),
        );
        final guestRepo = FirestoreTransactionRepository(
          FirebaseSession(auth: auths.last, firestore: guest),
        );
        await expectLater(
          guestRepo.fetchPage(),
          throwsA(
            isA<DataFailure>().having(
              (e) => e.kind,
              'kind',
              DataFailureKind.unauthenticated,
            ),
          ),
        );
        _passed('repository_unauthenticated_session_barrier');
        expect(
          (await transactions.fetchPage())
              .singleWhere((t) => t.id == ids.first)
              .amountCents,
          111,
        );
        _passed('integrity_after_denied_access');
        await budgets.remove(month: month, category: Category.food);
        expect(await budgets.fetchMonth(month), isEmpty);
        expect(
          (await store
                  .doc('$root/budgets/$_monthKey')
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
        budgetTracked = false;
        _passed('budget_repository_delete_server_absence');
        for (final id in ids.toList()) {
          await transactions.delete(id);
          expect(
            (await store
                    .doc('$root/transactions/$id')
                    .get(const GetOptions(source: Source.server)))
                .exists,
            isFalse,
          );
          ids.remove(id);
          _passed('transaction_repository_delete_server_absence');
        }
        expect(await transactions.fetchPage(), isEmpty);
        success = true;
      } finally {
        if (uid != null) {
          final session = FirebaseSession(
            auth: auths.first,
            firestore: stores.first,
          );
          final transactions = FirestoreTransactionRepository(session);
          for (final id in ids) {
            final path = 'users/$uid/transactions/$id';
            try {
              await transactions.delete(id);
              if ((await stores.first
                      .doc(path)
                      .get(const GetOptions(source: Source.server)))
                  .exists) {
                remaining.add(path);
              }
            } catch (_) {
              {
                remaining.add(path);
              }
            }
          }
          if (budgetTracked) {
            final path = 'users/$uid/budgets/$_monthKey';
            try {
              await FirestoreBudgetRepository(session).remove(
                month: FinancialMonth(2099, 12),
                category: Category.food,
              );
              if ((await stores.first
                      .doc(path)
                      .get(const GetOptions(source: Source.server)))
                  .exists) {
                remaining.add(path);
              }
            } catch (_) {
              {
                remaining.add(path);
              }
            }
          }
          _event('cleanup_report', {
            'uid': uid,
            'retainedProfilePath': 'users/$uid',
            'financialRemaining': remaining.toList(),
            'checksPassed': _checks,
            'success': success,
          });
          await auths.first.signOut();
        }
        for (final store in stores) {
          await store.terminate();
        }
        for (final app in apps) {
          await app.delete();
        }
      }
      expect(remaining, isEmpty);
    },
    skip: !_approved,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
