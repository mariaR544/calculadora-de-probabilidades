import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renderizador de alta resolución para exportar los [CustomPainter] de las
/// gráficas de Quantis a imágenes PNG fieles a la plataforma e integrarlas en los PDFs.
class PdfChartImageBuilder {
  PdfChartImageBuilder._();

  /// Renderiza cualquier [CustomPainter] sobre un contenedor idéntico al de la plataforma
  /// (`AppColors.surfaceAlt` con esquinas redondeadas y borde sutil).
  static Future<Uint8List> renderPainter({
    required CustomPainter painter,
    Size size = const Size(500, 200),
    double pixelRatio = 3.0,
    Color backgroundColor = AppColors.surfaceAlt,
    Color borderColor = AppColors.border,
    double borderRadius = 14.0,
  }) async {
    final width = size.width * pixelRatio;
    final height = size.height * pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);

    // 1. Fondo idéntico al contenedor de la plataforma
    final bgPaint = Paint()..color = backgroundColor;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, bgPaint);

    // 2. Borde idéntico al contenedor de la plataforma
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Renderizado del CustomPainter con ejes, grid, curvas/barras y etiquetas
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.round(), height.round());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
