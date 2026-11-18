import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/financial_visual_tokens.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/financial_month.dart';
import '../../controllers/financial_controller.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/theme_toggle.dart';
import '../../widgets/financial_load_state.dart';
import '../../widgets/monthly_totals_cards.dart';
import '../../widgets/category_spending_section.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/unavailable_financial_action.dart';
import '../../services/financial_projection.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.controller,
    required this.profile,
    this.clock,
    this.onAddTransaction,
    this.onViewTransactions,
    this.onViewBudget,
    this.onViewReports,
    super.key,
  });
  final FinancialController controller;
  final UserProfile profile;
  final DateTime Function()? clock;
  final VoidCallback? onAddTransaction;
  final VoidCallback? onViewTransactions;
  final VoidCallback? onViewBudget;
  final VoidCallback? onViewReports;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _monthTimer;
  bool _syncScheduled = false;
  bool _active = true;
  // Preferência visual pertencente somente à árvore privada desta sessão.
  bool _balanceVisible = true;
  FinancialController get controller => widget.controller;
  UserProfile get profile => widget.profile;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onController);
    _scheduleSync();
  }

  void _onController() {
    if (controller.phase == FinancialPhase.sessionInvalidated) {
      _monthTimer?.cancel();
      _balanceVisible = true;
    } else if (controller.month != FinancialMonth.fromDate(_now)) {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _syncCurrentMonth();
    });
  }

  void _syncCurrentMonth() {
    _monthTimer?.cancel();
    if (!mounted ||
        !_active ||
        controller.phase == FinancialPhase.sessionInvalidated) {
      return;
    }
    final now = _now.toLocal();
    controller.syncCurrentMonth(now: now);
    final untilBoundary = DateTime(now.year, now.month + 1).difference(now);
    // Apenas relógio local: sem polling de rede; evita limite de timers JS longos.
    final delay = untilBoundary > const Duration(days: 1)
        ? const Duration(days: 1)
        : untilBoundary;
    _monthTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      _syncCurrentMonth,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _syncCurrentMonth();
    } else {
      _monthTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(_onController);
      controller.addListener(_onController);
    }
    if (oldWidget.controller != controller ||
        oldWidget.profile.userId != profile.userId) {
      _balanceVisible = true;
    }
    _scheduleSync();
  }

  @override
  void dispose() {
    _monthTimer?.cancel();
    controller.removeListener(_onController);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final invalid =
          profile.userId != controller.expectedUserId ||
          controller.phase == FinancialPhase.sessionInvalidated;
      final currentSummary = controller.month == FinancialMonth.fromDate(_now)
          ? controller.summary
          : null;
      return Scaffold(
        floatingActionButton: invalid
            ? null
            : Semantics(
                label: widget.onAddTransaction == null
                    ? 'Adicionar transação disponível no M5.5.'
                    : 'Adicionar transação',
                button: true,
                enabled: widget.onAddTransaction != null,
                onTap: widget.onAddTransaction,
                excludeSemantics: true,
                child: FloatingActionButton(
                  onPressed: widget.onAddTransaction,
                  tooltip: widget.onAddTransaction == null
                      ? 'Adicionar transação disponível no M5.5.'
                      : 'Adicionar transação',
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  shape: const CircleBorder(),
                  child: Icon(Icons.add),
                ),
              ),
        body: SafeArea(
          child: invalid
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.base),
                    child: Text(
                      'Não foi possível confirmar a identidade desta sessão.',
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                      ),
                      child: FinancialLoadState(controller: controller),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.refreshFinancialData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.base),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  ExcludeSemantics(
                                    child: CircleAvatar(
                                      backgroundColor:
                                          FinancialVisualTokens.avatar,
                                      foregroundColor: context.colors.onPrimary,
                                      child: Text(
                                        profile.displayName.characters.first
                                            .toUpperCase(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Olá, ${profile.displayName} 👋',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                fontFamilyFallback: const [
                                                  'Noto Color Emoji',
                                                  'Segoe UI Emoji',
                                                ],
                                              ),
                                        ),
                                        Text(
                                          'Que bom te ver por aqui!',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const ThemeToggle(),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.base),
                              if (currentSummary case final summary?) ...[
                                BalanceCard(
                                  balanceCents: summary.balanceCents,
                                  visible: _balanceVisible,
                                  onToggleVisibility: () {
                                    if (profile.userId !=
                                            controller.expectedUserId ||
                                        controller.phase ==
                                            FinancialPhase.sessionInvalidated) {
                                      return;
                                    }
                                    setState(
                                      () => _balanceVisible = !_balanceVisible,
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                MonthlyTotalsCards(
                                  totals: summary.totals,
                                  budget: controller.dashboardBudgetState,
                                  onViewBudget: widget.onViewBudget,
                                  onRetryBudget: () => controller
                                      .refreshBudgets(month: controller.month),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                CategorySpendingSection(
                                  summary: summary,
                                  onViewReports: widget.onViewReports,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          'Transações recentes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ),
                                    if (widget.onViewTransactions != null)
                                      TextButton(
                                        onPressed: widget.onViewTransactions,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              context.colors.primary,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                        child: const Text('Ver todas ›'),
                                      )
                                    else
                                      const UnavailableFinancialAction(
                                        label: 'Ver todas',
                                        availability:
                                            'Navegação disponível no M5.5.',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                for (final transaction
                                    in FinancialProjection.recent(
                                      controller.transactions,
                                    ))
                                  TransactionTile(transaction: transaction),
                                const SizedBox(height: 72),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
