import 'dart:math' as math;
import '../../models/calculation_result.dart';
import '../../models/probability_type.dart';
import '../../utils/math_utils.dart';

/// Encapsula toda la lógica de evaluación de la distribución de
/// Poisson: cálculo de probabilidad, momentos y generación de los
/// puntos para graficar el histograma de barras.
class PoissonCalculator {
  PoissonCalculator._();

  /// Calcula el resultado completo para Poisson.
  static CalculationResult calculate({
    required double lambda,
    required int x,
    required ProbabilityType type,
  }) {
    if (lambda <= 0) {
      throw const ValidationException('λ (tasa promedio) debe ser mayor que 0.');
    }
    if (x < 0) {
      throw const ValidationException('x debe ser un entero ≥ 0.');
    }

    double probability;
    switch (type) {
      case ProbabilityType.puntual:
        probability = MathUtils.poissonPmf(lambda, x);
        break;
      case ProbabilityType.menorOIgual:
        probability = MathUtils.poissonCdfAtMost(lambda, x);
        break;
      case ProbabilityType.mayorOIgual:
        probability = MathUtils.poissonCdfAtLeast(lambda, x);
        break;
        default:
         probability = 0.0; // Para otros tipos de probabilidad no aplicables a Poisson
        break;
    }

    // Rango de graficación
    final spread = math.sqrt(lambda) * 4 + 6;
    final upperBound = (lambda + spread).ceil().clamp(x + 3, 60);

    final points = <ChartPoint>[];
    for (int i = 0; i <= upperBound; i++) {
      final y = MathUtils.poissonPmf(lambda, i);
      bool highlighted;
      switch (type) {
        case ProbabilityType.puntual:
          highlighted = i == x;
          break;
        case ProbabilityType.menorOIgual:
          highlighted = i <= x;
          break;
        case ProbabilityType.mayorOIgual:
          highlighted = i >= x;
          break;
        default:
          highlighted = false; // Otros tipos no aplicables a Poisson
      }
      points.add(ChartPoint(x: i.toDouble(), y: y, highlighted: highlighted));
    }

    return CalculationResult(
      probability: probability,
      mean: lambda,
      variance: lambda,
      parameterSummary:
          'λ = ${lambda.toStringAsFixed(4)}  |  x = $x',
      points: points,
      isDiscrete: true,
      evaluatedX: x.toDouble(),
    );
  }
}