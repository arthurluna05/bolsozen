import 'dart:async';

import 'package:flutter/services.dart';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/data/firebase/firebase_session.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/repositories/transaction_repository.dart';
import 'package:bolsozen/domain/services/money.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';
import 'repository_session_test.dart' show TestAuth, TestUser;
import 'auth_test_fakes.dart' show AuthTestApp;

typedef Fields = Map<String, dynamic>;

// Referências/queries/snapshots reais do SDK, transporte nativo interceptado.
// Não subtipar classes @sealed nem acessar plugin nativo/rede em testes.
class _Wire {
  const _Wire(this.tag, this.fields);
  final int tag;
  final List<Object?> fields;
}

class _ReplyCodec extends StandardMessageCodec {
  const _ReplyCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is Timestamp) {
      buffer.putUint8(188);
      buffer.putInt64(value.seconds);
      buffer.putInt32(value.nanoseconds);
    } else if (value is _Wire) {
      buffer.putUint8(value.tag);
      writeValue(buffer, value.fields);
    } else {
      super.writeValue(buffer, value);
    }
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.delegate);
  final FirebaseFirestore delegate;
  final paths = <String>[];
  final writes = <(String, Fields)>[];
  final deletes = <String>[];
  final readPaths = <String>[];
  Fields? document;
  FirebaseException? readError, confirmationError;
  void Function()? retry;
  int transactionAttempts = 0;
  String queryWire = '';
  Completer<void>? page;
  Completer<void>? beforeHandler, documentRead, afterHandler;
  int transactionReads = 0;
  @override
  CollectionReference<Fields> collection(String path) {
    paths.add(path);
    return delegate.collection(path);
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    await beforeHandler?.future;
    transactionAttempts++;
    final value = await handler(_Transaction(this));
    if (retry != null) {
      // Primeira tentativa abandonada, como um retry transacional do SDK.
      writes.clear();
      deletes.clear();
      retry!();
      transactionAttempts++;
      await handler(_Transaction(this));
    }
    await afterHandler?.future;
    if (confirmationError != null) throw confirmationError!;
    return value;
  }
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Firestore db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    db.transactionReads++;
    await db.documentRead?.future;
    if (db.readError != null) throw db.readError!;
    return ref.get();
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    db.writes.add((ref.path, Map<String, dynamic>.from(data as Fields)));
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    db.writes.add((ref.path, Map<String, dynamic>.from(data)));
    return this;
  }

  @override
  Transaction delete(DocumentReference ref) {
    db.deletes.add(ref.path);
    return this;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const prefix =
      'dev.flutter.pigeon.cloud_firestore_platform_interface.FirebaseFirestoreHostApi.';
  const codec = _ReplyCodec();
  const metadata = _Wire(140, [false, false]);
  var appIndex = 0;
  setUpAll(() async {
    // Registra somente um app no SDK Dart usando resposta Core local, sem plugin
    // nativo/rede. Necessário à criação das referências reais do Firestore.
    const coreChannel =
        'dev.flutter.pigeon.firebase_core_platform_interface.FirebaseCoreHostApi.initializeCore';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(
      coreChannel,
      (_) async => codec.encodeMessage([
        [
          const _Wire(130, [
            '[DEFAULT]',
            _Wire(129, [
              'demo-api-key',
              'demo-app',
              '123',
              'demo-bolsozen',
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
            ]),
            true,
            <String, Object?>{},
          ]),
        ],
      ]),
    );
    await Firebase.initializeApp();
    messenger.setMockMessageHandler(coreChannel, null);
  });
  late TestAuth auth;
  late _Firestore db;
  late TransactionRepository repository;
  final changed = throwsA(
    isA<DataFailure>().having(
      (e) => e.kind,
      'kind',
      DataFailureKind.sessionChanged,
    ),
  );
  Future<String> create({String? expectedUserId}) => repository.create(
    type: TransactionType.expense,
    amountCents: 12345,
    category: Category.food,
    description: 'Teste local',
    occurredAt: DateTime(2026, 11, 17),
    expectedUserId: expectedUserId,
  );
  setUp(() {
    auth = TestAuth()..user = TestUser('A');
    db = _Firestore(
      FirebaseFirestore.instanceFor(
        app: AuthTestApp(name: 'm5-session-${appIndex++}'),
      ),
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('${prefix}queryGet', (
      ByteData? message,
    ) async {
      db.queryWire = String.fromCharCodes(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      db.paths.add(
        RegExp(r'users/[AB]/transactions').firstMatch(db.queryWire)!.group(0)!,
      );
      await db.page?.future;
      return codec.encodeMessage([
        const _Wire(143, [[], [], metadata]),
      ]);
    });
    messenger.setMockMessageHandler('${prefix}documentReferenceGet', (
      message,
    ) async {
      final wire = String.fromCharCodes(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      final path = RegExp(r'users/[AB]/transactions/[A-Za-z0-9_-]+')
          .firstMatch(wire)!
          .group(0)!;
      db.readPaths.add(path);
      return codec.encodeMessage([
        _Wire(141, [path, db.document, metadata]),
      ]);
    });
    addTearDown(() {
      messenger.setMockMessageHandler('${prefix}queryGet', null);
      messenger.setMockMessageHandler('${prefix}documentReferenceGet', null);
    });
    repository = FirestoreTransactionRepository(
      FirebaseSession(auth: auth, firestore: db),
    );
  });

  test(
    'UID esperado correto lê pelo UID autenticado e preserva consulta/cursor',
    () async {
      final after = transaction(userId: 'A');
      expect(
        await repository.fetchPage(after: after, limit: 2, expectedUserId: 'A'),
        isEmpty,
      );
      expect(db.paths, ['users', 'users/A/transactions']);
      expect(db.queryWire, contains('occurredAt'));
      expect(db.queryWire, contains('createdAt'));
      expect(db.queryWire, contains(after.id));
    },
  );
  test(
    'UID esperado correto cria no UID autenticado com auditoria do servidor',
    () async {
      final id = await create(expectedUserId: 'A');
      expect(id, isNotEmpty);
      final (path, data) = db.writes.single;
      expect(path, 'users/A/transactions/$id');
      expect(data['userId'], 'A');
      expect(data['amountCents'], 12345);
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    },
  );
  for (final expected in ['B', '', ' A ']) {
    test(
      'UID divergente "$expected" bloqueia leitura e criação antes do Firestore',
      () async {
        await expectLater(
          repository.fetchPage(expectedUserId: expected),
          changed,
        );
        await expectLater(create(expectedUserId: expected), changed);
        expect(db.paths, isEmpty);
        expect(db.writes, isEmpty);
        expect(db.transactionReads, 0);
      },
    );
  }
  test(
    'SDK já em B rejeita chamada originada de A, sem escrever em B',
    () async {
      auth.user = TestUser('B');
      await expectLater(create(expectedUserId: 'A'), changed);
      await expectLater(repository.fetchPage(expectedUserId: 'A'), changed);
      expect(db.paths, isEmpty);
      expect(db.writes, isEmpty);
    },
  );
  test(
    'Sem sessão permanece unauthenticated antes de qualquer acesso',
    () async {
      auth.user = null;
      final unauthenticated = throwsA(
        isA<DataFailure>().having(
          (e) => e.kind,
          'kind',
          DataFailureKind.unauthenticated,
        ),
      );
      await expectLater(
        repository.fetchPage(expectedUserId: 'A'),
        unauthenticated,
      );
      await expectLater(create(expectedUserId: 'A'), unauthenticated);
      expect(db.paths, isEmpty);
    },
  );
  test('Chamadas anteriores sem argumento permanecem compatíveis e usam a sessão B', () async {
    auth.user = TestUser('B');
    expect(await repository.fetchPage(), isEmpty);
    // Chamada antiga, sem sequer declarar expectedUserId.
    expect(
      await repository.create(
        type: TransactionType.income,
        amountCents: 1,
        category: Category.salary,
        description: 'Receita local',
        occurredAt: DateTime(2026),
      ),
      isNotEmpty,
    );
    expect(db.writes.single.$1, startsWith('users/B/transactions/'));
    expect(db.writes.single.$2['userId'], 'B');
    expect(db.queryWire, contains('users/B/transactions'));
  });
  for (final logout in [false, true]) {
    test(
      'Sessão muda durante fetchPage; logout=$logout rejeita resposta atrasada',
      () async {
        db.page = Completer<void>();
        final call = repository.fetchPage(expectedUserId: 'A');
        final check = expectLater(call, changed);
        auth.user = logout ? null : TestUser('B');
        db.page!.complete();
        await check;
        expect(db.paths, ['users', 'users/A/transactions']);
      },
    );
    test(
      'Sessão muda durante leitura transacional; logout=$logout impede set',
      () async {
        db.documentRead = Completer<void>();
        final call = create(expectedUserId: 'A');
        final check = expectLater(call, changed);
        // Permite entrar no handler e aguardar get, sem relógios ou rede reais.
        await Future<void>.delayed(Duration.zero);
        expect(db.transactionReads, 1);
        auth.user = logout ? null : TestUser('B');
        db.documentRead!.complete();
        await check;
        expect(db.writes, isEmpty);
      },
    );
  }
  test(
    'Troca antes do callback transacional é barrada pela verificação existente',
    () async {
      db.beforeHandler = Completer<void>();
      final check = expectLater(create(expectedUserId: 'A'), changed);
      auth.user = TestUser('B');
      db.beforeHandler!.complete();
      await check;
      expect(db.transactionReads, 0);
      expect(db.writes, isEmpty);
    },
  );
  test(
    'Troca após set e antes da confirmação não retorna sucesso à sessão nova',
    () async {
      db.afterHandler = Completer<void>();
      final check = expectLater(create(expectedUserId: 'A'), changed);
      await Future<void>.delayed(Duration.zero);
      expect(db.writes.single.$2['userId'], 'A');
      auth.user = TestUser('B');
      db.afterHandler!.complete();
      await check;
      expect(db.writes.single.$1, startsWith('users/A/transactions/'));
      // Não promete cancelar/reverter operação já submetida; nunca redireciona a B.
    },
  );

  Fields stored({String uid = 'A'}) {
    final value = transaction(userId: uid);
    return {
      'userId': uid,
      'type': 'expense',
      'amountCents': value.amountCents,
      'categoryId': 'food',
      'description': value.description,
      'occurredAt': Timestamp.fromDate(value.occurredAt),
      'createdAt': Timestamp.fromDate(value.createdAt),
      'updatedAt': Timestamp.fromDate(value.updatedAt),
    };
  }

  Matcher failure(DataFailureKind kind) =>
      throwsA(isA<DataFailure>().having((e) => e.kind, 'kind', kind));

  for (final edit in [true, false]) {
    final operation = edit ? 'update' : 'delete';
    Future<void> mutate({String? expected = 'A'}) => edit
        ? repository.update(transaction(userId: 'A'), expectedUserId: expected)
        : repository.delete('t', expectedUserId: expected);

    test(
      '$operation correto usa UID SDK e preserva integridade/auditoria',
      () async {
        db.document = stored();
        await mutate();
        expect(db.readPaths, ['users/A/transactions/t']);
        expect(db.transactionAttempts, 1);
        if (edit) {
          final (path, data) = db.writes.single;
          expect(path, 'users/A/transactions/t');
          expect(data['userId'], 'A');
          expect(data['amountCents'], transaction().amountCents);
          expect(
            data['occurredAt'],
            Timestamp.fromDate(transaction().occurredAt),
          );
          expect(data.containsKey('createdAt'), isFalse);
          expect(data['updatedAt'], isA<FieldValue>());
        } else {
          expect(db.deletes, ['users/A/transactions/t']);
          expect(db.writes, isEmpty);
        }
      },
    );
    for (final expected in ['B', '', ' A ']) {
      test(
        '$operation expectedUserId divergente "$expected" não acessa Firestore',
        () async {
          await expectLater(mutate(expected: expected), changed);
          expect(db.paths, isEmpty);
          expect(db.transactionAttempts, 0);
          expect(db.transactionReads, 0);
          expect(db.writes, isEmpty);
          expect(db.deletes, isEmpty);
        },
      );
    }
    test(
      '$operation de A quando SDK já está em B não toca ID coincidente em B',
      () async {
        auth.user = TestUser('B');
        db.document = stored(uid: 'B');
        await expectLater(mutate(), changed);
        expect(db.paths, isEmpty);
        expect(db.transactionAttempts, 0);
        expect(db.writes, isEmpty);
        expect(db.deletes, isEmpty);
      },
    );
    test('$operation sem autenticação não inicia operação', () async {
      auth.user = null;
      await expectLater(mutate(), failure(DataFailureKind.unauthenticated));
      expect(db.paths, isEmpty);
      expect(db.transactionAttempts, 0);
    });
    test(
      '$operation antigo sem parâmetro continua usando sessão corrente B',
      () async {
        auth.user = TestUser('B');
        db.document = stored(uid: 'B');
        if (edit) {
          await repository.update(transaction(userId: 'B'));
          expect(db.writes.single.$1, 'users/B/transactions/t');
          expect(db.writes.single.$2['userId'], 'B');
        } else {
          await repository.delete('t');
          expect(db.deletes, ['users/B/transactions/t']);
        }
      },
    );
    test('$operation troca antes do callback impede leitura/escrita', () async {
      db.document = stored();
      db.beforeHandler = Completer<void>();
      final check = expectLater(mutate(), changed);
      auth.user = TestUser('B');
      db.beforeHandler!.complete();
      await check;
      expect(db.transactionReads, 0);
      expect(db.writes, isEmpty);
      expect(db.deletes, isEmpty);
    });
    for (final logout in [true, false]) {
      test(
        '$operation troca durante get, logout=$logout, impede mutação',
        () async {
          db.document = stored();
          db.documentRead = Completer<void>();
          final check = expectLater(mutate(), changed);
          await Future<void>.delayed(Duration.zero);
          expect(db.transactionReads, 1);
          auth.user = logout ? null : TestUser('B');
          db.documentRead!.complete();
          await check;
          expect(db.writes, isEmpty);
          expect(db.deletes, isEmpty);
          expect(db.readPaths, ['users/A/transactions/t']);
        },
      );
    }
    test(
      '$operation troca em retry transacional não executa tentativa como B',
      () async {
        db.document = stored();
        db.retry = () => auth.user = TestUser('B');
        await expectLater(mutate(), changed);
        expect(db.transactionAttempts, 2);
        expect(db.transactionReads, 1);
        expect(db.writes, isEmpty);
        expect(db.deletes, isEmpty);
        expect(db.readPaths, ['users/A/transactions/t']);
      },
    );
    test(
      '$operation troca durante leitura ausente prioriza erro de sessão',
      () async {
        db.documentRead = Completer<void>();
        final check = expectLater(mutate(), changed);
        await Future<void>.delayed(Duration.zero);
        auth.user = TestUser('B');
        db.documentRead!.complete();
        await check;
        expect(db.writes, isEmpty);
        expect(db.deletes, isEmpty);
      },
    );
    test(
      '$operation troca após enfileirar escrita não retorna sucesso para B',
      () async {
        db.document = stored();
        db.afterHandler = Completer<void>();
        final check = expectLater(mutate(), changed);
        await Future<void>.delayed(Duration.zero);
        expect(
          edit ? db.writes.single.$1 : db.deletes.single,
          'users/A/transactions/t',
        );
        auth.user = TestUser('B');
        db.afterHandler!.complete();
        await check;
        expect(db.transactionAttempts, 1);
        expect(db.readPaths, ['users/A/transactions/t']);
      },
    );
    test('$operation documento ausente é notFound, nunca sucesso', () async {
      await expectLater(mutate(), failure(DataFailureKind.notFound));
      expect(db.writes, isEmpty);
      expect(db.deletes, isEmpty);
    });
    test(
      '$operation documento inválido de outro proprietário é recusado',
      () async {
        db.document = stored(uid: 'B');
        await expectLater(mutate(), failure(DataFailureKind.invalidData));
        expect(db.writes, isEmpty);
        expect(db.deletes, isEmpty);
      },
    );
    for (final code in ['unavailable', 'permission-denied']) {
      test(
        '$operation falha $code mantém erro tipado sem mutação ou retry próprio',
        () async {
          db.document = stored();
          db.readError = FirebaseException(
            plugin: 'cloud_firestore',
            code: code,
          );
          await expectLater(
            mutate(),
            failure(
              code == 'unavailable'
                  ? DataFailureKind.unavailable
                  : DataFailureKind.permissionDenied,
            ),
          );
          expect(db.writes, isEmpty);
          expect(db.deletes, isEmpty);
          expect(db.transactionAttempts, 1);
        },
      );
    }
    test('$operation confirmação incerta mantém ID de origem e erro, sem replay', () async {
      db.document = stored();
      db.confirmationError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      );
      await expectLater(mutate(), failure(DataFailureKind.unavailable));
      expect(
        edit ? db.writes.single.$1 : db.deletes.single,
        'users/A/transactions/t',
      );
      expect(db.transactionAttempts, 1);
      expect(db.readPaths, ['users/A/transactions/t']);
      // O caller conserva o ID t para reconciliar. Enfileirar no fake não prova
      // commit, nem a falha prova que o servidor cancelou uma operação real.
    });
  }
  test(
    'update modelo de outro usuário falha antes de acessar documento',
    () async {
      await expectLater(
        repository.update(transaction(userId: 'B'), expectedUserId: 'A'),
        failure(DataFailureKind.permissionDenied),
      );
      expect(db.paths, isEmpty);
      expect(db.transactionAttempts, 0);
    },
  );
  test('update preserva createdAt imutável', () async {
    db.document = stored();
    await expectLater(
      repository.update(
        transaction(userId: 'A', created: DateTime(2000)),
        expectedUserId: 'A',
      ),
      failure(DataFailureKind.invalidData),
    );
    expect(db.writes, isEmpty);
  });
  test('update no limite monetário conserva centavos exatos', () async {
    db.document = stored();
    await repository.update(
      transaction(userId: 'A', amount: Money.maxSafeCents),
      expectedUserId: 'A',
    );
    expect(db.writes.single.$2['amountCents'], Money.maxSafeCents);
  });
  test(
    'update acima do limite monetário é recusado antes de enfileirar',
    () async {
      db.document = stored();
      await expectLater(
        repository.update(
          transaction(userId: 'A', amount: int.parse('9007199254740993')),
          expectedUserId: 'A',
        ),
        failure(DataFailureKind.invalidData),
      );
      expect(db.writes, isEmpty);
    },
  );
}
