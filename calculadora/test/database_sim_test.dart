import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora/models/distribution_type.dart';
import 'package:calculadora/features/database_sim/database_simulator.dart';
import 'package:calculadora/features/database_sim/database_sim_pdf_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseSimPdfReport', () {
    test('Genera reporte PDF para simulación Poisson', () async {
      final sim = DatabaseSimulator.generate(
        distributionType: DistributionType.poisson,
        lambda: 4.0,
        numVariables: 3,
        numObservations: 10,
      );

      final bytes = await DatabaseSimPdfReport.generate(sim);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Genera reporte PDF para simulación Exponencial', () async {
      final sim = DatabaseSimulator.generate(
        distributionType: DistributionType.exponential,
        lambda: 2.0,
        numVariables: 2,
        numObservations: 15,
      );

      final bytes = await DatabaseSimPdfReport.generate(sim);
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}
