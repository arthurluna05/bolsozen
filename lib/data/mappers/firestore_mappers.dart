import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/category.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/models/monthly_budget.dart';
import '../../domain/models/user_profile.dart';

abstract final class FirestoreMappers {
  static const transactionKeys = {
    'userId',
    'type',
    'amountCents',
    'categoryId',
    'description',
    'occurredAt',
    'createdAt',
    'updatedAt',
  };
  static const budgetKeys = {
    'userId',
    'monthKey',
    'categoryId',
    'limitCents',
    'createdAt',
    'updatedAt',
  };
  static const profileKeys = {'displayName', 'email', 'createdAt'};

  static void _keys(Map<String, dynamic> data, Set<String> keys) {
    if (data.length != keys.length || !data.keys.every(keys.contains)) {
      throw const FormatException('Campos inválidos');
    }
  }

  static T _field<T>(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! T) throw FormatException('Campo inválido: $key');
    return value;
  }

  static DateTime _date(Map<String, dynamic> data, String key) =>
      _field<Timestamp>(data, key).toDate();

  static FinancialTransaction transaction(
    String id,
    String uid,
    Map<String, dynamic> data,
  ) {
    _keys(data, transactionKeys);
    if (_field<String>(data, 'userId') != uid) {
      throw const FormatException('Proprietário inválido');
    }
    final typeName = _field<String>(data, 'type');
    final type = TransactionType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => throw const FormatException('Tipo inválido'),
    );
    return FinancialTransaction(
      id: id,
      userId: uid,
      type: type,
      amountCents: _field<int>(data, 'amountCents'),
      category: Category.fromId(_field<String>(data, 'categoryId')),
      description: _field<String>(data, 'description'),
      occurredAt: _date(data, 'occurredAt'),
      createdAt: _date(data, 'createdAt'),
      updatedAt: _date(data, 'updatedAt'),
    );
  }

  static Map<String, dynamic> transactionFields(FinancialTransaction value) => {
    'userId': value.userId,
    'type': value.type.name,
    'amountCents': value.amountCents,
    'categoryId': value.category.id,
    'description': value.description,
    'occurredAt': Timestamp.fromDate(value.occurredAt),
  };

  static FinancialMonth month(String value) {
    if (!RegExp(r'^[0-9]{4}-(0[1-9]|1[0-2])$').hasMatch(value)) {
      throw const FormatException('Competência inválida');
    }
    return FinancialMonth(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(5)),
    );
  }

  static MonthlyBudget budget(
    String id,
    String uid,
    Map<String, dynamic> data,
  ) {
    _keys(data, budgetKeys);
    if (_field<String>(data, 'userId') != uid) {
      throw const FormatException('Proprietário inválido');
    }
    final value = MonthlyBudget(
      userId: uid,
      month: month(_field<String>(data, 'monthKey')),
      category: Category.fromId(_field<String>(data, 'categoryId')),
      limitCents: _field<int>(data, 'limitCents'),
      createdAt: _date(data, 'createdAt'),
      updatedAt: _date(data, 'updatedAt'),
    );
    if (value.id != id) {
      throw const FormatException('Identidade de orçamento inválida');
    }
    return value;
  }

  static Map<String, dynamic> budgetFields(MonthlyBudget value) => {
    'userId': value.userId,
    'monthKey': value.month.key,
    'categoryId': value.category.id,
    'limitCents': value.limitCents,
  };

  static UserProfile profile(String uid, Map<String, dynamic> data) {
    _keys(data, profileKeys);
    return UserProfile(
      userId: uid,
      displayName: _field<String>(data, 'displayName'),
      email: _field<String>(data, 'email'),
      createdAt: _date(data, 'createdAt'),
    );
  }
}
