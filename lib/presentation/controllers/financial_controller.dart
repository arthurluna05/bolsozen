import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../data/firebase/data_failure.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/financial_calculator.dart';
import '../../domain/services/money.dart';
import '../../domain/services/transaction_validation.dart';
import 'session_controller.dart';

enum FinancialPhase {
  idle,
  loading,
  refreshing,
  ready,
  empty,
  error,
  sessionInvalidated,
}

enum TransactionSubmissionStatus {
  confirmed,
  refreshPending,
  failed,
  uncertain,
  sessionInvalidated,
  busy,
}

final class TransactionSubmissionResult {
  const TransactionSubmissionResult(
    this.status, {
    this.id,
    this.failure,
    this.expectedTransaction,
  });
  final TransactionSubmissionStatus status;
  final String? id;
  final DataFailure? failure;
  final FinancialTransaction? expectedTransaction;
}

/// Uma instância pertence a uma única sessão pronta, nunca é reutilizada por UID.
/// Não inicia consultas no construtor. Escrita confirmada exige nova carga completa.
final class FinancialController extends ChangeNotifier {
  FinancialController({
    required TransactionRepository transactions,
    required SessionController session,
    required this.expectedUserId,
    FinancialMonth? initialMonth,
  }) : _repository = transactions,
       _session = session,
       _identityVersion = session.navigationVersion,
       _month = initialMonth ?? FinancialMonth.fromDate(DateTime.now()) {
    if (expectedUserId.trim().isEmpty) throw ArgumentError('UID obrigatório');
    _session.addListener(_onSession);
    if (!_sameSession) _invalidateSession();
  }

  final TransactionRepository _repository;
  final SessionController _session;
  final String expectedUserId;
  final int _identityVersion;
  FinancialMonth _month;
  FinancialPhase _phase = FinancialPhase.idle;
  List<FinancialTransaction> _transactions = const [];
  FinancialSummary? _summary;
  DataFailure? _failure;
  Future<void>? _inFlight;
  int _generation = 0;
  bool _disposed = false;
  bool _submitting = false, _requiresReconciliation = false;
  Completer<void>? _submissionDone;
  int _submissionVersion = 0;
  final _pendingCreatedIds = <String>{};
  final _pendingUpdates = <String, FinancialTransaction>{};
  final _pendingDeletedIds = <String>{};

  bool get isSubmitting => _submitting;
  bool get hasPendingRefresh =>
      _pendingCreatedIds.isNotEmpty ||
      _pendingUpdates.isNotEmpty ||
      _pendingDeletedIds.isNotEmpty;
  bool get requiresReconciliation => _requiresReconciliation;

  FinancialMonth get month => _month;
  FinancialPhase get phase => _phase;
  List<FinancialTransaction> get transactions => _transactions;
  FinancialSummary? get summary => _summary;
  DataFailure? get failure => _failure;
  bool get isLoading =>
      _phase == FinancialPhase.loading || _phase == FinancialPhase.refreshing;
  bool get hasConfirmedSnapshot => _summary != null;

  /// A UI futura deve identificar explicitamente esse snapshot como desatualizado.
  bool get isStale =>
      hasConfirmedSnapshot &&
      (_phase == FinancialPhase.refreshing ||
          _phase == FinancialPhase.error ||
          hasPendingRefresh);

  bool get _sameSession =>
      !_disposed &&
      _phase != FinancialPhase.sessionInvalidated &&
      _session.isReady &&
      _session.user?.uid == expectedUserId &&
      _session.navigationVersion == _identityVersion;

  void _onSession() {
    if (!_sameSession) _invalidateSession();
  }

  void _invalidateSession() {
    if (_disposed || _phase == FinancialPhase.sessionInvalidated) return;
    _generation++;
    _submissionVersion++;
    _pendingCreatedIds.clear();
    _pendingUpdates.clear();
    _pendingDeletedIds.clear();
    _requiresReconciliation = false;
    _transactions = const [];
    _summary = null;
    _failure = const DataFailure(
      DataFailureKind.sessionChanged,
      'Sua sessão mudou. Entre novamente para carregar os dados.',
    );
    _phase = FinancialPhase.sessionInvalidated;
    notifyListeners();
  }

  bool _current(int generation) {
    if (!_sameSession) {
      _invalidateSession();
      return false;
    }
    return generation == _generation;
  }

  /// Várias telas podem pedir a carga inicial sem repetir uma carga já completa.
  Future<void> load() {
    if (!_sameSession) {
      _invalidateSession();
      return Future.value();
    }
    if (_inFlight != null) return _inFlight!;
    if (_phase == FinancialPhase.ready || _phase == FinancialPhase.empty) {
      return Future.value();
    }
    return refresh();
  }

