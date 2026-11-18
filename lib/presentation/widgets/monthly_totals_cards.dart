import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/services/money.dart';
import '../controllers/budget_month_state.dart';
import '../services/budget_presentation.dart';

class MonthlyTotalsCards extends StatelessWidget {
  const MonthlyTotalsCards({
    required this.totals,
    this.budget,
    this.onViewBudget,
    this.onRetryBudget,
    super.key,
  });
  final BudgetMonthState? budget;
  final VoidCallback? onViewBudget;
  final VoidCallback? onRetryBudget;
  final MonthlyTotals totals;

  String get _budgetLabel {
    final state = budget;
    if (state == null || !state.available) return 'Indisponível';
    if (state.failure != null) return 'Tentar novamente';
    if (!state.hasConfirmedLimits) return 'Carregando…';
    if (state.limits!.isEmpty) return 'Defina limites';
    final total = state.totalBudget;
    if (total == null) return 'Aguardando dados';
    return BudgetPresentation.percentage(total);
  }

  @override
  Widget build(BuildContext context) {
    final income = Money.formatCents(totals.incomeCents);
    final expense = Money.formatCents(totals.expenseCents);
    final cards = [
      _TotalCard(
        label: 'Receitas',
        value: income,
        color: context.colors.primary,
        icon: Icons.arrow_upward,
      ),
      _TotalCard(
        label: 'Despesas',
        value: expense,
        color: context.colors.expenseText,
        icon: Icons.arrow_downward,
      ),
      InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: budget?.failure != null ? onRetryBudget : onViewBudget,
        child: _TotalCard(
          label: 'Meta do mês',
          value: _budgetLabel,
          color: switch (budget?.totalBudget?.status) {
            BudgetStatus.reached => context.colors.error,
            BudgetStatus.attention => context.colors.textPrimary,
            _ => context.colors.primary,
          },
          icon: Icons.track_changes_outlined,
          iconColor: context.colors.warning,
          notice: budget?.isStale == true ? 'Dados desatualizados' : null,
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20 ||
            income.length > 16 ||
            expense.length > 16;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                cards[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards.first),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[1]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[2]),
            ],
          ),
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.iconColor,
    this.notice,
  });
  final String label, value;
  final String? notice;
  final Color color;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Card(
    shadowColor: context.colors.shadow.withValues(alpha: 0.16),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, color: iconColor ?? color, size: 20),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(color: color),
          ),
          if (notice != null)
            Text(notice!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}
