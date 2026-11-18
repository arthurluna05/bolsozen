import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/models/category.dart';

typedef HistoryCategorySelection = ({Category? category, bool clearAll});

class HistoryCategoryDialog extends StatefulWidget {
  const HistoryCategoryDialog({
    required this.type,
    required this.category,
    super.key,
  });
  final TransactionType? type;
  final Category? category;
  @override
  State<HistoryCategoryDialog> createState() => _HistoryCategoryDialogState();
}

class _HistoryCategoryDialogState extends State<HistoryCategoryDialog> {
  late Category? _draft = widget.category;
  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('history-category-dialog'),
    title: const Text('Filtrar por categoria'),
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
    ),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Category>(
          key: const ValueKey('history-category-choice'),
          initialValue: _draft,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoria'),
          hint: const Text('Todas'),
          items: [
            const DropdownMenuItem<Category>(value: null, child: Text('Todas')),
            for (final value
                in widget.type == null
                    ? Category.values
                    : Category.forType(widget.type!))
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) => setState(() => _draft = value),
        ),
        const SizedBox(height: AppSpacing.base),
        const Text(
          'Limpar filtros remove a pesquisa e as seleções de tipo e categoria.',
        ),
      ],
    ),
    actions: [
      TextButton(
        key: const ValueKey('history-category-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      TextButton(
        key: const ValueKey('history-clear-all'),
        onPressed: () => Navigator.of(context)
            .pop<HistoryCategorySelection>((category: null, clearAll: true)),
        child: const Text('Limpar filtros'),
      ),
      FilledButton(
        key: const ValueKey('history-category-apply'),
        onPressed: () => Navigator.of(context)
            .pop<HistoryCategorySelection>((category: _draft, clearAll: false)),
        child: const Text('Aplicar'),
      ),
    ],
  );
}