  Future<void> retry() => refresh();

  /// Compartilha a mesma operação, inclusive se um listener chamar refresh.
  Future<void> refresh() {
    if (!_sameSession) {
      _invalidateSession();
      return Future.value();
    }
    if (_submitting) return _submissionDone!.future;
    return _startRefresh();
  }

  Future<void> _startRefresh() {
    if (_inFlight != null) return _inFlight!;
    final completion = Completer<void>();
    final operation = completion.future;
    _inFlight = operation;
    final generation = ++_generation;
    _phase = hasConfirmedSnapshot
        ? FinancialPhase.refreshing
        : FinancialPhase.loading;
    _failure = null;
    notifyListeners();
    unawaited(
      _readAll(generation).whenComplete(() {
        if (identical(_inFlight, operation)) _inFlight = null;
        completion.complete();
      }),
    );
    return operation;
  }

  Future<void> _readAll(int generation) async {
    final buffer = <String, FinancialTransaction>{};
    final cursors = <(DateTime, DateTime, String)>{};
    FinancialTransaction? cursor;
    try {
      while (_current(generation)) {
        final page = await _repository.fetchPage(
          limit: 100,
          after: cursor,
          expectedUserId: expectedUserId,
        );
        if (!_current(generation)) return;
        if (page.length > 100) {
          throw const FormatException('Página excede limite');
        }
        for (final value in page) {
          if (value.userId != expectedUserId) {
            _invalidateSession();
            return;
          }
          Money.requireSafeCents(value.amountCents);
          final previous = buffer[value.id];
          if (previous != null && !_sameContent(previous, value)) {
            throw const FormatException('Documentos conflitantes');
          }
          buffer[value.id] = value;
        }
        if (page.isNotEmpty) {
          final last =
              page.last; // Cursor bruto, nunca o último item deduplicado.
          final key = (last.occurredAt, last.createdAt, last.id);
          if (!cursors.add(key) ||
              (cursor != null && !_advances(cursor, last))) {
            throw const FormatException('Cursor sem avanço ou cíclico');
          }
          cursor = last;
        }
        if (page.length < 100) {
          if (!_current(generation)) return;
          if (!_pendingCreatedIds.every(buffer.containsKey)) {
            throw const DataFailure(
              DataFailureKind.unavailable,
              'Movimentação salva; não foi possível confirmar a atualização do histórico. Tente atualizar os dados.',
            );
          }
          if (!_pendingUpdates.values.every((expected) {
            final actual = buffer[expected.id];
            return actual != null && _sameUpdate(actual, expected);
          })) {
            throw const DataFailure(
              DataFailureKind.unavailable,
              'Edição salva; não foi possível confirmar as alterações no histórico. Atualize os dados.',
            );
          }
          if (_pendingDeletedIds.any(buffer.containsKey)) {
            throw const DataFailure(
              DataFailureKind.unavailable,
              'Transação excluída; não foi possível confirmar a ausência no histórico. Atualize os dados.',
            );
          }
          final calculated = FinancialCalculator.summarize(
            userId: expectedUserId,
            month: _month,
            transactions: buffer.values,
          );
          if (!_current(generation)) return;
          _summary = calculated;
          _pendingCreatedIds.clear();
          _pendingUpdates.clear();
          _pendingDeletedIds.clear();
          _requiresReconciliation = false;
          _transactions = calculated.history;
          _failure = null;
          _phase = _transactions.isEmpty
              ? FinancialPhase.empty
              : FinancialPhase.ready;
          notifyListeners();
          return;
        }
      }
    } catch (error) {
      if (!_current(generation)) return;
      if (error is DataFailure &&
          (error.kind == DataFailureKind.sessionChanged ||
              error.kind == DataFailureKind.unauthenticated)) {
        _invalidateSession();
        return;
      }
      _failure = _mapFailure(error);
      if (_failure!.kind == DataFailureKind.permissionDenied) {
        _summary = null;
        _transactions = const [];
      }
      _phase = FinancialPhase.error;
      notifyListeners();
    }
  }

  Future<TransactionSubmissionResult> createTransaction({
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  }) =>
      _submitTransaction(
        type: type,
        amountCents: amountCents,
        category: category,
        description: description,
        occurredAt: occurredAt,
      ).then(
        (result) => _sameSession
            ? result
            : const TransactionSubmissionResult(
                TransactionSubmissionStatus.sessionInvalidated,
              ),
      );

  /// Snapshot confirmado do UID atual, sem resolução de proprietário pela UI.
  FinancialTransaction? transactionById(String id) {
    if (!_sameSession || !hasConfirmedSnapshot) return null;
    for (final value in _transactions) {
      if (value.id == id) return value;
    }
    return null;
  }

