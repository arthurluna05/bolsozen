import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/services/money.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balanceCents,
    this.visible = true,
    this.onToggleVisibility,
    super.key,
  });
  final int balanceCents;
  final bool visible;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      shadowColor: context.colors.shadow.withValues(alpha: 0.16),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FinancialVisualTokens.balanceStart,
              FinancialVisualTokens.balanceEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: AppSpacing.lg,
              bottom: -AppSpacing.sm,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 88,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Saldo total',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Semantics(
                          label: visible
                              ? Money.formatCents(balanceCents)
                              : 'Saldo oculto',
                          excludeSemantics: true,
                          child: Text(
                            visible
                                ? Money.formatCents(balanceCents)
                                : '••••••',
                            key: const ValueKey('global-balance'),
                            style: theme.textTheme.headlineLarge!.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    key: const ValueKey('balance-visibility'),
                    tooltip: visible ? 'Ocultar saldo' : 'Mostrar saldo',
                    onPressed: onToggleVisibility,
                    color: Colors.white,
                    disabledColor: Colors.white,
                    style: IconButton.styleFrom(
                      disabledBackgroundColor: FinancialVisualTokens.balanceEnd,
                      backgroundColor: FinancialVisualTokens.balanceEnd,
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
