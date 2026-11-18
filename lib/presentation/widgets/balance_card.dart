import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/services/money.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.balanceCents, super.key});
  final int balanceCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      shadowColor: theme.colorScheme.onSurface.withValues(alpha: 0.16),
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
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
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
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          Money.formatCents(balanceCents),
                          key: const ValueKey('global-balance'),
                          style: theme.textTheme.headlineLarge!.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Tooltip(
                    message: 'Ocultar saldo disponível no M6.',
                    child: Semantics(
                      label: 'Ocultar saldo disponível no M6.',
                      button: true,
                      enabled: false,
                      excludeSemantics: true,
                      child: IconButton(
                        onPressed: null,
                        disabledColor: theme.colorScheme.onPrimary,
                        style: IconButton.styleFrom(
                          disabledBackgroundColor:
                              FinancialVisualTokens.balanceEnd,
                          backgroundColor: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.08),
                          shape: const CircleBorder(),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                      ),
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