  bool canEdit(FinancialTransaction original) {
    final value = transactionById(original.id);
    return value != null &&
        !isSubmitting &&
        !isStale &&
        !requiresReconciliation &&
        original.userId == expectedUserId &&
        _sameContent(value, original);
  }

  bool confirmsUpdate(FinancialTransaction expected) {
    final actual = transactionById(expected.id);
    return actual != null &&
        !isStale &&
        !requiresReconciliation &&
        failure == null &&
        _sameUpdate(actual, expected);
  }

  bool confirmsDeletion(FinancialTransaction original) =>
      _sameSession &&
      hasConfirmedSnapshot &&
      !isStale &&
      !requiresReconciliation &&
      failure == null &&
      original.userId == expectedUserId &&
      transactionById(original.id) == null;

  Future<TransactionSubmissionResult> deleteTransaction(
    FinancialTransaction original,
  ) =>
      _submitTransaction(
        original: original,
        deleting: true,
        type: original.type,
        amountCents: original.amountCents,
        category: original.category,
        description: original.description,
        occurredAt: original.occurredAt,
      ).then(
        (result) => _sameSession
            ? result
            : const TransactionSubmissionResult(
                TransactionSubmissionStatus.sessionInvalidated,
              ),
      );

  void _validateOriginal(FinancialTransaction original) {
    if (original.userId != expectedUserId) {
      throw const DataFailure(
        DataFailureKind.permissionDenied,
        'Registro de outro usuário.',
      );
    }
    final stored = transactionById(original.id);
    if (stored == null) {
      throw const DataFailure(
        DataFailureKind.notFound,
        'Transação não encontrada. Atualize os dados.',
      );
    }
    if (!_sameContent(stored, original)) {
      throw const DataFailure(
        DataFailureKind.invalidData,
        'A transação mudou. Atualize os dados e abra a edição novamente.',
      );
    }
  }

  Future<TransactionSubmissionResult> updateTransaction({
    required FinancialTransaction original,
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  }) =>
      _submitTransaction(
        original: original,
        type: type,
        amountCents: amountCents,
        category: category,
        description: description,
        occurredAt: occurredAt,
      ).then(
        (result) => _sameSession
            ? result
            : const TransactionSubmissionResult(
                TransactionSubmissionStatus.sessionInvalidated,
              ),
      );

  Future<TransactionSubmissionResult> _submitTransaction({
    FinancialTransaction? original,
    bool deleting = false,
    required TransactionType type,
    required int amountCents,
    required Category category,
    required String description,
    required DateTime occurredAt,
  }) async {
    if (!_sameSession) {
      _invalidateSession();
      return const TransactionSubmissionResult(
        TransactionSubmissionStatus.sessionInvalidated,
      );
    }
    if (_submitting) {
      return const TransactionSubmissionResult(
        TransactionSubmissionStatus.busy,
      );
    }
    if (_requiresReconciliation || hasPendingRefresh) {
      return const TransactionSubmissionResult(
        TransactionSubmissionStatus.uncertain,
        failure: DataFailure(
          DataFailureKind.unavailable,
          'Atualize e confira o histórico antes de iniciar outro lançamento.',
        ),
      );
    }
    try {
      if (original != null) _validateOriginal(original);
      TransactionValidation.check(
        type: type,
        amountCents: amountCents,
        category: category,
        description: description,
        occurredAt: occurredAt,
      );
    } catch (error) {
      return TransactionSubmissionResult(
        TransactionSubmissionStatus.failed,
        failure: error is DataFailure
            ? error
            : const DataFailure(
                DataFailureKind.invalidData,
                'Confira os campos da transação.',
              ),
      );
    }
    final version = ++_submissionVersion;
    _submitting = true;
    final done = Completer<void>();
    _submissionDone = done;
    notifyListeners();
    bool current() => _sameSession && _submissionVersion == version;
    String? confirmedId;
    final expected = deleting
        ? null
        : original?.copyWith(
            type: type,
            amountCents: amountCents,
            category: category,
            description: description,
            occurredAt: occurredAt,
          );
    try {
      // Nenhuma leitura antiga pode substituir a recarga posterior ao commit.
      final previousRead = _inFlight;
      if (previousRead != null) await previousRead;
      if (!current()) {
        return const TransactionSubmissionResult(
          TransactionSubmissionStatus.sessionInvalidated,
        );
      }
      if (original != null) {
        _validateOriginal(original);
        if (deleting) {
          await _repository.delete(original.id, expectedUserId: expectedUserId);
        } else {
          await _repository.update(expected!, expectedUserId: expectedUserId);
        }
        confirmedId = original.id;
      } else {
        confirmedId = await _repository.create(
          type: type,
          amountCents: amountCents,
          category: category,
          description: description.trim(),
          occurredAt: occurredAt,
          expectedUserId: expectedUserId,
        );
      }
      if (!current()) {
        return const TransactionSubmissionResult(
          TransactionSubmissionStatus.sessionInvalidated,
        );
      }
      if (confirmedId.trim().isEmpty) {
        throw const FormatException('Identificador não confirmado');
      }
      if (deleting) {
        _pendingDeletedIds.add(confirmedId);
      } else if (expected != null) {
        _pendingUpdates[confirmedId] = expected;
      } else {
        _pendingCreatedIds.add(confirmedId);
      }
      await _startRefresh();
      if (!current()) {
        return const TransactionSubmissionResult(
          TransactionSubmissionStatus.sessionInvalidated,
        );
      }
      return TransactionSubmissionResult(
        hasPendingRefresh || _failure != null
            ? TransactionSubmissionStatus.refreshPending
            : TransactionSubmissionStatus.confirmed,
        id: confirmedId,
        failure: _failure,
        expectedTransaction: expected,
      );
    } catch (error) {
      if (!current()) {
        return const TransactionSubmissionResult(
          TransactionSubmissionStatus.sessionInvalidated,
        );
      }
      if (error is DataFailure &&
          (error.kind == DataFailureKind.sessionChanged ||
              error.kind == DataFailureKind.unauthenticated)) {
        _invalidateSession();
        return const TransactionSubmissionResult(
          TransactionSubmissionStatus.sessionInvalidated,
        );
      }
      final failure = _mapFailure(error);
      final uncertain =
          confirmedId != null ||
          failure.kind == DataFailureKind.unavailable ||
          failure.kind == DataFailureKind.unknown;
      if (uncertain) {
        _requiresReconciliation = true;
        _failure = failure;
        _phase = FinancialPhase.error;
      }
      return TransactionSubmissionResult(
        uncertain
            ? TransactionSubmissionStatus.uncertain
            : TransactionSubmissionStatus.failed,
        failure: failure,
        id: original?.id,
        expectedTransaction: expected,
      );
    } finally {
      _submitting = false;
      if (identical(_submissionDone, done)) _submissionDone = null;
      done.complete();
      if (!_disposed) notifyListeners();
    }
  }

