import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/models/category.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/services/money.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    this.showDate = true,
    this.emphasized = false,
    this.onTap,
    super.key,
  });
  final FinancialTransaction transaction;
  final bool showDate;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    final value =
        '${income ? '+' : '−'} ${Money.formatCents(transaction.amountCents)}';
    final date = DateFormat(
      'dd/MM/yyyy',
      'pt_BR',
    ).format(transaction.occurredAt.toLocal());
    final theme = Theme.of(context);
    final amount = Text(
      value,
      style: theme.textTheme.labelLarge!.copyWith(
        color: income ? AppColors.primary : FinancialVisualTokens.expenseText,
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label:
          '${income ? 'Receita' : 'Despesa'}, ${transaction.description}, ${transaction.category.label}, $date, $value',
      excludeSemantics: true,
      child: Card(
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.field),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20 ||
                    value.length > 16;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: emphasized
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      showDate
                          ? '${transaction.category.label} · $date'
                          : transaction.category.label,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (stack) ...[
                      const SizedBox(height: AppSpacing.sm),
                      amount,
                    ],
                  ],
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryIcon(
                      category: transaction.category,
                      size: emphasized ? 28 : 24,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: details),
                    if (!stack) ...[
                      const SizedBox(width: AppSpacing.sm),
                      amount,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
