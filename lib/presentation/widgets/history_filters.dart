import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/category.dart';

class HistoryFilters extends StatelessWidget {
  const HistoryFilters({
    required this.query,
    required this.searchFocus,
    required this.filterFocus,
    required this.type,
    required this.category,
    required this.onQueryChanged,
    required this.onTypeChanged,
    required this.onCategory,
    super.key,
  });
  final TextEditingController query;
  final FocusNode searchFocus, filterFocus;
  final TransactionType? type;
  final Category? category;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TransactionType?> onTypeChanged;
  final VoidCallback onCategory;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Buscar transações por descrição ou categoria',
              child: TextField(
                key: const ValueKey('history-search'),
                controller: query,
                focusNode: searchFocus,
                onChanged: onQueryChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchFocus.unfocus(),
                decoration: InputDecoration(
                  hintText: 'Buscar transação…',
                  isDense: true,
                  fillColor: context.colors.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.colors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: query.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('history-clear-search'),
                          tooltip: 'Limpar pesquisa',
                          onPressed: () {
                            query.clear();
                            onQueryChanged('');
                          },
                          icon: Icon(Icons.close, size: 20),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const ValueKey('history-category-filter'),
            focusNode: filterFocus,
            tooltip: category == null
                ? 'Filtrar por categoria'
                : 'Filtrar por categoria: ${category!.label}',
            onPressed: onCategory,
            style: IconButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: context.colors.primary,
              backgroundColor: category == null
                  ? null
                  : context.colors.mintSurface,
            ),
            icon: Icon(Icons.tune, size: 26),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      LayoutBuilder(
        builder: (context, constraints) {
          final style = Theme.of(context).textTheme.labelLarge!;
          final scaler = MediaQuery.textScalerOf(context);
          var widest = 0.0;
          for (final label in ['Todas', 'Receitas', 'Despesas']) {
            final painter = TextPainter(
              text: TextSpan(text: label, style: style),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            if (painter.width > widest) widest = painter.width;
            painter.dispose();
          }
          var columns = 3;
          while (columns > 1 &&
              (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns <
                  widest + 2 * AppSpacing.md + 4) {
            columns--;
          }
          final width =
              (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (value, label, background, foreground) in [
                (
                  null,
                  'Todas',
                  context.colors.primary,
                  context.colors.onPrimary,
                ),
                (
                  TransactionType.income,
                  'Receitas',
                  context.colors.mintSurface,
                  context.colors.primary,
                ),
                (
                  TransactionType.expense,
                  'Despesas',
                  context.colors.expenseSurface,
                  context.colors.expenseControlText,
                ),
              ])
                SizedBox(
                  width: width,
                  child: MergeSemantics(
                    child: Semantics(
                      selected: type == value,
                      child: FilledButton(
                        key: ValueKey('history-type-${value?.name ?? 'all'}'),
                        onPressed: () => onTypeChanged(value),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          backgroundColor: background,
                          foregroundColor: foreground,
                          textStyle: style,
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            width: 2,
                            color: type == value
                                ? value == null
                                      ? context.colors.textPrimary
                                      : foreground
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      if (category != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Categoria: ${category!.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );
}
