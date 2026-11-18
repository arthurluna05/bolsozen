// Regressão pura VM/JavaScript/Chrome, sem Firebase.
// Valores grandes são strings para não perder precisão já no literal compilado.
import 'dart:convert';
import 'dart:async';

import 'package:bolsozen/domain/services/money.dart';
import 'package:bolsozen/domain/services/financial_calculator.dart';
import 'package:bolsozen/domain/models/financial_month.dart';
import 'package:bolsozen/domain/models/category.dart';

import '../domain/fixtures.dart';

void main() {
  final cases = <Map<String, Object?>>[];
  for (final raw in [
    '1',
    '123456',
    '9007199254740990',
    '9007199254740991',
    '9007199254740992',
    '9007199254740993',
    '9007199254740994',
    '9007199254740995',
  ]) {
    final expected = BigInt.parse(raw);
    final padded = raw.padLeft(3, '0');
    final brl =
        '${padded.substring(0, padded.length - 2)},${padded.substring(padded.length - 2)}';
    if (expected > BigInt.from(Money.maxSafeCents)) {
      var rejected = false;
      try {
        Money.parseCents(brl);
      } on FormatException {
        rejected = true;
      }
      if (!rejected) throw StateError('UNSAFE_INPUT_ACCEPTED');
      // Simula também um int já convertido pelo SDK JS; não confiar na origem.
      var numericRejected = false;
      try {
        Money.requireSafeCents(int.parse(raw));
      } on FormatException {
        numericRejected = true;
      }
      if (!numericRejected) throw StateError('UNSAFE_NUMBER_ACCEPTED');
      cases.add({
        'expectedCents': raw,
        'rejected': true,
        'numericRejected': true,
        'parseExact': true,
      });
      continue;
    }
    final parsed = Money.parseCents(brl);
    final converted = int.parse(raw);
    cases.add({
      'expectedCents': raw,
      'inputBRL': brl,
      'parsedCents': parsed.toString(),
      'parseExact': BigInt.from(parsed) == expected,
      'convertedCents': converted.toString(),
      'conversionExact': BigInt.from(converted) == expected,
      'formatted': Money.formatCents(parsed),
      'formattedNegative': Money.formatCents(-parsed),
      'roundTripCents': Money.parseCents(Money.formatCents(parsed)).toString(),
      'roundTripExact':
          BigInt.from(Money.parseCents(Money.formatCents(parsed))) == expected,
    });
  }
  var aggregateRejected = false;
  try {
    final result = FinancialCalculator.summarize(
      userId: 'A',
      month: FinancialMonth(2026, 11),
      transactions: [
        transaction(category: Category.salary, amount: Money.maxSafeCents),
        transaction(id: 'extra', category: Category.salary, amount: 2),
      ],
    );
    if (Money.isJavaScript) throw StateError('UNSAFE_AGGREGATE_ACCEPTED');
    if (BigInt.from(result.balanceCents) != BigInt.parse('9007199254740993')) {
      throw StateError('NATIVE_PRECISION_LOSS');
    }
  } on StateError catch (error) {
    if (!Money.isJavaScript || error.message == 'UNSAFE_AGGREGATE_ACCEPTED') {
      rethrow;
    }
    aggregateRejected = true;
  }
  if (cases.any(
    (c) =>
        c['parseExact'] != true ||
        (c['roundTripExact'] != null && c['roundTripExact'] != true),
  )) {
    throw StateError('PRECISION_LOSS');
  }
  Zone.current.print(
    'MONEY_PRECISION ${jsonEncode({'cases': cases, 'aggregateRejected': aggregateRejected, 'javaScript': Money.isJavaScript, 'precisionLossDetected': false})}',
  );
}
