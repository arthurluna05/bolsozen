// Executar somente após aprovação explícita dos identificadores e da limpeza.
import 'dart:convert';
import 'dart:math';

import 'package:bolsozen/data/firebase/firebase_session.dart';
import 'package:bolsozen/data/mappers/firestore_mappers.dart';
import 'package:bolsozen/data/repositories/firestore_budget_repository.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/data/repositories/firestore_user_repository.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/financial_transaction.dart';
import 'package:bolsozen/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _approved = bool.fromEnvironment('M3_REMOTE_APPROVED');
const _allowProfileRemainder = bool.fromEnvironment(
  'M3_ALLOW_PROFILE_REMAINDER',
);
const _indexReady = bool.fromEnvironment('M3_INDEX_READY');
const _run = 'm3r20261117a01';
const _project = 'bolsozen-f2f35';

void _record(String event, [Map<String, Object?> fields = const {}]) {
  // Somente evidências: sem UserCredential, senha, token ou erro bruto.
  debugPrint(jsonEncode({'m3run': _run, 'event': event, ...fields}));
}

String _password() {
  final random = Random.secure();
  return 'M3!aA9_${List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join()}';
}

Future<void> _permissionDenied(
  String operation,
  Future<void> Function() attempt,
) async {
  try {
    await attempt();
  } on FirebaseException catch (error) {
    // Rede/timeout/failed-precondition não servem como prova de isolamento.
    expect(error.code, 'permission-denied', reason: operation);
    _record('permission_denied', {'operation': operation});
    return;
  }
  fail('Operação indevida foi permitida: $operation');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'M3 remoto: cliente real, repositórios e isolamento',
    (tester) async {
      expect(
        _allowProfileRemainder,
        isTrue,
        reason: 'A regra atual impede apagar perfil; aprovar remanescente/limpeza manual antes de executar.',
      );
      expect(
        kIsWeb,
        isFalse,
        reason: 'Rotina preparada exclusivamente para Android.',
      );
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options.projectId, _project);
      expect(options.appId, '1:691532851056:android:de5076a8ee9cd05dc0d1b5');
      final apps = <FirebaseApp>[];
      final auths = <FirebaseAuth>[];
      final stores = <FirebaseFirestore>[];
      final documents = <String>{};
      final remaining = <String>{};
      final accounts = <String, String>{};
      String? uidA;
      bool profileMayExist = false;
      bool successful = false;
      try {
        for (final role in ['a', 'b', 'guest']) {
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
          // Não usar, deslogar ou reutilizar conta pessoal/preexistente.
          expect(
            auth.currentUser,
            isNull,
            reason: 'Sessão nomeada já existente; abortar sem reutilizar.',
          );
        }
        final authA = auths[0];
        final authB = auths[1];
        final storeA = stores[0];
        final sessionA = FirebaseSession(auth: authA, firestore: storeA);
        final transactions = FirestoreTransactionRepository(sessionA);
        final budgets = FirestoreBudgetRepository(sessionA);
        final users = FirestoreUserRepository(sessionA);

        // PRIMEIRAS MUTAÇÕES REMOTAS: nunca executar sem M3_REMOTE_APPROVED.
        for (var index = 0; index < 2; index++) {
          final role = index == 0 ? 'a' : 'b';
          final email = 'bolsozen-$_run-$role@example.com';
          final password = _password();
          final credential = await auths[index].createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = credential.user!.uid;
          accounts[role] = uid;
          if (index == 0) uidA = uid;
          _record('account_created', {
            'role': role,
            'uid': uid,
            'email': email,
          });
          await auths[index].signOut();
          final login = await auths[index].signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          expect(login.user!.uid, uid);
          expect(auths[index].currentUser!.uid, uid);
          _record('login_verified', {'role': role, 'uid': uid});
        }
        expect(accounts['a'], isNot(accounts['b']));
        expect(authA.currentUser!.uid, accounts['a']);
        expect(authB.currentUser!.uid, accounts['b']);
        expect(auths[2].currentUser, isNull);

        final root = 'users/$uidA';
        expect(
          (await storeA.doc(root).get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
        profileMayExist = true;
        await users.ensureProfile(displayName: 'TESTE M3 A $_run');
        expect((await users.fetch())!.userId, uidA);
        _record('profile_created', {'path': root});

        final transactionIds = <String>[];
        for (var index = 0; index < 3; index++) {
          final id = await transactions.create(
            type: TransactionType.income,
            amountCents: (index + 1) * 101,
            category: Category.salary,
            description: 'TESTE_M3 $_run receita ${index + 1}',
            occurredAt: DateTime(2099, 12, 10),
          );
          transactionIds.add(id);
          documents.add('$root/transactions/$id');
          _record('transaction_created', {'path': '$root/transactions/$id'});
        }
        final primary = '$root/transactions/${transactionIds.first}';
        Future<FinancialTransaction> readPrimary() async {
          if (_indexReady) {
            final page = await transactions.fetchPage();
            return page.singleWhere((item) => item.id == transactionIds.first);
          }
          final doc = await storeA
              .doc(primary)
              .get(const GetOptions(source: Source.server));
          return FirestoreMappers.transaction(doc.id, uidA!, doc.data()!);
        }

        final original = await readPrimary();
        expect(original.amountCents, 101);
        await transactions.update(
          original.copyWith(
            amountCents: 111,
            description: 'TESTE_M3 $_run receita atualizada',
          ),
        );
        final updated = await readPrimary();
        expect(updated.amountCents, 111);
        expect(updated.createdAt, original.createdAt);
        _record('transaction_read_update_verified', {
          'reader': _indexReady ? 'Dart repository' : 'client document SDK',
          'path': primary,
        });

        if (_indexReady) {
          final first = await transactions.fetchPage(limit: 2);
          expect(first.length, 2);
          final second = await transactions.fetchPage(
            after: first.last,
            limit: 2,
          );
          expect(second.length, 1);
          expect({
            ...first.map((t) => t.id),
            ...second.map((t) => t.id),
          }, transactionIds.toSet());
          expect(
            await transactions.fetchPage(after: second.last, limit: 2),
            isEmpty,
          );
          _record('repository_pagination_verified');
        } else {
          _record('pagination_blocked_index_not_ready');
        }

        final month = FinancialMonth(2099, 12);
        final budgetPath = '$root/budgets/2099-12_food';
        expect(
          (await storeA
                  .doc(budgetPath)
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
        documents.add(budgetPath);
        await budgets.save(
          month: month,
          category: Category.food,
          limitCents: 1000,
        );
        expect((await budgets.fetchMonth(month)).single.limitCents, 1000);
        await budgets.save(
          month: month,
          category: Category.food,
          limitCents: 1200,
        );
        expect((await budgets.fetchMonth(month)).single.limitCents, 1200);
        _record('budget_repository_create_read_update_verified', {
          'path': budgetPath,
        });

        for (var index = 1; index <= 2; index++) {
          final role = index == 1 ? 'B' : 'unauthenticated';
          final foreign = stores[index].doc(primary);
          final probe =
              '$root/transactions/$_run-probe-${index == 1 ? 'b' : 'guest'}';
          documents.add(
            probe,
          ); // Incluir na limpeza se as regras permitirem indevidamente.
          await _permissionDenied('$role read A transaction', () async {
            await foreign.get(const GetOptions(source: Source.server));
          });
          await _permissionDenied(
            '$role create A transaction',
            () => stores[index].doc(probe).set({
              ...FirestoreMappers.transactionFields(updated),
              'description': 'TESTE_M3 $_run acesso indevido',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }),
          );
          await _permissionDenied(
            '$role update A transaction',
            () => foreign.update({
              'amountCents': 222,
              'updatedAt': FieldValue.serverTimestamp(),
            }),
          );
          await _permissionDenied(
            '$role delete A transaction',
            () => foreign.delete(),
          );
          await _permissionDenied('$role read A profile', () async {
            await stores[index]
                .doc(root)
                .get(const GetOptions(source: Source.server));
          });
          await _permissionDenied('$role read A budget', () async {
            await stores[index]
                .doc(budgetPath)
                .get(const GetOptions(source: Source.server));
          });
        }
        expect((await readPrimary()).amountCents, 111);
        await budgets.remove(month: month, category: Category.food);
        expect(
          (await storeA
                  .doc(budgetPath)
                  .get(const GetOptions(source: Source.server)))
              .exists,
          isFalse,
        );
        expect(await budgets.fetchMonth(month), isEmpty);
        documents.remove(budgetPath);
        for (final id in transactionIds) {
          final path = '$root/transactions/$id';
          await transactions.delete(id);
          expect(
            (await storeA
                    .doc(path)
                    .get(const GetOptions(source: Source.server)))
                .exists,
            isFalse,
          );
          documents.remove(path);
        }
        _record('repository_deletions_verified');
        successful = true;
      } finally {
        // Somente caminhos rastreados nesta execução, nunca exclusão de coleção.
        if (uidA != null && stores.isNotEmpty) {
          for (final path in documents) {
            try {
              final ref = stores.first.doc(path);
              final snapshot = await ref.get(
                const GetOptions(source: Source.server),
              );
              if (snapshot.exists) {
                final description = snapshot.data()?['description'];
                final isBudget = path == 'users/$uidA/budgets/2099-12_food';
                if (!isBudget &&
                    (description is! String ||
                        !description.startsWith('TESTE_M3 $_run '))) {
                  remaining.add(path);
                  continue;
                }
                await ref.delete();
              }
              if ((await ref.get(const GetOptions(source: Source.server)))
                  .exists) {
                remaining.add(path);
              }
            } catch (_) {
              remaining.add(path);
            }
          }
          if (profileMayExist) {
            final path = 'users/$uidA';
            // Não contornar a regra allow delete:false. Limpeza manual acordada.
            try {
              if ((await stores.first
                      .doc(path)
                      .get(const GetOptions(source: Source.server)))
                  .exists) {
                remaining.add(path);
              }
            } catch (_) {
              remaining.add(path);
            }
          }
        }
        _record('cleanup_report', {
          'remainingDocuments': remaining.toList(),
          'testAccountsRetained': accounts,
          'testsSucceeded': successful,
        });
        for (final auth in auths) {
          // Não apagar contas: exige autorização específica posterior.
          if (accounts.containsValue(auth.currentUser?.uid)) {
            await auth.signOut();
          }
        }
        for (final app in apps) {
          await app.delete(); // Remove instância local do SDK, não conta Authentication.
        }
      }
      expect(
        remaining.where((path) => path != 'users/$uidA'),
        isEmpty,
        reason:
            'Documentos temporários não removidos; consultar cleanup_report.',
      );
    },
    skip: !_approved,
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
