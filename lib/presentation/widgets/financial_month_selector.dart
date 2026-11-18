import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/financial_month.dart';

class FinancialMonthSelector extends StatelessWidget {
  const FinancialMonthSelector({
    required this.month,
    required this.onChanged,
    super.key,
  });
  final FinancialMonth month;
  final ValueChanged<FinancialMonth> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: context.colors.border),
      borderRadius: BorderRadius.circular(AppRadii.field),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          onPressed: month.year == 1 && month.month == 1
              ? null
              : () => onChanged(month.shift(-1)),
          icon: Icon(Icons.chevron_left, color: context.colors.primary),
        ),
        Icon(
          Icons.calendar_today_outlined,
          size: 20,
          color: context.colors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: 'Competência mensal',
            child: Text(
              DateFormat(
                'MMMM yyyy',
                'pt_BR',
              ).format(DateTime(month.year, month.month)),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          onPressed: month.year == 9999 && month.month == 12
              ? null
              : () => onChanged(month.shift(1)),
          icon: Icon(Icons.chevron_right, color: context.colors.primary),
        ),
      ],
    ),
  );
}