  void selectMonth(FinancialMonth value) {
    if (!_sameSession) {
      _invalidateSession();
      return;
    }
    if (_month == value) return;
    _month = value;
    if (_summary != null) {
      try {
        _summary = FinancialCalculator.summarize(
          userId: expectedUserId,
          month: _month,
          transactions: _transactions,
        );
      } catch (error) {
        // Nunca associar os totais do mês anterior ao novo rótulo.
        _summary = null;
        _transactions = const [];
        _failure = _mapFailure(error);
        _phase = FinancialPhase.error;
      }
    }
    notifyListeners();
  }

  static DataFailure _mapFailure(Object error) {
    if (error is DataFailure) return error;
    if (error is FormatException ||
        error is ArgumentError ||
        error is StateError) {
      return const DataFailure(
        DataFailureKind.invalidData,
        'Não foi possível calcular valores financeiros válidos. Atualize os dados ou tente novamente.',
      );
    }
    return const DataFailure(
      DataFailureKind.unknown,
      'Não foi possível carregar os dados financeiros. Tente novamente.',
    );
  }

  // Valida o protocolo do cursor; os cálculos/ordenação finais são do domínio.
  static bool _advances(
    FinancialTransaction before,
    FinancialTransaction after,
  ) {
    final date = after.occurredAt.compareTo(before.occurredAt);
    if (date != 0) return date < 0;
    final creation = after.createdAt.compareTo(before.createdAt);
    return creation != 0 ? creation < 0 : after.id.compareTo(before.id) > 0;
  }

  static bool _sameContent(FinancialTransaction a, FinancialTransaction b) =>
      _sameUpdate(a, b) && a.updatedAt == b.updatedAt;

  // updatedAt é auditoria do servidor, não o valor antecipado pelo formulário.
  static bool _sameUpdate(FinancialTransaction a, FinancialTransaction b) =>
      a.id == b.id &&
      a.userId == b.userId &&
      a.type == b.type &&
      a.amountCents == b.amountCents &&
      a.category == b.category &&
      a.description == b.description &&
      a.occurredAt == b.occurredAt &&
      a.createdAt == b.createdAt;

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _disposed = true;
    _generation++;
    _submissionVersion++;
    _pendingCreatedIds.clear();
    _pendingUpdates.clear();
    _pendingDeletedIds.clear();
    _phase = FinancialPhase.sessionInvalidated;
    _summary = null;
    _transactions = const [];
    _failure = null;
    super.dispose();
  }
}
