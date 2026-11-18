import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../data/firebase/data_failure.dart';
import '../../domain/models/financial_month.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/models/category.dart';
import '../../domain/models/monthly_budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/financial_calculator.dart';
import '../../domain/services/money.dart';
import '../../domain/services/transaction_validation.dart';
import 'session_controller.dart';
import 'budget_month_state.dart';
import 'budget_submission_result.dart';

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
    BudgetRepository? budgets,
    DateTime Function()? clock,
  }) : _repository = transactions,
       _budgetRepository = budgets,
       _clock = clock ?? DateTime.now,
       _selectedBudgetMonth = FinancialMonth.fromDate(
         (clock ?? DateTime.now)(),
       ),
       _session = session,
       _identityVersion = session.navigationVersion,
       _month =
           initialMonth ?? FinancialMonth.fromDate((clock ?? DateTime.now)()) {
    if (expectedUserId.trim().isEmpty) throw ArgumentError('UID obrigatório');
    _session.addListener(_onSession);
    if (!_sameSession) _invalidateSession();
  }

  final TransactionRepository _repository;
  final BudgetRepository? _budgetRepository;
  final DateTime Function() _clock;
  FinancialMonth _selectedBudgetMonth;
  bool _manualBudgetMonth = false, _budgetsRequested = false;
  final _budgetCache = <FinancialMonth, _BudgetEntry>{};
  final _budgetFlights = <FinancialMonth, _BudgetEntry>{};
  final _pendingBudgetChanges = <FinancialMonth, Map<Category, int?>>{};
  final _budgetResults = <FinancialMonth, BudgetSubmissionResult>{};
  bool _budgetWriting = false;
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
  bool get hasPendingBudgetChanges => _pendingBudgetChanges.isNotEmpty;
  bool get sessionValid => _sameSession;
  BudgetSubmissionResult? budgetResultFor(FinancialMonth month) =>
      _sameSession ? _budgetResults[month] : null;

  bool canEditBudgets(FinancialMonth month) {
    final entry = _budgetCache[month];
    return _sameSession &&
        _budgetRepository != null &&
        !_submitting &&
        !hasPendingBudgetChanges &&
        !_requiresReconciliation &&
        !hasPendingRefresh &&
        entry?.limits != null &&
        entry?.failure == null &&
        (entry?.phase == BudgetPhase.ready ||
            entry?.phase == BudgetPhase.empty);
  }

  FinancialMonth get selectedBudgetMonth => _selectedBudgetMonth;
  bool get hasManualBudgetMonth => _manualBudgetMonth;
  Set<FinancialMonth> get cachedBudgetMonths =>
      Set.unmodifiable(_budgetCache.keys);
  BudgetMonthState get selectedBudgetState =>
      budgetStateFor(_selectedBudgetMonth);
  BudgetMonthState get dashboardBudgetState => budgetStateFor(_month);

  BudgetMonthState budgetStateFor(FinancialMonth month) {
    final available = _budgetRepository != null && _sameSession;
    final entry = available ? _budgetCache[month] : null;
    final phase = entry?.projectionFailure != null
        ? BudgetPhase.error
        : entry?.phase ?? BudgetPhase.idle;
    return BudgetMonthState(
      userId: expectedUserId,
      month: month,
      available: available,
      phase: phase,
      limits: entry?.limits,
      summary: entry?.summary,
      failure: entry?.failure ?? entry?.projectionFailure,
      lastConfirmedAt: entry?.lastConfirmedAt,
      isStale:
          entry?.limits != null &&
          (isStale ||
              _pendingBudgetChanges.containsKey(month) ||
              _submitting ||
              !hasConfirmedSnapshot ||
              phase == BudgetPhase.refreshing ||
              phase == BudgetPhase.error),
    );
  }

  /// Ação explícita, independente do mês financeiro do Dashboard.
  Future<void> selectBudgetMonth(FinancialMonth value) {
    if (!_sameSession) {
      _invalidateSession();
      return Future.value();
    }
    _manualBudgetMonth = true;
    _selectedBudgetMonth = value;
    _pruneBudgetCache();
    notifyListeners();
    return loadBudgets();
  }

  /// Chamado pelo relógio/lifecycle existente; não cria timer ou polling remoto.
  void syncCurrentMonth({DateTime? now}) {
    if (!_sameSession) {
      _invalidateSession();
      return;
    }
    final current = FinancialMonth.fromDate(now ?? _clock());
    final changed = current != _month;
    final previous = _selectedBudgetMonth;
    if (!_manualBudgetMonth) _selectedBudgetMonth = current;
    // A competência financeira continua sendo sincronizada pelo Dashboard.
    selectMonth(current);
    _pruneBudgetCache();
    if (previous != _selectedBudgetMonth || changed) {
      notifyListeners();
      if (_budgetsRequested) {
        unawaited(loadBudgets(month: current));
        if (_selectedBudgetMonth != current) unawaited(loadBudgets());
      }
    }
  }

  void _pruneBudgetCache() {
    _budgetCache.removeWhere(
      (month, _) => month != _month && month != _selectedBudgetMonth,
    );
  }

  void _retainBudget(_BudgetEntry entry) {
    _budgetCache.remove(entry.month);
    _budgetCache[entry.month] = entry;
    while (_budgetCache.length > 2) {
      final victim = _budgetCache.keys.firstWhere(
        (month) => month != entry.month && month != _month,
        orElse: () =>
            _budgetCache.keys.firstWhere((month) => month != entry.month),
      );
      _budgetCache.remove(victim);
    }
  }

  Future<void> loadBudgets({FinancialMonth? month}) =>
      _loadBudgets(month ?? _selectedBudgetMonth, refresh: false);
  Future<void> refreshBudgets({FinancialMonth? month}) =>
      _loadBudgets(month ?? _selectedBudgetMonth, refresh: true);

  /// Refresh explícito: não é usado pelo CRUD, que relê somente transações.
  Future<void> refreshFinancialData() async {
    if (!_sameSession) {
      _invalidateSession();
      return;
    }
    await Future.wait([
      refresh(),
      for (final month in {_month, _selectedBudgetMonth})
        refreshBudgets(month: month),
    ]);
  }

  Future<void> _loadBudgets(FinancialMonth month, {required bool refresh}) {
    if (!_sameSession) {
      _invalidateSession();
      return Future.value();
    }
    if (_budgetRepository == null) return Future.value();
    if (_budgetWriting) {
      return _submissionDone!.future.then(
        (_) => _loadBudgets(month, refresh: refresh),
      );
    }
    _budgetsRequested = true;
    final entry =
        _budgetFlights[month] ?? _budgetCache[month] ?? _BudgetEntry(month);
    _retainBudget(entry);
    if (entry.inFlight != null) return entry.inFlight!;
    if (!refresh && entry.limits != null) return Future.value();
    final completion = Completer<void>();
    final operation = completion.future;
    entry.inFlight = operation;
    _budgetFlights[month] = entry;
    final generation = ++entry.generation;
    entry.phase = entry.limits == null
        ? BudgetPhase.loading
        : BudgetPhase.refreshing;
    entry.failure = null;
    notifyListeners();
    unawaited(
      _readBudgets(entry, generation).whenComplete(() {
        if (identical(_budgetFlights[month], entry)) {
          _budgetFlights.remove(month);
        }
        entry.inFlight = null;
        completion.complete();
      }),
    );
    return operation;
  }

  bool _currentBudget(_BudgetEntry entry, int generation) =>
      _sameSession &&
      entry.generation == generation &&
      identical(_budgetFlights[entry.month], entry);

  Future<void> _readBudgets(_BudgetEntry entry, int generation) async {
    if (!_currentBudget(entry, generation)) return;
    try {
      final values = await _budgetRepository!.fetchMonth(
        entry.month,
        expectedUserId: expectedUserId,
      );
      if (!_currentBudget(entry, generation)) return;
      final ids = <String>{};
      for (final value in values) {
        if (value.userId != expectedUserId ||
            value.month != entry.month ||
            value.category.type != TransactionType.expense ||
            value.limitCents <= 0 ||
            value.id != '${entry.month.key}_${value.category.id}' ||
            !ids.add(value.id)) {
          throw const FormatException(
            'Limites incompatíveis com a competência/identidade',
          );
        }
        Money.requireSafeCents(value.limitCents);
      }
      if (!identical(_budgetCache[entry.month], entry)) return;
      _reconcileBudgetSnapshot(entry.month, values);
      entry.limits = List.unmodifiable(values);
      entry.lastConfirmedAt = _clock();
      entry.failure = null;
      entry.phase = values.isEmpty ? BudgetPhase.empty : BudgetPhase.ready;
    } catch (error) {
      if (!_currentBudget(entry, generation)) return;
      if (error is DataFailure &&
          (error.kind == DataFailureKind.sessionChanged ||
              error.kind == DataFailureKind.unauthenticated)) {
        _invalidateSession();
        return;
      }
      if (!identical(_budgetCache[entry.month], entry)) return;
      entry.failure = _mapFailure(error);
      if (entry.failure!.kind == DataFailureKind.permissionDenied ||
          entry.failure!.kind == DataFailureKind.invalidData) {
        entry.limits = null;
        entry.lastConfirmedAt = null;
      }
      entry.phase = BudgetPhase.error;
    }
    if (_sameSession && identical(_budgetCache[entry.month], entry)) {
      notifyListeners();
    }
  }

  Future<BudgetSubmissionResult> saveBudgetLimits({
    required FinancialMonth month,
    required Map<Category, int> limits,
    Map<Category, int>? expectedLimits,
  }) => _submitBudgetChanges(
    month,
    Map<Category, int?>.from(limits),
    expectedLimits: expectedLimits,
  );

  Future<BudgetSubmissionResult> removeBudgetLimit({
    required FinancialMonth month,
    required Category category,
    Map<Category, int>? expectedLimits,
  }) => _submitBudgetChanges(month, {
    category: null,
  }, expectedLimits: expectedLimits);

  void _reconcileBudgetSnapshot(
    FinancialMonth month,
    List<MonthlyBudget> values,
  ) {
    final expected = _pendingBudgetChanges[month];
    if (expected == null) return;
    final actual = {
      for (final value in values) value.category: value.limitCents,
    };
    if (!expected.entries.every((entry) => actual[entry.key] == entry.value)) {
      throw const DataFailure(
        DataFailureKind.unavailable,
        'Não foi possível confirmar o resultado dos limites. Atualize e confira os dados; não reenvie a alteração.',
      );
    }
    final previous = _budgetResults[month]!;
    final confirmed = {...previous.confirmed, ...expected};
    final pending = {...previous.pending}
      ..removeWhere((key, _) => expected.containsKey(key));
    _pendingBudgetChanges.remove(month);
    _budgetResults[month] = BudgetSubmissionResult(
      month: month,
      status: pending.isEmpty
          ? BudgetSubmissionStatus.confirmed
          : BudgetSubmissionStatus.partial,
      confirmed: confirmed,
      pending: pending,
      failure: pending.isEmpty ? null : previous.failure,
    );
  }

  Future<BudgetSubmissionResult> _submitBudgetChanges(
    FinancialMonth month,
    Map<Category, int?> proposed, {
    Map<Category, int>? expectedLimits,
  }) async {
    BudgetSubmissionResult result(
      BudgetSubmissionStatus status, [
      DataFailure? failure,
    ]) => BudgetSubmissionResult(
      month: month,
      status: status,
      pending: status == BudgetSubmissionStatus.sessionInvalidated
          ? const {}
          : proposed,
      failure: failure,
    );
    if (!_sameSession) {
      _invalidateSession();
      return result(BudgetSubmissionStatus.sessionInvalidated);
    }
    if (_submitting) return result(BudgetSubmissionStatus.busy);
    if (hasPendingBudgetChanges ||
        hasPendingRefresh ||
        _requiresReconciliation) {
      return _budgetResults[month] ??
          result(
            BudgetSubmissionStatus.uncertain,
            const DataFailure(
              DataFailureKind.unavailable,
              'Atualize e confira os dados antes de outra alteração.',
            ),
          );
    }
    final changes = <Category, int?>{};
    try {
      // Valida o rascunho inteiro antes de iniciar qualquer escrita.
      for (final entry in proposed.entries) {
        if (entry.key.type != TransactionType.expense) {
          throw const FormatException('Categoria inválida');
        }
        if (entry.value case final cents?) {
          Money.requireSafeCents(cents);
          if (cents <= 0) {
            throw const FormatException('Limite deve ser positivo');
          }
        }
      }
      if (!canEditBudgets(month)) {
        throw const DataFailure(
          DataFailureKind.unavailable,
          'Carregue os limites confirmados antes de editar.',
        );
      }
      final existing = {
        for (final value in _budgetCache[month]!.limits!)
          value.category: value.limitCents,
      };
      for (final category in Category.forType(TransactionType.expense)) {
        if (!proposed.containsKey(category)) continue;
        if (expectedLimits != null &&
            expectedLimits[category] != existing[category]) {
          throw const DataFailure(
            DataFailureKind.invalidData,
            'Os limites mudaram. Atualize os dados e reabra o editor.',
          );
        }
        final value = proposed[category];
        if (value == null && !existing.containsKey(category)) {
          throw const DataFailure(
            DataFailureKind.notFound,
            'Limite não encontrado. Atualize os dados.',
          );
        }
        if (existing[category] != value) changes[category] = value;
      }
    } catch (error) {
      return result(BudgetSubmissionStatus.failed, _mapFailure(error));
    }
    if (changes.isEmpty) {
      final unchanged = BudgetSubmissionResult(
        month: month,
        status: BudgetSubmissionStatus.confirmed,
      );
      _budgetResults[month] = unchanged;
      return unchanged;
    }
    final version = ++_submissionVersion;
    bool current() => _sameSession && version == _submissionVersion;
    _submitting = true;
    _budgetWriting = true;
    final done = Completer<void>();
    _submissionDone = done;
    final confirmed = <Category, int?>{};
    final pending = {...changes};
    final uncertain = <Category>{};
    DataFailure? failure;
    notifyListeners();
    try {
      for (final entry in changes.entries) {
        if (!current()) {
          return result(BudgetSubmissionStatus.sessionInvalidated);
        }
        try {
          if (entry.value case final cents?) {
            await _budgetRepository!.save(
              month: month,
              category: entry.key,
              limitCents: cents,
              expectedUserId: expectedUserId,
            );
          } else {
            await _budgetRepository!.remove(
              month: month,
              category: entry.key,
              expectedUserId: expectedUserId,
            );
          }
          if (!current()) {
            return result(BudgetSubmissionStatus.sessionInvalidated);
          }
          confirmed[entry.key] = entry.value;
          pending.remove(entry.key);
          (_pendingBudgetChanges[month] ??= {})[entry.key] = entry.value;
        } catch (error) {
          if (!current()) {
            return result(BudgetSubmissionStatus.sessionInvalidated);
          }
          failure = _mapFailure(error);
          if (failure.kind == DataFailureKind.sessionChanged ||
              failure.kind == DataFailureKind.unauthenticated) {
            _invalidateSession();
            return result(BudgetSubmissionStatus.sessionInvalidated);
          }
          if (failure.kind == DataFailureKind.unavailable ||
              failure.kind == DataFailureKind.unknown) {
            uncertain.add(entry.key);
            (_pendingBudgetChanges[month] ??= {})[entry.key] = entry.value;
          }
          break;
        }
      }
      var status = failure == null
          ? BudgetSubmissionStatus.confirmed
          : uncertain.isNotEmpty
          ? BudgetSubmissionStatus.uncertain
          : confirmed.isNotEmpty
          ? BudgetSubmissionStatus.partial
          : BudgetSubmissionStatus.failed;
      if (_pendingBudgetChanges.containsKey(month) &&
          uncertain.isEmpty &&
          pending.isEmpty) {
        status = BudgetSubmissionStatus.refreshPending;
      }
      _budgetResults[month] = BudgetSubmissionResult(
        month: month,
        status: status,
        confirmed: confirmed,
        pending: pending,
        uncertain: uncertain,
        needsRead: _pendingBudgetChanges.containsKey(month),
        failure: failure,
      );
      _budgetWriting = false;
      if (_pendingBudgetChanges.containsKey(month)) {
        await refreshBudgets(month: month);
      }
      if (!current()) return result(BudgetSubmissionStatus.sessionInvalidated);
      final stored = _budgetResults[month]!;
      if (stored.needsRead) {
        _budgetResults[month] = BudgetSubmissionResult(
          month: month,
          status: stored.status,
          confirmed: stored.confirmed,
          pending: stored.pending,
          uncertain: stored.uncertain,
          needsRead: true,
          failure: budgetStateFor(month).failure ?? stored.failure,
        );
      }
      return _budgetResults[month]!;
    } finally {
      _budgetWriting = false;
      _submitting = false;
      if (identical(_submissionDone, done)) _submissionDone = null;
      done.complete();
      if (!_disposed) notifyListeners();
    }
  }

  void _clearBudgets() {
    for (final entry in {..._budgetCache.values, ..._budgetFlights.values}) {
      entry.generation++;
      entry.limits = null;
      entry.summary = null;
      entry.failure = null;
      entry.projectionFailure = null;
      entry.lastConfirmedAt = null;
    }
    _budgetCache.clear();
    _budgetFlights.clear();
    _pendingBudgetChanges.clear();
    _budgetResults.clear();
    _manualBudgetMonth = false;
    _selectedBudgetMonth = FinancialMonth.fromDate(_clock());
    _budgetsRequested = false;
  }

  @override
  void notifyListeners() {
    // Projeções derivadas somente nas publicações, nunca nos widgets/getters.
    for (final entry in _budgetCache.values) {
      entry.summary = null;
      entry.projectionFailure = null;
      if (!_sameSession || _summary == null || entry.limits == null) continue;
      try {
        entry.summary = FinancialCalculator.summarize(
          userId: expectedUserId,
          month: entry.month,
          transactions: _transactions,
          budgets: entry.limits!,
        );
      } catch (error) {
        entry.projectionFailure = _mapFailure(error);
      }
    }
    if (!_disposed) super.notifyListeners();
  }

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
    _clearBudgets();
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
    if (_requiresReconciliation ||
        hasPendingRefresh ||
        hasPendingBudgetChanges) {
      return TransactionSubmissionResult(
        TransactionSubmissionStatus.uncertain,
        failure: DataFailure(
          DataFailureKind.unavailable,
          hasPendingBudgetChanges
              ? 'Atualize e confira os limites de orçamento antes de iniciar outra movimentação.'
              : 'Atualize e confira o histórico antes de iniciar outro lançamento.',
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
    _clearBudgets();
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

final class _BudgetEntry {
  _BudgetEntry(this.month);
  final FinancialMonth month;
  BudgetPhase phase = BudgetPhase.idle;
  int generation = 0;
  List<MonthlyBudget>? limits;
  FinancialSummary? summary;
  DataFailure? failure, projectionFailure;
  DateTime? lastConfirmedAt;
  Future<void>? inFlight;
}
