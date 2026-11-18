import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/financial_summary.dart';
import '../../../domain/services/money.dart';
import '../../controllers/financial_controller.dart';
import '../../services/report_projection.dart';
import '../../widgets/financial_load_state.dart';
import '../../widgets/report_charts.dart';

enum ReportMode { overview, categories, evolution }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.controller, super.key});
  final FinancialController controller;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportMode _mode = ReportMode.overview;
  int? _selectedPoint;
  Category? _selectedCategory;
  FinancialSummary? _source;
  ReportProjection? _projection;
  final _donutAnimationKey = GlobalKey();

  @override
  void didUpdateWidget(covariant ReportsScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _source = null;
      _projection = null;
      _selectedPoint = null;
      _selectedCategory = null;
      _mode = ReportMode.overview;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (!controller.sessionValid) {
        _source = null;
        _projection = null;
        _selectedCategory = null;
        _selectedPoint = null;
        return const SizedBox.shrink();
      }
      final summary = controller.summary;
      if (!identical(_source, summary)) {
        _source = summary;
        _projection = summary == null
            ? null
            : ReportProjection(summary, userId: controller.expectedUserId);
        _selectedPoint = null;
        _selectedCategory = null;
      }
      final report = _projection;
      return Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Relatórios',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final (mode, label) in [
                        (ReportMode.overview, 'Visão geral'),
                        (ReportMode.categories, 'Categorias'),
                        (ReportMode.evolution, 'Evolução'),
                      ]) ...[
                        if (mode != ReportMode.overview)
                          const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Semantics(
                            selected: _mode == mode,
                            child: FilledButton(
                              key: ValueKey('report-mode-${mode.name}'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                backgroundColor: _mode == mode
                                    ? context.colors.primary
                                    : context.colors.surfaceMuted,
                                foregroundColor: _mode == mode
                                    ? context.colors.onPrimary
                                    : context.colors.textPrimary,
                              ),
                              onPressed: () => setState(() => _mode = mode),
                              child: Text(label, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  FinancialLoadState(controller: controller),
                  if (summary != null && report != null) ...[
                    _ReportReveal(
                      visible: _mode != ReportMode.categories,
                      child: _card([
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Gastos do mês',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            _Variation(
                              value: summary.expenseVariationPercentage,
                              badge: true,
                            ),
                          ],
                        ),
                        Text(
                          Money.formatCents(summary.totals.expenseCents),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'vs. mês anterior (${Money.formatCents(summary.previousExpenseCents)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          ReportProjection.monthLabel(summary.totals.month),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (report.evolution.every((item) => item.cents == 0))
                          Padding(
                            padding: EdgeInsets.all(AppSpacing.base),
                            child: Text(
                              'Nenhuma despesa nos últimos seis meses.',
                            ),
                          )
                        else ...[
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              end: _mode == ReportMode.evolution
                                  ? 260.0
                                  : 175.0,
                            ),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 320),
                            curve: Curves.easeInOutCubic,
                            builder: (context, height, _) => ReportLineChart(
                              months: report.evolution,
                              selected: _selectedPoint,
                              expanded: _mode == ReportMode.evolution,
                              plotHeight: height,
                              onSelected: (index) =>
                                  setState(() => _selectedPoint = index),
                            ),
                          ),
                          if (_selectedPoint case final index?)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                '${ReportProjection.monthLabel(report.evolution[index].month)}: ${Money.formatCents(report.evolution[index].cents)}',
                                key: const ValueKey('report-point-value'),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                        ],
                        _ReportReveal(
                          visible: _mode == ReportMode.evolution,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.base),
                              Text(
                                'Últimos seis meses',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                'Maior gasto: ${ReportProjection.monthLabel(report.maximum.month)} — ${Money.formatCents(report.maximum.cents)}',
                              ),
                              Text(
                                'Menor gasto: ${ReportProjection.monthLabel(report.minimum.month)} — ${Money.formatCents(report.minimum.cents)}',
                              ),
                              Text(
                                'Média mensal: ${Money.formatCents(report.averageCents)}',
                              ),
                              for (final month in report.evolution)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ReportProjection.monthLabel(month.month)}: ${Money.formatCents(month.cents)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      _Variation(value: month.variation),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    _ReportReveal(
                      visible: _mode != ReportMode.evolution,
                      child: _card([
                        Text(
                          'Gastos por categoria',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (report.categories.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.base,
                            ),
                            child: Text('Nenhuma despesa nesta competência.'),
                          )
                        else ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked =
                                  _mode == ReportMode.categories ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      20 ||
                                  Money.formatCents(summary.totals.expenseCents)
                                          .length >
                                      16;
                              final legend = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final item in report.categories)
                                    Semantics(
                                      selected:
                                          _selectedCategory == item.category,
                                      child: InkWell(
                                        onTap: () => setState(
                                          () =>
                                              _selectedCategory = item.category,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.field,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.sm,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 10,
                                                color: reportCategoryColor(
                                                  item.category,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppSpacing.xs,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.category.label,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                              Text(
                                                ReportProjection.percentage(
                                                  item.percentage,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                              return TweenAnimationBuilder<double>(
                                key: _donutAnimationKey,
                                tween: Tween(
                                  end: stacked
                                      ? constraints.maxWidth.clamp(180.0, 260.0)
                                      : constraints.maxWidth * 0.5,
                                ),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 320),
                                curve: Curves.easeInOutCubic,
                                builder: (context, size, _) {
                                  final chart = ReportDonut(
                                    categories: report.categories,
                                    total: summary.totals.expenseCents,
                                    size: size,
                                    selected: _selectedCategory,
                                    onSelected: (category) => setState(
                                      () => _selectedCategory = category,
                                    ),
                                  );
                                  // A legenda só volta à lateral quando houver espaço real.
                                  return stacked ||
                                          size >
                                              constraints.maxWidth * 0.5 + 0.01
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Center(child: chart),
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            legend,
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            chart,
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Expanded(child: legend),
                                          ],
                                        );
                                },
                              );
                            },
                          ),
                          if (_selectedCategory case final category?)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                '${category.label}: ${Money.formatCents(report.categories.firstWhere((item) => item.category == category).cents)}',
                                key: const ValueKey('report-category-value'),
                              ),
                            ),
                          _ReportReveal(
                            visible: _mode == ReportMode.categories,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppSpacing.base),
                                Text(
                                  'Maior gasto: ${report.categories.first.category.label}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                for (
                                  var i = 0;
                                  i < report.categories.length;
                                  i++
                                )
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          '${i + 1}. ${report.categories[i].category.label}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        Text(
                                          '${Money.formatCents(report.categories[i].cents)} • ${report.categories[i].count} ${report.categories[i].count == 1 ? 'transação' : 'transações'} • ${ReportProjection.percentage(report.categories[i].percentage)}',
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        LinearProgressIndicator(
                                          value:
                                              report.categories[i].percentage /
                                              100,
                                          color: reportCategoryColor(
                                            report.categories[i].category,
                                          ),
                                          backgroundColor:
                                              context.colors.surfaceMuted,
                                          semanticsLabel:
                                              '${report.categories[i].category.label}: ${ReportProjection.percentage(report.categories[i].percentage)} das despesas',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _size(Widget child) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          child: child,
        );

  Widget _card(List<Widget> children) => _size(
    Card(
      margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _Variation extends StatelessWidget {
  const _Variation({required this.value, this.badge = false});
  final double? value;
  final bool badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Container(
      padding: badge
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            )
          : null,
      decoration: badge
          ? BoxDecoration(
              color: value == null || value == 0
                  ? context.colors.surfaceMuted
                  : value! > 0
                  ? context.colors.expenseSurface
                  : context.colors.mintSurface,
              borderRadius: BorderRadius.circular(AppRadii.field),
            )
          : null,
      child: Text(
        ReportProjection.variation(value),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
          color: value == null || value == 0
              ? context.colors.textSecondary
              : value! > 0
              ? context.colors.expenseText
              : context.colors.primary,
        ),
      ),
    ),
  );
}

/// Mantém os cards montados; tamanho/opacidade respondem a mudanças rápidas.
class _ReportReveal extends StatefulWidget {
  const _ReportReveal({required this.visible, required this.child});
  final bool visible;
  final Widget child;
  @override
  State<_ReportReveal> createState() => _ReportRevealState();
}

class _ReportRevealState extends State<_ReportReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeInOutCubic,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _ReportReveal old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _animation.forward();
    } else {
      _animation.reverse();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, _) => Offstage(
      offstage: _animation.isDismissed,
      child: SizeTransition(
        sizeFactor: _curve,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _curve,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: ExcludeSemantics(
              excluding: !widget.visible,
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}
