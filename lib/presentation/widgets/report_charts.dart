import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/financial_visual_tokens.dart';
import '../../domain/models/category.dart';
import '../../domain/services/money.dart';
import '../services/report_projection.dart';

Color reportCategoryColor(Category category) =>
    FinancialVisualTokens.reportPalette[category.index];

class ReportLineChart extends StatelessWidget {
  const ReportLineChart({
    required this.months,
    required this.selected,
    required this.onSelected,
    required this.expanded,
    this.plotHeight,
    super.key,
  });
  final List<ReportMonth> months;
  final int? selected;
  final ValueChanged<int> onSelected;
  final bool expanded;
  final double? plotHeight;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11);
    final ticks = ReportProjection.axisTicks(months).toSet().toList();
    final labels = ticks.map(Money.formatCents).toList();
    var left = 0.0;
    for (final label in labels) {
      final text = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scale,
      )..layout();
      left = math.max(left, text.width + 12);
      text.dispose();
    }
    final height = (plotHeight ?? (expanded ? 260.0 : 175.0)) + scale.scale(16);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(constraints.maxWidth, left + 245);
        final rect = Rect.fromLTRB(
          left + 12,
          16,
          width - 24,
          height - scale.scale(24),
        );
        final max = ticks.last;
        final points = List.generate(
          months.length,
          (i) => Offset(
            rect.left + rect.width * i / (months.length - 1),
            max == 0
                ? rect.bottom
                : rect.bottom - rect.height * (months[i].cents / max),
          ),
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: height + 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _LinePainter(
                        points: points,
                        rect: rect,
                        ticks: ticks,
                        tickLabels: labels,
                        months: months
                            .map(
                              (m) => ReportProjection.monthLabel(
                                m.month,
                                short: true,
                              ),
                            )
                            .toList(),
                        style: style,
                        palette: context.colors,
                        scale: scale,
                        selected: selected,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < points.length; i++)
                  Positioned(
                    left: points[i].dx - 24,
                    top: points[i].dy - 24,
                    child: IconButton(
                      key: ValueKey('report-point-$i'),
                      tooltip:
                          '${ReportProjection.monthLabel(months[i].month)}: ${Money.formatCents(months[i].cents)}',
                      onPressed: () => onSelected(i),
                      icon: const SizedBox(width: 24, height: 24),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.rect,
    required this.ticks,
    required this.tickLabels,
    required this.months,
    required this.style,
    required this.palette,
    required this.scale,
    required this.selected,
  });
  final List<Offset> points;
  final Rect rect;
  final List<int> ticks;
  final List<String> tickLabels, months;
  final TextStyle style;
  final AppPalette palette;
  final TextScaler scale;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = palette.border
      ..strokeWidth = 0.7;
    for (var i = 0; i < ticks.length; i++) {
      final y = ticks.last == 0
          ? rect.bottom
          : rect.bottom - rect.height * ticks[i] / ticks.last;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      _text(canvas, tickLabels[i], Offset(0, y - scale.scale(6)));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final middle = (a.dx + b.dx) / 2;
      // Bézier monotone entre pontos: não produz gastos negativos por overshoot.
      path.cubicTo(middle, a.dy, middle, b.dy, b.dx, b.dy);
    }
    final area = Path.from(path)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.mint.withValues(alpha: 0.7),
            palette.mintSurface.withValues(alpha: 0.15),
          ],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        selected == i ? 5 : 3,
        Paint()..color = palette.primary,
      );
      _text(
        canvas,
        months[i],
        Offset(points[i].dx, rect.bottom + 8),
        centered: true,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset, {
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textScaler: scale,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centered ? offset.translate(-painter.width / 2, 0) : offset,
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.scale != scale ||
      old.style != style ||
      old.palette != palette;
}

class ReportDonut extends StatelessWidget {
  const ReportDonut({
    required this.categories,
    required this.total,
    required this.size,
    this.selected,
    this.onSelected,
    super.key,
  });
  final List<ReportCategory> categories;
  final int total;
  final double size;
  final Category? selected;
  final ValueChanged<Category>? onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: GestureDetector(
              onTapUp: onSelected == null
                  ? null
                  : (event) {
                      final vector =
                          event.localPosition - Offset(size / 2, size / 2);
                      if (vector.distance < size * 0.33 ||
                          vector.distance > size / 2) {
                        return;
                      }
                      var angle =
                          (math.atan2(vector.dy, vector.dx) + math.pi / 2) %
                          (2 * math.pi);
                      for (final category in categories) {
                        final sweep = category.percentage / 100 * 2 * math.pi;
                        if (angle < sweep) {
                          onSelected!(category.category);
                          return;
                        }
                        angle -= sweep;
                      }
                    },
              child: CustomPaint(painter: _DonutPainter(categories, selected)),
            ),
          ),
        ),
        SizedBox(
          width: size * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Money.formatCents(total),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text('Total', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.categories, this.selected);
  final List<ReportCategory> categories;
  final Category? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.14;
    final rect = Offset.zero & size;
    var angle = -math.pi / 2;
    for (final category in categories) {
      final sweep = category.percentage / 100 * 2 * math.pi;
      canvas.drawArc(
        rect.deflate(stroke / 2 + 2),
        angle,
        sweep,
        false,
        Paint()
          ..color = reportCategoryColor(category.category)
          ..strokeWidth = selected == category.category ? stroke + 3 : stroke
          ..style = PaintingStyle.stroke,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.categories != categories || old.selected != selected;
}
