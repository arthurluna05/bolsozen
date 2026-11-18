import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/firebase/data_failure.dart';
import '../../domain/models/financial_transaction.dart';
import '../../domain/services/money.dart';
import '../controllers/financial_controller.dart';

class DeleteTransactionDialog extends StatefulWidget {
  const DeleteTransactionDialog({
    required this.controller,
    required this.transaction,
    super.key,
  });
  final FinancialController controller;
  final FinancialTransaction transaction;

  @override
  State<DeleteTransactionDialog> createState() =>
      _DeleteTransactionDialogState();
}

class _DeleteTransactionDialogState extends State<DeleteTransactionDialog> {
  bool _sending = false, _reading = false;
  TransactionSubmissionResult? _result;
  bool get _readOnly =>
      _result?.status == TransactionSubmissionStatus.refreshPending ||
      _result?.status == TransactionSubmissionStatus.uncertain ||
      _result?.failure?.kind == DataFailureKind.notFound;

  Future<void> _delete() async {
    if (_sending || _reading || _readOnly || widget.controller.isSubmitting) {
      return;
    }
    setState(() => _sending = true);
    final result = await widget.controller.deleteTransaction(
      widget.transaction,
    );
    if (!mounted ||
        widget.controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    setState(() {
      _sending = false;
      _result = result;
    });
    if (result.status == TransactionSubmissionStatus.confirmed) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _refresh() async {
    if (_sending || _reading || widget.controller.isSubmitting) return;
    setState(() => _reading = true);
    await widget.controller.refresh();
    if (!mounted ||
        widget.controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    setState(() => _reading = false);
    // notFound é um erro específico, não vira sucesso porque o ID está ausente.
    if (_result?.failure?.kind != DataFailureKind.notFound &&
        widget.controller.confirmsDeletion(widget.transaction)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      if (widget.controller.phase == FinancialPhase.sessionInvalidated ||
          widget.transaction.userId != widget.controller.expectedUserId) {
        return const AlertDialog(
          content: Text('Sua sessão mudou. Feche esta confirmação.'),
        );
      }
      final busy = _sending || _reading;
      final receipt = _result;
      return AlertDialog(
        title: const Text('Excluir transação?'),
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.base),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.transaction.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(Money.formatCents(widget.transaction.amountCents)),
            const SizedBox(height: AppSpacing.base),
            const Text('A exclusão não poderá ser desfeita.'),
            if (busy) ...[
              const SizedBox(height: AppSpacing.base),
              LinearProgressIndicator(
                semanticsLabel: _reading
                    ? 'Atualizando histórico'
                    : 'Excluindo transação',
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _reading ? 'Atualizando dados…' : 'Exclusão em andamento. Fechar não cancela a operação já enviada.',
              ),
            ],
            if (receipt != null &&
                receipt.status != TransactionSubmissionStatus.busy) ...[
              const SizedBox(height: AppSpacing.base),
              Semantics(
                liveRegion: true,
                child: Text(switch (receipt.status) {
                  TransactionSubmissionStatus.refreshPending => 'Transação excluída; não foi possível atualizar o histórico. Atualize sem excluir novamente.',
                  TransactionSubmissionStatus.uncertain => 'Não foi possível confirmar a exclusão. Atualize e confira o histórico; a exclusão não será reenviada automaticamente.',
                  _ =>
                    receipt.failure?.message ??
                        'Não foi possível excluir. Tente novamente.',
                }),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('delete-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(busy || _readOnly ? 'Fechar' : 'Cancelar'),
          ),
          if (_readOnly)
            FilledButton(
              key: const ValueKey('delete-read'),
              onPressed: busy || widget.controller.isSubmitting
                  ? null
                  : _refresh,
              child: const Text('Atualizar dados'),
            )
          else
            FilledButton(
              key: const ValueKey('delete-confirm'),
              onPressed: busy || widget.controller.isSubmitting
                  ? null
                  : _delete,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.onError,
              ),
              child: const Text('Excluir'),
            ),
        ],
      );
    },
  );
}
