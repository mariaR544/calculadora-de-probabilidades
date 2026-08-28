import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/models/queue_model_type.dart';
import 'package:calculadora/features/queueing/queue_calculator.dart';
import 'package:calculadora/features/queueing/queue_explanation_bottom_sheet.dart';

void main() {
  group('QueueExplanationTextGenerator', () {
    test('Genera interpretación para M/M/1 sin límite (infinito)', () {
      final result = QueueCalculator.calculate(
        lambda: 4,
        mu: 6,
        type: QueueModelType.infinite,
      );

      final overview = QueueExplanationTextGenerator.systemOverview(result);
      expect(overview, contains('M/M/1 (Capacidad infinita)'));
      expect(overview, contains('66.67%'));

      final metrics = QueueExplanationTextGenerator.metricsExplanations(result);
      expect(metrics.length, equals(4));
      expect(metrics[0].label, contains('Factor de utilización'));
      expect(metrics[1].label, contains('Probabilidad de sistema vacío'));
      expect(metrics[2].label, contains('Clientes en el sistema'));
      expect(metrics[3].label, contains('Tiempo en el sistema'));
    });

    test('Genera interpretación para M/M/1 con límite N (finito)', () {
      final result = QueueCalculator.calculate(
        lambda: 4,
        mu: 6,
        type: QueueModelType.finite,
        capacity: 5,
      );

      final overview = QueueExplanationTextGenerator.systemOverview(result);
      expect(overview, contains('M/M/1/5'));
      expect(overview, contains('Capacidad finita de 5 clientes'));

      final metrics = QueueExplanationTextGenerator.metricsExplanations(result);
      expect(metrics.length, equals(7));
      expect(metrics.any((m) => m.label.contains('Tasa efectiva de llegada')), isTrue);
      expect(metrics.any((m) => m.label.contains('Tasa de pérdida')), isTrue);
      expect(metrics.any((m) => m.label.contains('Probabilidad de bloqueo')), isTrue);
    });
  });

  testWidgets('QueueExplanationBottomSheet se renderiza correctamente',
      (WidgetTester tester) async {
    final result = QueueCalculator.calculate(
      lambda: 4,
      mu: 6,
      type: QueueModelType.finite,
      capacity: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QueueExplanationBottomSheet(result: result),
        ),
      ),
    );

    expect(find.text('Explicación del resultado'), findsOneWidget);
    expect(find.text('DIAGNÓSTICO GENERAL DEL SISTEMA'), findsOneWidget);
    expect(find.text('SIGNIFICADO DE LAS MÉTRICAS OPERATIVAS'), findsOneWidget);
    expect(find.text('DISTRIBUCIÓN DE PROBABILIDAD (Pn)'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
  });
}
