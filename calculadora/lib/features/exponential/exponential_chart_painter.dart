import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/calculation_result.dart';

/// Dibuja la curva de densidad f(x) = λe^(-λx) en un plano cartesiano,
/// resaltando con un relleno diferenciado el área bajo la curva que
/// satisface la condición de probabilidad seleccionada.
class ExponentialChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final double axisLabelSize;

  ExponentialChartPainter({
    required this.points,
    this.axisLabelSize = 10.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPadding = 42.0;
    const bottomPadding = 28.0;
    const topPadding = 12.0;
    const rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final maxX = points.last.x;
    final maxY = points.map((p) => p.y).fold<double>(0, (a, b) => a > b ? a : b);
    final yTop = maxY <= 0 ? 1.0 : maxY * 1.2;

    Offset toCanvas(ChartPoint p) {
      final px = leftPadding + (p.x / maxX) * chartWidth;
      final py = topPadding + chartHeight - (p.y / yTop) * chartHeight;
      return Offset(px, py);
    }

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

    // --- Área resaltada bajo la curva ---
    final highlightedPoints = points.where((p) => p.highlighted).toList();
    if (highlightedPoints.isNotEmpty) {
      final areaPath = Path();
      final baseline = topPadding + chartHeight;
      final firstPoint = toCanvas(highlightedPoints.first);
      areaPath.moveTo(firstPoint.dx, baseline);
      for (final p in highlightedPoints) {
        areaPath.lineTo(toCanvas(p).dx, toCanvas(p).dy);
      }
      areaPath.lineTo(toCanvas(highlightedPoints.last).dx, baseline);
      areaPath.close();

      final areaPaint = Paint()..color = AppColors.highlight.withValues(alpha: 0.55);
      canvas.drawPath(areaPath, areaPaint);
    }

    // --- Curva f(x) ---
    final curvePath = Path();
    for (int i = 0; i < points.length; i++) {
      final c = toCanvas(points[i]);
      if (i == 0) {
        curvePath.moveTo(c.dx, c.dy);
      } else {
        curvePath.lineTo(c.dx, c.dy);
      }
    }
    final curvePaint = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, curvePaint);

    // --- Línea vertical en el punto evaluado (x₀) ---
    // El límite de la región resaltada está en el extremo del rango
    // que colinda con el punto no resaltado (o en el borde del plano).
    if (highlightedPoints.isNotEmpty &&
        highlightedPoints.length != points.length) {
      final startsHighlighted = points.first.highlighted;
      final markerX = startsHighlighted
          ? highlightedPoints.last.x
          : highlightedPoints.first.x;
      final markerCanvasX = leftPadding + (markerX / maxX) * chartWidth;
      final markerPaint = Paint()
        ..color = AppColors.highlightStrong
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(markerCanvasX, topPadding),
        Offset(markerCanvasX, size.height - bottomPadding),
        markerPaint,
      );
    }

    // --- Etiquetas eje X ---
    final labelStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: axisLabelSize,
    );
    for (int i = 0; i <= 5; i++) {
      final xVal = maxX * i / 5;
      final xPos = leftPadding + chartWidth * i / 5;
      final tp = TextPainter(
        text: TextSpan(text: xVal.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(xPos - tp.width / 2, size.height - bottomPadding + 6),
      );
    }

    // --- Etiquetas eje Y ---
    for (int i = 0; i <= 4; i++) {
      final value = yTop * i / 4;
      final y = topPadding + chartHeight - (chartHeight * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(2), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ExponentialChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
