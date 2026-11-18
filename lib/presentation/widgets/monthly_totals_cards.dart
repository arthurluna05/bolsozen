import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/models/financial_summary.dart';
import '../../domain/services/money.dart';

class MonthlyTotalsCards extends StatelessWidget {
  const MonthlyTotalsCards({required this.totals, super.key});
  final MonthlyTotals totals;

  @override
  Widget build(BuildContext context) {
    final income = Money.formatCents(totals.incomeCents);
    final expense = Money.formatCents(totals.expenseCents);
    final cards = [
      _TotalCard(
        label: 'Receitas',
        value: income,
        color: AppColors.primary,
        icon: Icons.arrow_upward,
      ),
      _TotalCard(
        label: 'Despesas',
        value: expense,
        color: FinancialVisualTokens.expenseText,
        icon: Icons.arrow_downward,
      ),
      const _TotalCard(
        label: 'Meta do mês',
        value: 'Em breve',
        color: AppColors.textSecondary,
        icon: Icons.track_changes_outlined,
        iconColor: AppColors.warning,
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
              Expanded(
                child: Tooltip(
                  message: 'Orçamento indisponível até o M7; nenhum limite foi consultado.',
                  child: cards[2],
                ),
              ),
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
  });
  final String label, value;
  final Color color;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Card(
    shadowColor: AppColors.textPrimary.withValues(alpha: 0.16),
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
        ],
      ),
    ),
  );
}
