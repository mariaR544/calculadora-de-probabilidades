import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/models/distribution_type.dart';
import 'package:calculadora/models/probability_type.dart';
import 'package:calculadora/features/poisson/poisson_calculator.dart';
import 'package:calculadora/features/exponential/exponential_calculator.dart';
import 'package:calculadora/features/calculator/probability_pdf_report.dart';

void main() {
  group('ProbabilityPdfReport (Módulo 1)', () {
    test('Genera reporte PDF para Poisson', () async {
      final result = PoissonCalculator.calculate(
        lambda: 3.0,
        x: 2,
        type: ProbabilityType.puntual,
      );

      final bytes = await ProbabilityPdfReport.generate(
        result: result,
        distributionType: DistributionType.poisson,
        probabilityType: ProbabilityType.puntual,
      );

      expect(bytes.isNotEmpty, isTrue);
    });

    test('Genera reporte PDF para Exponencial', () async {
      final result = ExponentialCalculator.calculate(
        lambda: 0.5,
        xi: 2.0,
        xj: 4.0,
        type: ProbabilityType.cerradoRango,
      );

      final bytes = await ProbabilityPdfReport.generate(
        result: result,
        distributionType: DistributionType.exponential,
        probabilityType: ProbabilityType.cerradoRango,
        upperX: 4.0,
      );

      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
