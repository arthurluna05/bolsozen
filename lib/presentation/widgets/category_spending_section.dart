import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/financial_summary.dart';
import '../services/financial_projection.dart';
import 'category_icon.dart';
import 'unavailable_financial_action.dart';

class CategorySpendingSection extends StatelessWidget {
  const CategorySpendingSection({
    required this.summary,
    this.onViewReports,
    super.key,
  });
  final FinancialSummary summary;
  final VoidCallback? onViewReports;

  @override
  Widget build(BuildContext context) {
    final spending = FinancialProjection.spending(summary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Gastos por categoria',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (onViewReports != null)
              TextButton(
                onPressed: onViewReports,
                child: const Text('Ver mais ›'),
              )
            else
              const UnavailableFinancialAction(
                label: 'Ver mais',
                availability: 'Abra Relatórios para o detalhamento.',
              ),
          ],
        ),
        if (spending.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text('Nenhuma despesa nesta competência.'),
          ),
        for (final item in spending)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Semantics(
              label:
                  '${item.category.label}, ${item.percentage} das despesas do mês',
              excludeSemantics: true,
              child: Row(
                children: [
                  CategoryIcon(
                    category: item.category,
                    spendingBreakdown: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.category.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.field),
                          child: LinearProgressIndicator(
                            value: item.proportion,
                            minHeight: 8,
                            color: context.colors.secondary,
                            backgroundColor: context.colors.surfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    item.percentage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
