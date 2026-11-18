import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/financial_visual_tokens.dart';
import '../../../domain/models/category.dart';
import '../../../domain/services/money.dart';
import '../../../domain/services/transaction_validation.dart';
import '../../controllers/financial_controller.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/submit_button.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    required this.controller,
    this.clock,
    super.key,
  });
  final FinancialController controller;
  final DateTime Function()? clock;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _description = TextEditingController(),
      _dateText = TextEditingController();
  final _amountFocus = FocusNode(),
      _categoryFocus = FocusNode(),
      _descriptionFocus = FocusNode();
  TransactionType _type = TransactionType.expense;
  Category? _category;
  late DateTime _date;
  TransactionSubmissionResult? _result;
  bool _refreshing = false;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  bool get _locked =>
      widget.controller.isSubmitting ||
      _refreshing ||
      _result?.status == TransactionSubmissionStatus.confirmed ||
      _result?.status == TransactionSubmissionStatus.refreshPending ||
      _result?.status == TransactionSubmissionStatus.uncertain;

  @override
  void initState() {
    super.initState();
    final now = _now.toLocal();
    _date = DateTime(now.year, now.month, now.day);
    _updateDateText();
  }

  void _updateDateText() {
    // Data de calendário local; não é campo editável ou string persistida.
    _dateText.text = DateFormat('dd/MM/yyyy', 'pt_BR').format(_date);
  }

  Future<void> _pickDate() async {
    if (_locked) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      currentDate: _now,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (!mounted ||
        _locked ||
        widget.controller.phase == FinancialPhase.sessionInvalidated ||
        date == null) {
      return;
    }
    setState(() {
      _date = date;
      _updateDateText();
    });
  }

  Future<void> _submit() async {
    if (_locked) return;
    if (!_form.currentState!.validate()) {
      if (TransactionValidation.amount(_amount.text) != null) {
        _amountFocus.requestFocus();
      } else if (TransactionValidation.category(_category, _type) != null) {
        _categoryFocus.requestFocus();
      } else {
        _descriptionFocus.requestFocus();
      }
      return;
    }
    FocusScope.of(context).unfocus();
    final result = await widget.controller.createTransaction(
      type: _type,
      amountCents: Money.parseCents(_amount.text),
      category: _category!,
      description: _description.text,
      occurredAt: _date,
    );
    if (!mounted ||
        widget.controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    if (result.status == TransactionSubmissionStatus.busy) return;
    setState(() => _result = result);
    _closeOnConfirmed(result.status);
  }

  void _closeOnConfirmed(TransactionSubmissionStatus status) {
    if (status == TransactionSubmissionStatus.confirmed &&
        widget.controller.phase != FinancialPhase.sessionInvalidated &&
        Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _retryRead() async {
    if (_refreshing || widget.controller.isSubmitting) return;
    setState(() => _refreshing = true);
    await widget.controller.refresh();
    if (!mounted ||
        widget.controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    setState(() {
      _refreshing = false;
      if (_result?.status == TransactionSubmissionStatus.refreshPending &&
          !widget.controller.hasPendingRefresh &&
          widget.controller.failure == null &&
          widget.controller.hasConfirmedSnapshot) {
        _result = TransactionSubmissionResult(
          TransactionSubmissionStatus.confirmed,
          id: _result!.id,
        );
      }
    });
    _closeOnConfirmed(_result!.status);
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.all(AppSpacing.md),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (controller.phase == FinancialPhase.sessionInvalidated) {
        return const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.base),
              child: Text(
                'Sua sessão mudou. Feche este formulário e entre novamente.',
              ),
            ),
          ),
        );
      }
      final receipt = _result?.status;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nova transação'),
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primary),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppSpacing.xl).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              for (final type in TransactionType.values) ...[
                                if (type == TransactionType.expense)
                                  const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Semantics(
                                    selected: _type == type,
                                    child: FilledButton.icon(
                                      key: ValueKey('type-${type.name}'),
                                      onPressed: _locked
                                          ? null
                                          : () => setState(() {
                                              _type = type;
                                              if (_category?.type != type) {
                                                _category = null;
                                              }
                                              _result = null;
                                            }),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            type == TransactionType.income
                                            ? AppColors.mintSurface
                                            : FinancialVisualTokens.foodSurface,
                                        foregroundColor:
                                            type == TransactionType.income
                                            ? AppColors.primary
                                            : FinancialVisualTokens
                                                  .expenseControlText,
                                        side: _type == type
                                            ? BorderSide(
                                                color:
                                                    type ==
                                                        TransactionType.income
                                                    ? AppColors.primary
                                                    : FinancialVisualTokens
                                                          .expenseText,
                                              )
                                            : BorderSide.none,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.sm,
                                        ),
                                      ),
                                      icon: Icon(
                                        type == TransactionType.income
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 20,
                                      ),
                                      label: Text(
                                        type == TransactionType.income
                                            ? 'Receita'
                                            : 'Despesa',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            key: const ValueKey('transaction-amount'),
                            controller: _amount,
                            focusNode: _amountFocus,
                            enabled: !_locked,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                TransactionValidation.amount(value ?? ''),
                            decoration: _decoration('Valor', Icons.attach_money)
                                .copyWith(
                                  prefixText:
                                      _amount.text.trimLeft().startsWith('R\$')
                                      ? null
                                      : 'R\$ ',
                                  hintText: '0,00',
                                  errorMaxLines: 4,
                                ),
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) =>
                                _categoryFocus.requestFocus(),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          DropdownButtonFormField<Category>(
                            key: ValueKey('transaction-category-${_type.name}'),
                            initialValue: _category,
                            focusNode: _categoryFocus,
                            isExpanded: true,
                            decoration: _decoration(
                              'Categoria',
                              _category == null
                                  ? Icons.category_outlined
                                  : CategoryIcon(category: _category!).icon,
                            ),
                            hint: const Text('Selecione'),
                            items: [
                              for (final category in Category.forType(_type))
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(category.label),
                                ),
                            ],
                            onChanged: _locked
                                ? null
                                : (value) => setState(() => _category = value),
                            validator: (value) =>
                                TransactionValidation.category(value, _type),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          TextFormField(
                            key: const ValueKey('transaction-date'),
                            controller: _dateText,
                            enabled: !_locked,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration:
                                _decoration(
                                  'Data',
                                  Icons.calendar_today_outlined,
                                ).copyWith(
                                  suffixIcon: const Icon(Icons.expand_more),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          TextFormField(
                            key: const ValueKey('transaction-description'),
                            controller: _description,
                            focusNode: _descriptionFocus,
                            enabled: !_locked,
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                TransactionValidation.description(value ?? ''),
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => _submit(),
                            decoration:
                                _decoration(
                                  'Descrição',
                                  Icons.receipt_long_outlined,
                                ).copyWith(
                                  counterText:
                                      '${_description.text.trim().runes.length}/120',
                                ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          InputDecorator(
                            decoration: _decoration(
                              'Conta',
                              Icons.account_balance_wallet_outlined,
                            ),
                            child: const Text('Conta principal'),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          if (receipt != null &&
                              receipt != TransactionSubmissionStatus.busy) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(switch (receipt) {
                                TransactionSubmissionStatus.confirmed =>
                                  'Movimentação salva e dados atualizados.',
                                TransactionSubmissionStatus.refreshPending => 'Movimentação salva; não foi possível atualizar os dados. Atualize sem salvar novamente.',
                                TransactionSubmissionStatus.uncertain =>
                                  controller.hasPendingRefresh
                                      ? 'Há uma movimentação salva aguardando atualização. Atualize os dados antes de iniciar outro lançamento.'
                                      : controller.requiresReconciliation
                                      ? 'Não foi possível confirmar a gravação. Atualize e confira o histórico antes de iniciar outro lançamento.'
                                      : 'Dados atualizados. Confira o histórico antes de iniciar outro lançamento. Este formulário não será reenviado.',
                                _ => _result!.failure?.message ?? 'Não foi possível salvar. Confira os dados e tente novamente.',
                              }),
                            ),
                            const SizedBox(height: AppSpacing.base),
                          ],
                          if (receipt ==
                                  TransactionSubmissionStatus.refreshPending ||
                              receipt == TransactionSubmissionStatus.uncertain)
                            SubmitButton(
                              label: 'Atualizar dados',
                              busy: _refreshing,
                              onPressed: _retryRead,
                            )
                          else if (receipt !=
                              TransactionSubmissionStatus.confirmed)
                            SubmitButton(
                              key: const ValueKey('transaction-submit'),
                              label: 'Salvar transação',
                              busy: controller.isSubmitting,
                              onPressed: _submit,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _dateText.dispose();
    _amountFocus.dispose();
    _categoryFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }
}
