import 'package:bolsozen/data/mappers/firestore_mappers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  Map<String, dynamic> transactionData() => {
    ...FirestoreMappers.transactionFields(transaction()),
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  };
  Map<String, dynamic> budgetData() => {
    ...FirestoreMappers.budgetFields(budget()),
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  };
  test(
    'Transação mantém valores, tipo, ID e precisão temporal na conversão',
    () {
      final value = transaction(amount: 9007199254740993);
      final fields = {
        ...FirestoreMappers.transactionFields(value),
        'createdAt': Timestamp.fromDate(value.createdAt),
        'updatedAt': Timestamp.fromDate(value.updatedAt),
      };
      final restored = FirestoreMappers.transaction(value.id, 'A', fields);
      expect(restored.amountCents, value.amountCents);
      expect(restored.occurredAt, value.occurredAt);
      expect(restored.createdAt, value.createdAt);
      expect(restored.type, value.type);
      expect(restored.category, value.category);
      expect(restored.id, value.id);
      expect(fields['amountCents'], isA<int>());
    },
  );
  for (final entry in <String, dynamic>{
    'userId': 'B',
    'type': 'invalid',
    'amountCents': 1.5,
    'categoryId': 'salary',
    'description': '',
    'occurredAt': 'wrong',
    'createdAt': null,
    'updatedAt': 'wrong',
    'extra': true,
  }.entries) {
    test('Recusa documento de transação inválido: ${entry.key}', () {
      expect(
        () => FirestoreMappers.transaction('t', 'A', {
          ...transactionData(),
          entry.key: entry.value,
        }),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    });
  }
  test('Documento incompleto é recusado', () {
    final data = transactionData()..remove('type');
    expect(
      () => FirestoreMappers.transaction('t', 'A', data),
      throwsFormatException,
    );
  });
  test('Orçamento mantém chave, limite e datas', () {
    final value = FirestoreMappers.budget('2026-11_food', 'A', budgetData());
    expect(value.limitCents, 30000);
    expect(value.id, '2026-11_food');
    expect(value.createdAt, now);
  });
  for (final entry in <String, dynamic>{
    'userId': 'B',
    'monthKey': '2026-13',
    'categoryId': 'salary',
    'limitCents': -1,
    'createdAt': null,
    'extra': true,
  }.entries) {
    test('Recusa orçamento inválido: ${entry.key}', () {
      expect(
        () => FirestoreMappers.budget('2026-11_food', 'A', {
          ...budgetData(),
          entry.key: entry.value,
        }),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    });
  }
  test('Recusa ID de limite divergente', () {
    expect(
      () => FirestoreMappers.budget('wrong', 'A', budgetData()),
      throwsFormatException,
    );
  });
  test('Perfil convertido e validado sem campos confidenciais', () {
    final value = FirestoreMappers.profile('A', {
      'displayName': 'Pessoa A',
      'email': 'a@example.test',
      'createdAt': Timestamp.fromDate(now),
    });
    expect(value.userId, 'A');
    expect(value.displayName, 'Pessoa A');
    expect(value.createdAt, now);
    expect(
      () => FirestoreMappers.profile('A', {
        'displayName': 'A',
        'email': 'invalid',
        'createdAt': Timestamp.fromDate(now),
      }),
      throwsArgumentError,
    );
    expect(
      () => FirestoreMappers.profile('A', {
        'displayName': 'Pessoa',
        'email': 'a@example.test',
        'createdAt': Timestamp.fromDate(now),
        'password': 'proibido',
      }),
      throwsFormatException,
    );
  });
}
