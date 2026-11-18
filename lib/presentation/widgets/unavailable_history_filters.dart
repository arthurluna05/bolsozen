import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/financial_visual_tokens.dart';

class UnavailableHistoryFilters extends StatelessWidget {
  const UnavailableHistoryFilters({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    enabled: false,
    label:
        'Busca e filtros disponíveis no M6. Todas as transações são exibidas.',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.field),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Buscar transação…',
                        style: Theme.of(context).textTheme.bodySmall!
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.md),
              child: Icon(Icons.tune, size: 24, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Builder(
          builder: (context) {
            final pills = <Widget>[
              for (final (label, background, foreground) in [
                ('Todas', AppColors.primary, AppColors.surface),
                ('Receitas', AppColors.mintSurface, AppColors.primary),
                (
                  'Despesas',
                  FinancialVisualTokens.foodSurface,
                  FinancialVisualTokens.expenseText,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(color: foreground),
                      ),
                    ),
                  ),
                ),
            ];
            if (MediaQuery.textScalerOf(context).scale(12) > 18) {
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: pills,
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final pill in pills) Expanded(child: pill)],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Busca e filtros disponíveis no M6.',
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
