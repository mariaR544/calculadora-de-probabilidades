import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/models/multiserver_queue_model_type.dart';
import 'package:calculadora/models/multiserver_queue_result.dart';
import 'package:calculadora/features/multiserver/multiserver_calculator.dart';
import 'package:calculadora/features/multiserver/multiserver_explanation_bottom_sheet.dart';
import 'package:calculadora/features/multiserver/multiserver_pdf_report.dart';
import 'package:calculadora/features/multiserver/multiserver_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('MultiserverCalculator (M/M/c y M/M/c/N)', () {
    test('M/M/c sin límite (capacidad infinita) calcula métricas exactas', () {
      // λ = 8, μ = 5, c = 2
      final result = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        type: MultiserverQueueModelType.infinite,
      );

      expect(result.servers, equals(2));
      expect(result.rho, closeTo(0.8, 1e-4));
      expect(result.p0, closeTo(1.0 / 9.0, 1e-4)); // ~0.1111
      expect(result.lq, closeTo(2.8444, 1e-3));
      expect(result.ls, closeTo(4.4444, 1e-3));
      expect(result.wq, closeTo(0.3555, 1e-3));
      expect(result.ws, closeTo(0.5555, 1e-3));
      expect(result.activeServers, closeTo(1.6, 1e-4));
      expect(result.idleServers, closeTo(0.4, 1e-4));
      expect(result.distribution.isNotEmpty, isTrue);
    });

    test('M/M/c sin límite arroja excepción si no cumple estabilidad (λ ≥ c·μ)', () {
      expect(
        () => MultiserverCalculator.calculate(
          lambda: 10,
          mu: 5,
          servers: 2, // 2 * 5 = 10, rho = 1.0 (inestable)
          type: MultiserverQueueModelType.infinite,
        ),
        throwsA(isA<MultiserverValidationException>()),
      );
    });

    test('M/M/c con límite N (capacidad finita) calcula λ_eff, pérdida y P_N', () {
      // λ = 8, μ = 5, c = 2, N = 4
      final result = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        capacity: 4,
        type: MultiserverQueueModelType.finite,
      );

      expect(result.isFinite, isTrue);
      expect(result.capacity, equals(4));
      expect(result.p0, greaterThan(0.0));
      expect(result.blockingProbability, isNotNull);
      expect(result.lambdaEff, isNotNull);
      expect(result.lossRate, isNotNull);
      expect(result.lambdaEff! + result.lossRate!, closeTo(8.0, 1e-4));
      expect(result.activeServers, closeTo(result.lambdaEff! / 5.0, 1e-4));
      expect(result.idleServers, closeTo(2 - (result.lambdaEff! / 5.0), 1e-4));
      expect(result.distribution.length, equals(5)); // n = 0, 1, 2, 3, 4
    });

    test('M/M/c/N valida que N ≥ c', () {
      expect(
        () => MultiserverCalculator.calculate(
          lambda: 8,
          mu: 5,
          servers: 3,
          capacity: 2, // N < c
          type: MultiserverQueueModelType.finite,
        ),
        throwsA(isA<MultiserverValidationException>()),
      );
    });
  });

  group('MultiserverExplanationBottomSheet', () {
    test('Genera textos explicativos completos para ambos modelos', () {
      final resInf = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        type: MultiserverQueueModelType.infinite,
      );
      final overviewInf = MultiserverExplanationTextGenerator.systemOverview(resInf);
      expect(overviewInf, contains('M/M/2'));
      expect(overviewInf, contains('capacidad infinita'));

      final serverInf = MultiserverExplanationTextGenerator.serverAnalysis(resInf);
      expect(serverInf, contains('servidores'));

      final metricsInf = MultiserverExplanationTextGenerator.metricsExplanations(resInf);
      expect(metricsInf.length, equals(5));

      final resFin = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        capacity: 4,
        type: MultiserverQueueModelType.finite,
      );
      final overviewFin = MultiserverExplanationTextGenerator.systemOverview(resFin);
      expect(overviewFin, contains('M/M/2/4'));
      expect(overviewFin, contains('capacidad finita'));

      final metricsFin = MultiserverExplanationTextGenerator.metricsExplanations(resFin);
      expect(metricsFin.length, equals(8));
      expect(metricsFin.any((m) => m.label.contains('Tasa efectiva')), isTrue);
      expect(metricsFin.any((m) => m.label.contains('Tasa de pérdida')), isTrue);
      expect(metricsFin.any((m) => m.label.contains('Probabilidad de bloqueo')), isTrue);
    });

    testWidgets('Modal de interpretación multicanal se renderiza correctamente',
        (WidgetTester tester) async {
      final res = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        type: MultiserverQueueModelType.infinite,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiserverExplanationBottomSheet(result: res),
          ),
        ),
      );

      expect(find.text('Explicación del resultado multicanal'), findsOneWidget);
      expect(find.text('DIAGNÓSTICO GENERAL DEL SISTEMA MULTICANAL'), findsOneWidget);
      expect(find.text('ANÁLISIS DE RENDIMIENTO DE LOS SERVIDORES'), findsOneWidget);
      expect(find.text('SIGNIFICADO DE LAS MÉTRICAS OPERATIVAS'), findsOneWidget);
    });
  });

  group('MultiserverPdfReport', () {
    test('Genera bytes PDF no vacíos para reporte multicanal', () async {
      final res = MultiserverCalculator.calculate(
        lambda: 8,
        mu: 5,
        servers: 2,
        capacity: 5,
        type: MultiserverQueueModelType.finite,
      );

      final pdfBytes = await MultiserverPdfReport.generate(res);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });

  group('MultiserverPanel Widget', () {
    testWidgets('Permite ingresar parámetros y calcular resultados',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MultiserverPanel(type: MultiserverQueueModelType.infinite),
          ),
        ),
      );

      expect(find.text('Parámetros de entrada multicanal'), findsOneWidget);
      expect(find.text('Calcular'), findsOneWidget);

      await tester.tap(find.text('Calcular'));
      await tester.pumpAndSettle();

      expect(find.text('MÉTRICAS DEL SISTEMA MULTICANAL'), findsOneWidget);
      expect(find.text('ESTADO DE LOS SERVIDORES (c = can.)'), findsOneWidget);
      expect(find.text('Interpretación'), findsOneWidget);
      expect(find.text('Tabla de probabilidades de estado'), findsOneWidget);
      expect(find.text('Exportar PDF'), findsOneWidget);
    });
  });
}
