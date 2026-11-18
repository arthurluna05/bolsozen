import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../controllers/financial_controller.dart';
import '../../widgets/financial_load_state.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/unavailable_history_filters.dart';
import '../../services/financial_projection.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({
    required this.controller,
    this.today,
    this.onAddTransaction,
    super.key,
  });
  final FinancialController controller;
  final DateTime? today;
  final VoidCallback? onAddTransaction;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final rows = FinancialProjection.historyRows(
        controller.transactions,
        today: today ?? DateTime.now(),
      );
      final showFilters = controller.phase != FinancialPhase.sessionInvalidated;
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
                    itemCount: rows.length + (showFilters ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showFilters && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: UnavailableHistoryFilters(),
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
