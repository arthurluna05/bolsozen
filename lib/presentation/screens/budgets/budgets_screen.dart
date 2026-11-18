import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/financial_summary.dart';
import '../../../domain/services/money.dart';
import '../../controllers/financial_controller.dart';
import '../../controllers/budget_month_state.dart';
import '../../services/budget_presentation.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/financial_month_selector.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({required this.controller, this.onEditLimits, super.key});
  final FinancialController controller;
  final VoidCallback? onEditLimits;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.phase == FinancialPhase.sessionInvalidated) {
        return const SizedBox.shrink();
      }
      final state = controller.selectedBudgetState;
      final summary = state.summary;
      final usages = summary?.budgetByCategory ?? <Category, BudgetUsage>{};
      final alerts = usages.entries.where(
        (entry) => entry.value.status != BudgetStatus.normal,
      );
      final busy =
          state.phase == BudgetPhase.loading ||
          state.phase == BudgetPhase.refreshing;
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshFinancialData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                Text(
                  'Orçamento mensal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.base),
                FinancialMonthSelector(
                  month: state.month,
                  onChanged: controller.selectBudgetMonth,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!state.available)
                  const Text('Orçamento indisponível nesta sessão.')
                else ...[
                  if (busy) ...[
                    const LinearProgressIndicator(
                      semanticsLabel: 'Carregando limites',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (state.failure != null || state.isStale) ...[
                    _Notice(
                      text: state.failure?.message ?? 'Atualização pendente. Os dados podem estar desatualizados.',
                    ),
                    TextButton(
                      onPressed: busy ? null : controller.refreshFinancialData,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                  if (!state.hasConfirmedLimits &&
                      !busy &&
                      state.failure == null)
                    const Text('Aguardando a leitura dos limites.'),
                  if (state.hasConfirmedLimits && summary == null) ...[
                    const Text(
                      'Aguardando histórico completo para calcular o consumo.',
                    ),
                    if (!busy)
                      TextButton(
                        onPressed: controller.refreshFinancialData,
                        child: const Text('Atualizar dados'),
                      ),
                  ],
                  if (state.hasConfirmedLimits && state.limits!.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text(
                        'Sem limites configurados para este mês. Defina limites por categoria para acompanhar seu orçamento.',
                      ),
                    ),
                  if (summary != null) ...[
                    for (final alert in alerts)
                      _Notice(
                        text:
                            'A categoria ${alert.key.label} já usou ${BudgetPresentation.percentage(alert.value)} do limite do mês. ${BudgetPresentation.status(alert.value)}.',
                        critical: alert.value.status == BudgetStatus.reached,
                      ),
                    for (final category in Category.forType(
                      TransactionType.expense,
                    ))
                      if (usages[category] case final usage?)
                        _BudgetCard(category: category, usage: usage),
                    if (summary.expensesByCategory.entries.any(
                      (entry) =>
                          entry.value > 0 && !usages.containsKey(entry.key),
                    )) ...[
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        'Sem limite',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final entry in summary.expensesByCategory.entries)
                        if (entry.value > 0 && !usages.containsKey(entry.key))
                          _BudgetCard(category: entry.key, spent: entry.value),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed:
                        state.hasConfirmedLimits && !controller.isSubmitting
                        ? onEditLimits
                        : null,
                    icon: Icon(Icons.edit_outlined),
                    label: const Text('Editar limites'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.critical = false});
  final String text;
  final bool critical;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: (critical ? context.colors.error : context.colors.warning)
          .withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadii.field),
      border: Border.all(
        color: (critical ? context.colors.error : context.colors.warning)
            .withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_rounded,
          color: critical ? context.colors.error : context.colors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atenção!', style: Theme.of(context).textTheme.labelLarge),
              Text(text, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.category, this.usage, this.spent});
  final Category category;
  final BudgetUsage? usage;
  final int? spent;

  @override
  Widget build(BuildContext context) {
    final value = usage;
    final color = switch (value?.status) {
      BudgetStatus.reached => context.colors.error,
      BudgetStatus.attention => context.colors.warning,
      _ => context.colors.primary,
    };
    final amount = Money.formatCents(value?.consumedCents ?? spent!);
    final percentage = value == null
        ? null
        : BudgetPresentation.percentage(value);
    final ring = value == null
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ExcludeSemantics(
                      child: SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: BudgetPresentation.progress(value),
                          strokeWidth: 5,
                          color: color,
                          backgroundColor: context.colors.border,
                        ),
                      ),
                    ),
                    if (percentage!.length <= 6)
                      Text(
                        percentage,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                  ],
                ),
              ),
              if (percentage.length > 6)
                Text(
                  percentage,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          );
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                MediaQuery.textScalerOf(context).scale(14) > 20 ||
                (percentage?.length ?? 0) > 8;
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  value == null
                      ? '$amount • Sem limite'
                      : '$amount de ${Money.formatCents(value.limitCents)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (value != null)
                  Text(
                    BudgetPresentation.status(value),
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(color: context.colors.textSecondary),
                  ),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CategoryIcon(category: category, budgetContext: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: details),
                    if (!stacked && ring != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ring,
                    ],
                  ],
                ),
                if (stacked && ring != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Align(alignment: Alignment.centerRight, child: ring),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
