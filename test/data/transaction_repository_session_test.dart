import 'dart:async';

import 'package:flutter/services.dart';

import 'package:bolsozen/data/firebase/data_failure.dart';
import 'package:bolsozen/data/firebase/firebase_session.dart';
import 'package:bolsozen/data/repositories/firestore_transaction_repository.dart';
import 'package:bolsozen/domain/models/category.dart';
import 'package:bolsozen/domain/repositories/transaction_repository.dart';
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
    if (value is _Wire) {
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
    final value = await handler(_Transaction(this));
    await afterHandler?.future;
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
    return ref.get();
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    db.writes.add((ref.path, Map<String, dynamic>.from(data as Fields)));
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
    messenger.setMockMessageHandler(
      '${prefix}documentReferenceGet',
      (_) async => codec.encodeMessage([
        const _Wire(141, ['users/A/transactions/test', null, metadata]),
      ]),
    );
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
}
