import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/financial_visual_tokens.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/financial_month.dart';
import '../../../domain/services/money.dart';
import '../../controllers/budget_submission_result.dart';
import '../../controllers/financial_controller.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/submit_button.dart';

/// Rota secundária privada a conectar somente no M7.5.
class BudgetEditorScreen extends StatefulWidget {
  const BudgetEditorScreen({
    required this.controller,
    required this.month,
    super.key,
  });
  final FinancialController controller;
  final FinancialMonth month;
  @override
  State<BudgetEditorScreen> createState() => _BudgetEditorScreenState();
}

class _BudgetEditorScreenState extends State<BudgetEditorScreen> {
  late final FinancialController _controller = widget.controller;
  late final FinancialMonth _month = widget.month;
  final _categories = Category.forType(TransactionType.expense);
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _texts = <Category, TextEditingController>{};
  final _focus = <Category, FocusNode>{};
  final _keys = <Category, GlobalKey>{};
  final _base = <Category, int>{};
  BudgetSubmissionResult? _result;
  bool _settingValues = false;
  bool _initialized = false,
      _invalid = false,
      _reading = false,
      _leaving = false,
      _allowPop = false,
      _closing = false;
  bool get _locked =>
      _allowPop ||
      _invalid ||
      _reading ||
      _controller.isSubmitting ||
      _result?.needsRead == true;
  bool get _dirty =>
      _initialized &&
      _categories.any((category) {
        final text = _texts[category]!.text;
        if (text.trim().isEmpty) return _base.containsKey(category);
        try {
          return Money.parseCents(text) != _base[category];
        } on FormatException {
          return true;
        }
      });

  @override
  void initState() {
    super.initState();
    for (final category in _categories) {
      _texts[category] = TextEditingController()..addListener(_draftChanged);
      _focus[category] = FocusNode();
      _keys[category] = GlobalKey();
    }
    _controller.addListener(_onController);
    _onController();
    unawaited(_controller.loadBudgets(month: _month));
  }

  void _draftChanged() {
    if (mounted && !_settingValues) {
      setState(() {
        if (_result?.needsRead != true) _result = null;
      });
    }
  }

  void _setText(Category category, String value) {
    _settingValues = true;
    _texts[category]!.text = value;
    _settingValues = false;
  }

