import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/services/money.dart';

enum TransactionAction { edit, delete }

/// Seleciona uma ação; a exclusão ainda exige confirmação em diálogo próprio.
class TransactionActionsSheet extends StatelessWidget {
  const TransactionActionsSheet({required this.transaction, super.key});
  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.base,
      0,
      AppSpacing.base,
      AppSpacing.base,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          transaction.description,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${transaction.category.label} · ${Money.formatCents(transaction.amountCents)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
          title: const Text('Editar'),
          onTap: () => Navigator.of(context).pop(TransactionAction.edit),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: const Text('Excluir'),
          onTap: () => Navigator.of(context).pop(TransactionAction.delete),
        ),
      ],
    ),
  );
}
