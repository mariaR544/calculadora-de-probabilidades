import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/core/theme/app_colors.dart';
import 'package:calculadora/features/poisson/poisson_chart_painter.dart';
import 'package:calculadora/features/exponential/exponential_chart_painter.dart';
import 'package:calculadora/features/queueing/queue_chart_painter.dart';
import 'package:calculadora/features/multiserver/multiserver_chart_painter.dart';
import 'package:calculadora/models/calculation_result.dart';
import 'package:calculadora/models/queue_result.dart';
import 'package:calculadora/models/multiserver_queue_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Renderiza CustomPainter a imagen PNG con alta resolución', () async {
    final points = [
      ChartPoint(x: 0, y: 0.05, highlighted: false),
      ChartPoint(x: 1, y: 0.15, highlighted: false),
      ChartPoint(x: 2, y: 0.25, highlighted: true),
      ChartPoint(x: 3, y: 0.20, highlighted: true),
      ChartPoint(x: 4, y: 0.10, highlighted: false),
    ];

    final painter = PoissonChartPainter(points: points);
    const size = Size(500, 220);
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('Renderiza ExponentialChartPainter a imagen PNG', () async {
    final points = List.generate(
      50,
      (i) => ChartPoint(
        x: i * 0.1,
        y: 0.5 * math.exp(-0.5 * i * 0.1),
        highlighted: i >= 10 && i <= 30,
      ),
    );

    final painter = ExponentialChartPainter(points: points);
    const size = Size(500, 220);
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, bgPaint);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    expect(bytes, isNotEmpty);
  });

  test('Renderiza QueueChartPainter a imagen PNG', () async {
    final points = [
      QueueDistributionPoint(n: 0, probability: 0.4, cumulative: 0.4),
      QueueDistributionPoint(n: 1, probability: 0.24, cumulative: 0.64),
      QueueDistributionPoint(n: 2, probability: 0.144, cumulative: 0.784),
    ];

    final painter = QueueChartPainter.fromDistribution(points, cumulative: false);
    const size = Size(500, 220);
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, bgPaint);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    expect(bytes, isNotEmpty);
  });

  test('Renderiza MultiserverChartPainter a imagen PNG', () async {
    final points = [
      MultiserverDistributionPoint(n: 0, probability: 0.3, cumulative: 0.3),
      MultiserverDistributionPoint(n: 1, probability: 0.3, cumulative: 0.6),
      MultiserverDistributionPoint(n: 2, probability: 0.15, cumulative: 0.75),
    ];

    final painter = MultiserverChartPainter.fromDistribution(
      points,
      cumulative: false,
      servers: 2,
    );
    const size = Size(500, 220);
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    final bgPaint = Paint()..color = AppColors.surfaceAlt;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, bgPaint);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    expect(bytes, isNotEmpty);
  });
}