  void _onController() {
    if (!_controller.sessionValid || widget.controller != _controller) {
      _invalid = true;
      _base.clear();
      _result = null;
      for (final text in _texts.values) {
        text.clear();
      }
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final navigator = Navigator.of(context);
          final route = ModalRoute.of(context);
          navigator.popUntil(
            (candidate) => candidate == route || candidate.isFirst,
          );
          if (mounted && route?.isCurrent == true && navigator.canPop()) {
            navigator.pop();
          }
        });
      }
      return;
    }
    final state = _controller.budgetStateFor(_month);
    if (!_initialized && state.hasConfirmedLimits) {
      _base.addAll({
        for (final value in state.limits!) value.category: value.limitCents,
      });
      for (final category in _categories) {
        _setText(
          category,
          _base[category] == null ? '' : Money.formatCents(_base[category]!),
        );
      }
      _initialized = true;
      final previous = _controller.budgetResultFor(_month);
      if (previous?.needsRead == true) {
        _result = previous;
        for (final entry in {
          ...previous!.confirmed,
          ...previous.pending,
        }.entries) {
          _setText(
            entry.key,
            entry.value == null ? '' : Money.formatCents(entry.value!),
          );
        }
      }
    }
    if (_result?.needsRead == true && !_controller.isSubmitting) {
      final latest = _controller.budgetResultFor(_month);
      if (latest != null && !latest.needsRead) {
        _result = latest;
        _adoptConfirmed(latest);
      }
    }
  }

  @override
  void didUpdateWidget(covariant BudgetEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O mês é capturado: mudanças no seletor não alteram esta edição aberta.
    if (oldWidget.controller != widget.controller) _onController();
  }

  String? _validate(Category category, String? text) {
    if (text == null || text.trim().isEmpty) {
      return _base.containsKey(category)
          ? 'Para remover, use Remover limite.'
          : null;
    }
    try {
      Money.parseCents(text);
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }

  void _adoptConfirmed(BudgetSubmissionResult result) {
    if (result.needsRead) return;
    for (final entry in result.confirmed.entries) {
      if (entry.value == null) {
        _base.remove(entry.key);
        _setText(entry.key, '');
      } else {
        _base[entry.key] = entry.value!;
      }
    }
  }

  Future<void> _submit() async {
    if (_locked || !_initialized || !_controller.canEditBudgets(_month)) return;
    if (!_form.currentState!.validate()) {
      final first = _categories.firstWhere(
        (c) => _validate(c, _texts[c]!.text) != null,
      );
      _focus[first]!.requestFocus();
      await Scrollable.ensureVisible(
        _keys[first]!.currentContext!,
        duration: const Duration(milliseconds: 150),
      );
      return;
    }
    final limits = <Category, int>{};
    for (final category in _categories) {
      if (_texts[category]!.text.trim().isNotEmpty) {
        limits[category] = Money.parseCents(_texts[category]!.text);
      }
    }
    FocusScope.of(context).unfocus();
    final result = await _controller.saveBudgetLimits(
      month: _month,
      limits: limits,
      expectedLimits: Map.of(_base),
    );
    _acceptResult(result);
  }

  void _acceptResult(BudgetSubmissionResult result) {
    if (!mounted || _allowPop || _invalid || !_controller.sessionValid) return;
    setState(() {
      _result = result;
      _adoptConfirmed(result);
    });
    if (_scroll.hasClients) {
      unawaited(
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _retryRead() async {
    if (_reading || _controller.isSubmitting || _invalid) return;
    setState(() => _reading = true);
    await _controller.refreshBudgets(month: _month);
    if (!mounted || _allowPop || _invalid || !_controller.sessionValid) return;
    setState(() {
      _reading = false;
      _result = _controller.budgetResultFor(_month);
      if (_result case final result?) _adoptConfirmed(result);
    });
  }

  Future<void> _remove(Category category) async {
    if (_locked || !_controller.canEditBudgets(_month)) return;
    final expected = Map<Category, int>.of(_base);
    var decided = false;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: Text('Remover limite de ${category.label}?'),
        content: Text(
          'Limite atual: ${Money.formatCents(expected[category]!)}. As despesas existentes não serão excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!decided) {
                decided = true;
                Navigator.pop(context, false);
              }
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('budget-remove-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () {
              if (!decided) {
                decided = true;
                Navigator.pop(context, true);
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _locked || !_controller.sessionValid) {
      return;
    }
    final result = await _controller.removeBudgetLimit(
      month: _month,
      category: category,
      expectedLimits: expected,
    );
    _acceptResult(result);
  }

  Future<void> _leave() async {
    if (_allowPop || _leaving || _invalid) return;
    _leaving = true;
    var discard = true;
    final sent = _controller.isSubmitting || _result?.needsRead == true;
    if (_dirty || sent) {
      discard =
          await showDialog<bool>(
            context: context,
            useRootNavigator: false,
            builder: (context) => AlertDialog(
              title: const Text('Sair do editor?'),
              content: Text(
                sent
                    ? 'Alterações enviadas podem continuar ou estar salvas. Sair não desfaz gravações; os rascunhos restantes serão descartados.'
                    : 'Descartar alterações não salvas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continuar editando'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (!mounted || _invalid) return;
    _leaving = false;
    if (!discard) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  Widget _resultView(BudgetSubmissionResult result) {
    final text = switch (result.status) {
      BudgetSubmissionStatus.confirmed =>
        result.confirmed.isEmpty
            ? 'Nenhuma alteração para salvar.'
            : 'Alterações confirmadas.',
      BudgetSubmissionStatus.partial =>
        'Alguns limites foram salvos; há alterações pendentes.',
      BudgetSubmissionStatus.refreshPending =>
        'Limites salvos. A atualização dos dados está pendente.',
      BudgetSubmissionStatus.uncertain => 'Resultado da alteração ainda incerto. Atualize os dados antes de continuar.',
      BudgetSubmissionStatus.failed =>
        result.failure?.message ?? 'Não foi possível salvar os limites.',
      BudgetSubmissionStatus.busy => 'Aguarde a operação em andamento.',
      BudgetSubmissionStatus.sessionInvalidated => 'Sessão alterada.',
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: Theme.of(context).textTheme.titleSmall),
          if (result.confirmed.isNotEmpty)
            Text(
              'Confirmados: ${result.confirmed.keys.map((c) => c.label).join(', ')}.',
            ),
          if (result.pending.isNotEmpty)
            Text(
              'Pendentes: ${result.pending.keys.map((c) => c.label).join(', ')}.',
            ),
          if (result.failure != null &&
              !result.needsRead &&
              result.status != BudgetSubmissionStatus.failed)
            Text(result.failure!.message),
          if (result.uncertain.isNotEmpty)
            Text(
              'Sem confirmação: ${result.uncertain.map((c) => c.label).join(', ')}.',
            ),
          if (result.needsRead) ...[
            if (result.failure != null) Text(result.failure!.message),
            OutlinedButton.icon(
              key: const ValueKey('budget-reconcile'),
              onPressed: _reading || _controller.isSubmitting
                  ? null
                  : _retryRead,
              icon: Icon(Icons.refresh),
              label: const Text('Atualizar limites'),
            ),
          ],
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final state = _controller.budgetStateFor(_month);
      final result = _result;
      return PopScope(
        canPop: _allowPop || _invalid || (!_dirty && !_controller.isSubmitting),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_leave());
        },
        child: Scaffold(
          body: SafeArea(
            child: _invalid
                ? const Center(
                    child: Text(
                      'Sessão alterada. Os dados do editor foram ocultados.',
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Voltar',
                              onPressed: _leave,
                              icon: Icon(
                                Icons.arrow_back,
                                color: context.colors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Editar limites',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  Text(
                                    DateFormat('MMMM yyyy', 'pt_BR').format(
                                      DateTime(_month.year, _month.month),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_controller.isSubmitting || _reading)
                        const LinearProgressIndicator(
                          semanticsLabel: 'Atualizando limites',
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (result != null) _resultView(result),
                              if (_initialized &&
                                  !state.hasConfirmedLimits &&
                                  result?.needsRead != true) ...[
                                Text(
                                  state.failure?.message ?? 'Atualize os limites desta competência antes de salvar.',
                                ),
                                OutlinedButton(
                                  key: const ValueKey('budget-reload-captured'),
                                  onPressed:
                                      _reading || _controller.isSubmitting
                                      ? null
                                      : _retryRead,
                                  child: const Text(
                                    'Atualizar limites desta competência',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.base),
                              ],
                              if (!_initialized) ...[
                                Text(
                                  state.failure?.message ??
                                      'Carregando limites…',
                                ),
                                if (state.failure != null)
                                  OutlinedButton(
                                    onPressed: _reading ? null : _retryRead,
                                    child: const Text('Tentar novamente'),
                                  ),
                              ] else
                                Form(
                                  key: _form,
                                  child: FocusTraversalGroup(
                                    child: Column(
                                      children: [
                                        for (final category in _categories)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md,
                                            ),
                                            child: Card(
                                              key: _keys[category],
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  AppSpacing.base,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        CategoryIcon(
                                                          category: category,
                                                        ),
                                                        const SizedBox(
                                                          width: AppSpacing.md,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            category.label,
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: AppSpacing.md,
                                                    ),
                                                    Semantics(
                                                      label:
                                                          'Limite de ${category.label}',
                                                      child: TextFormField(
                                                        key: ValueKey(
                                                          'budget-value-${category.id}',
                                                        ),
                                                        controller:
                                                            _texts[category],
                                                        focusNode:
                                                            _focus[category],
                                                        enabled: !_locked,
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(
                                                              decimal: true,
                                                            ),
                                                        textInputAction:
                                                            category ==
                                                                _categories.last
                                                            ? TextInputAction
                                                                  .done
                                                            : TextInputAction
                                                                  .next,
                                                        onFieldSubmitted: (_) {
                                                          final index =
                                                              _categories
                                                                  .indexOf(
                                                                    category,
                                                                  );
                                                          if (index + 1 <
                                                              _categories
                                                                  .length) {
                                                            _focus[_categories[index +
                                                                    1]]!
                                                                .requestFocus();
                                                          } else {
                                                            _focus[category]!
                                                                .unfocus();
                                                          }
                                                        },
                                                        validator: (value) =>
                                                            _validate(
                                                              category,
                                                              value,
                                                            ),
                                                        autovalidateMode:
                                                            AutovalidateMode
                                                                .onUserInteraction,
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Limite mensal',
                                                          hintText:
                                                              'Sem limite',
                                                          prefixIcon: Icon(
                                                            Icons.attach_money,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                          helperText:
                                                              _base[category] ==
                                                                  null
                                                              ? null
                                                              : 'Atual: ${Money.formatCents(_base[category]!)}',
                                                        ),
                                                      ),
                                                    ),
                                                    if (_base.containsKey(
                                                      category,
                                                    ))
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: TextButton.icon(
                                                          key: ValueKey(
                                                            'budget-remove-${category.id}',
                                                          ),
                                                          onPressed: _locked
                                                              ? null
                                                              : () => _remove(
                                                                  category,
                                                                ),
                                                          style: TextButton.styleFrom(
                                                            foregroundColor:
                                                                FinancialVisualTokens
                                                                    .expenseControlText,
                                                          ),
                                                          icon: Icon(
                                                            Icons
                                                                .delete_outline,
                                                          ),
                                                          label: const Text(
                                                            'Remover limite',
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        child: SubmitButton(
                          key: const ValueKey('budget-submit'),
                          label: 'Salvar alterações',
                          onPressed: _submit,
                          busy: _controller.isSubmitting,
                          enabled:
                              _initialized &&
                              !_locked &&
                              _controller.canEditBudgets(_month),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    },
  );

  @override
  void dispose() {
    _controller.removeListener(_onController);
    _scroll.dispose();
    for (final value in _texts.values) {
      value.removeListener(_draftChanged);
      value.dispose();
    }
    for (final value in _focus.values) {
      value.dispose();
    }
    super.dispose();
  }
}
