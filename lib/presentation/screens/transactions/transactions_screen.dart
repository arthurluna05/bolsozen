import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/financial_transaction.dart';
import '../../../domain/models/category.dart';
import '../../controllers/financial_controller.dart';
import '../../widgets/financial_load_state.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/history_filters.dart';
import '../../widgets/history_category_dialog.dart';
import '../../services/financial_projection.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    required this.controller,
    this.today,
    this.clock,
    this.onAddTransaction,
    this.onTransactionActions,
    super.key,
  });
  final FinancialController controller;
  final DateTime? today;
  final DateTime Function()? clock;
  final VoidCallback? onAddTransaction;
  final ValueChanged<FinancialTransaction>? onTransactionActions;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with WidgetsBindingObserver {
  final _query = TextEditingController();
  final _searchFocus = FocusNode(), _filterFocus = FocusNode();
  TransactionType? _type;
  Category? _category;
  Timer? _dayTimer;
  bool _active = true;
  int _modalVersion = 0;
  FinancialController get controller => widget.controller;
  VoidCallback? get onAddTransaction => widget.onAddTransaction;
  ValueChanged<FinancialTransaction>? get onTransactionActions =>
      widget.onTransactionActions;
  DateTime get _now =>
      (widget.today ?? widget.clock?.call() ?? DateTime.now()).toLocal();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onFinancial);
    _scheduleDay();
  }

  void _reset() {
    _query.clear();
    _type = null;
    _category = null;
  }

  void _onFinancial() {
    if (controller.phase == FinancialPhase.sessionInvalidated) {
      _modalVersion++;
      _dayTimer?.cancel();
      _reset();
    }
  }

  void _scheduleDay() {
    _dayTimer?.cancel();
    if (!_active ||
        widget.today != null ||
        controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    final now = _now;
    final delay = DateTime(now.year, now.month, now.day + 1).difference(now);
    _dayTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted || controller.phase == FinancialPhase.sessionInvalidated) {
        return;
      }
      setState(() {});
      _scheduleDay();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) setState(() {});
    _scheduleDay();
  }

  @override
  void didUpdateWidget(covariant TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_onFinancial);
      controller.addListener(_onFinancial);
      _modalVersion++;
      _reset();
    }
    _scheduleDay();
  }

  Future<void> _openCategory() async {
    if (controller.phase == FinancialPhase.sessionInvalidated) return;
    final version = _modalVersion;
    _searchFocus.unfocus();
    final selection = await showDialog<HistoryCategorySelection>(
      context: context,
      useRootNavigator: false,
      builder: (_) => HistoryCategoryDialog(type: _type, category: _category),
    );
    if (!mounted ||
        version != _modalVersion ||
        controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    if (selection != null) {
      setState(() {
        if (selection.clearAll) {
          _reset();
        } else {
          _category = selection.category;
        }
      });
    }
    _filterFocus.requestFocus();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    _modalVersion++;
    controller.removeListener(_onFinancial);
    WidgetsBinding.instance.removeObserver(this);
    _query.dispose();
    _searchFocus.dispose();
    _filterFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final filtered = FinancialProjection.filterHistory(
        controller.transactions,
        query: _query.text,
        type: _type,
        category: _category,
      );
      final rows = FinancialProjection.historyRows(filtered, today: _now);
      final showFilters = controller.phase != FinancialPhase.sessionInvalidated;
      final noResults =
          controller.phase == FinancialPhase.ready &&
          !controller.isStale &&
          controller.transactions.isNotEmpty &&
          filtered.isEmpty;
      final emptyAction =
          controller.phase == FinancialPhase.empty && onAddTransaction != null;
      return Scaffold(
        floatingActionButton: showFilters && onAddTransaction != null
            ? FloatingActionButton(
                onPressed: onAddTransaction,
                tooltip: 'Adicionar transação',
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Transações',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: FinancialLoadState(controller: controller),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: AppSpacing.base,
                      right: AppSpacing.base,
                      bottom: onAddTransaction != null ? 88 : 0,
                    ),
                    itemCount:
                        rows.length +
                        (showFilters ? 1 : 0) +
                        (noResults || emptyAction ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showFilters && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: HistoryFilters(
                            query: _query,
                            searchFocus: _searchFocus,
                            filterFocus: _filterFocus,
                            type: _type,
                            category: _category,
                            onQueryChanged: (_) => setState(() {}),
                            onTypeChanged: (value) => setState(() {
                              _type = value;
                              if (value != null && _category?.type != value) {
                                _category = null;
                              }
                            }),
                            onCategory: _openCategory,
                          ),
                        );
                      }
                      if (index - (showFilters ? 1 : 0) == rows.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Column(
                            children: [
                              if (noResults) ...[
                                const Text('Nenhuma transação encontrada'),
                                TextButton(
                                  key: const ValueKey('history-clear-results'),
                                  onPressed: () => setState(_reset),
                                  child: const Text('Limpar filtros'),
                                ),
                              ] else
                                OutlinedButton(
                                  onPressed: onAddTransaction,
                                  child: const Text('Adicionar movimentação'),
                                ),
                            ],
                          ),
                        );
                      }
                      final row = rows[index - (showFilters ? 1 : 0)];
                      if (row.heading case final heading?) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(
                              heading,
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        );
                      }
                      final transaction = row.transaction!;
                      return Padding(
                        key: ValueKey(transaction.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TransactionTile(
                          transaction: transaction,
                          showDate: false,
                          emphasized: true,
                          onTap:
                              onTransactionActions != null &&
                                  controller.canEdit(transaction)
                              ? () => onTransactionActions!(transaction)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
