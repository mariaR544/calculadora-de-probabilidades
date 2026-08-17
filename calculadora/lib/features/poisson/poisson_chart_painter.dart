import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/calculation_result.dart';

/// Dibuja el histograma de barras P(X = x) en un plano cartesiano,
/// resaltando en un color diferenciado las barras que satisfacen la
/// condición de probabilidad seleccionada.
class PoissonChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final double axisLabelSize;

  PoissonChartPainter({required this.points, this.axisLabelSize = 10.5});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 42.0;
    const bottomPadding = 28.0;
    const topPadding = 12.0;
    const rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxY = points.map((p) => p.y).fold<double>(0, math.max);
    final yTop = maxY <= 0 ? 1.0 : maxY * 1.2;

    final axisPaint = Paint()
      ..color = AppColors.axis
      ..strokeWidth = 1.2;

    // Ejes
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

    // Líneas de referencia horizontales (grid suave)
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

    if (points.isEmpty) return;

    final n = points.length;
    final slotWidth = chartWidth / n;
    final barWidth = (slotWidth * 0.62).clamp(2.0, 34.0);

    final textPainterStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: axisLabelSize,
    );

    // Determina cada cuántas barras mostrar la etiqueta del eje X para
    // evitar amontonamiento cuando hay muchos valores de x.
    final labelStep = (n / 12).ceil().clamp(1, 100);

    for (int i = 0; i < n; i++) {
      final point = points[i];
      final barHeight = (point.y / yTop) * chartHeight;
      final xCenter = leftPadding + slotWidth * i + slotWidth / 2;
      final barRect = Rect.fromLTWH(
        xCenter - barWidth / 2,
        size.height - bottomPadding - barHeight,
        barWidth,
        barHeight,
      );

      final barPaint = Paint()
        ..color = point.highlighted
            ? AppColors.highlightStrong
            : AppColors.barBase;

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
          text: TextSpan(
              text: point.x.toInt().toString(), style: textPainterStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(xCenter - tp.width / 2, size.height - bottomPadding + 6),
        );
      }
    }

    // Etiquetas del eje Y
    for (int i = 0; i <= 4; i++) {
      final value = yTop * i / 4;
      final y = topPadding + chartHeight - (chartHeight * i / 4);
      final tp = TextPainter(
        text: TextSpan(
            text: value.toStringAsFixed(2), style: textPainterStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant PoissonChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}