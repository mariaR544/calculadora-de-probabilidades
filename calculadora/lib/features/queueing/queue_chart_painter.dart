import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/queue_result.dart';

/// Dibuja el histograma de barras de la distribución de estado del
/// sistema (P_n o su acumulada) en un plano cartesiano.
///
/// Estructura idéntica a `PoissonChartPainter` del Módulo 1, para
/// mantener la misma identidad visual entre módulos.
class QueueChartPainter extends CustomPainter {
  final List<double> values;
  final List<int> nLabels;
  final double axisLabelSize;

  QueueChartPainter({
    required this.values,
    required this.nLabels,
    this.axisLabelSize = 10.5,
  });

  factory QueueChartPainter.fromDistribution(
    List<QueueDistributionPoint> points, {
    required bool cumulative,
  }) {
    return QueueChartPainter(
      values: points.map((p) => cumulative ? p.cumulative : p.probability).toList(),
      nLabels: points.map((p) => p.n).toList(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 42.0;
    const bottomPadding = 28.0;
    const topPadding = 12.0;
    const rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxY = values.fold<double>(0, math.max);
    final yTop = maxY <= 0 ? 1.0 : maxY * 1.2;

    final axisPaint = Paint()
      ..color = AppColors.axis
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width - rightPadding, size.height - bottomPadding),
      axisPaint,
    );

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = topPadding + chartHeight - (chartHeight * i / 4);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    if (values.isEmpty) return;

    final n = values.length;
    final slotWidth = chartWidth / n;
    final barWidth = (slotWidth * 0.62).clamp(2.0, 34.0);

    final textPainterStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: axisLabelSize,
    );

    final labelStep = (n / 12).ceil().clamp(1, 100);

    for (int i = 0; i < n; i++) {
      final barHeight = (values[i] / yTop) * chartHeight;
      final xCenter = leftPadding + slotWidth * i + slotWidth / 2;
      final barRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        size.height - bottomPadding - barHeight,
        barWidth,
        barHeight,
      );

      final barPaint = Paint()..color = AppColors.primaryLight;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        barPaint,
      );

      if (i % labelStep == 0) {
        final tp = TextPainter(
          text: TextSpan(text: nLabels[i].toString(), style: textPainterStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(xCenter - tp.width / 2, size.height - bottomPadding + 6),
        );
      }
    }

    for (int i = 0; i <= 4; i++) {
      final value = yTop * i / 4;
      final y = topPadding + chartHeight - (chartHeight * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(2), style: textPainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant QueueChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
