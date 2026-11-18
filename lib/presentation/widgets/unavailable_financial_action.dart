import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Preserva a composição da prancha, com estado indisponível explícito.
class UnavailableFinancialAction extends StatelessWidget {
  const UnavailableFinancialAction({
    required this.label,
    required this.availability,
    super.key,
  });
  final String label, availability;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: availability,
    child: Semantics(
      label: '$label. $availability',
      button: true,
      enabled: false,
      excludeSemantics: true,
      child: TextButton(
        onPressed: null,
        style: TextButton.styleFrom(
          disabledForegroundColor: AppColors.primary,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        child: Text('$label ›'),
      ),
    ),
  );
}
