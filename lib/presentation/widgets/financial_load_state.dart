import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../controllers/financial_controller.dart';

/// A tela já observa o controller; não inicia leituras durante build.
class FinancialLoadState extends StatelessWidget {
  const FinancialLoadState({required this.controller, super.key});
  final FinancialController controller;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    if (phase == FinancialPhase.ready) return const SizedBox.shrink();
    final message = switch (phase) {
      FinancialPhase.idle => 'Carregue seus dados financeiros.',
      FinancialPhase.loading => 'Carregando histórico completo…',
      FinancialPhase.refreshing => 'Atualizando dados…',
      FinancialPhase.empty => 'Nenhuma transação ainda.',
      FinancialPhase.error => controller.failure!.message,
      FinancialPhase.sessionInvalidated =>
        'Sessão alterada. Os dados financeiros foram ocultados.',
      FinancialPhase.ready => '',
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.isLoading) ...[
              const LinearProgressIndicator(
                semanticsLabel: 'Carregamento financeiro',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (phase == FinancialPhase.empty)
              const Icon(Icons.account_balance_wallet_outlined, size: 32),
            Text(message, textAlign: TextAlign.center),
            if (controller.isStale) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Dados da última carga; podem estar desatualizados.',
                textAlign: TextAlign.center,
              ),
            ],
            if (phase == FinancialPhase.error ||
                phase == FinancialPhase.idle) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                child: OutlinedButton(
                  onPressed: controller.retry,
                  child: Text(
                    phase == FinancialPhase.idle
                        ? 'Carregar dados'
                        : 'Tentar novamente',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
