import '../../models/calculation_result.dart';
import '../../models/probability_type.dart';
import '../../utils/math_utils.dart';

/// Encapsula toda la lógica de evaluación de la distribución
/// Exponencial: cálculo de probabilidad, momentos y generación de los
/// puntos para graficar la curva de densidad continua.
class ExponentialCalculator {
  ExponentialCalculator._();

static CalculationResult calculate({
    required double lambda,
    required double xi,  // Renombrado para consistencia con la guía
    double? xj,          // Agregar parámetro opcional xj
    required ProbabilityType type,
  }) {
    if (lambda <= 0) {
      throw const ValidationException('λ debe ser mayor que 0.');
    }
if (xi < 0 || (xj != null && xj < 0)) {
      throw const ValidationException('Los valores de x deben ser mayores o iguales que 0.');
    }
    if (type == ProbabilityType.puntual) {
      throw const ValidationException(
          'La probabilidad puntual no aplica a distribuciones continuas.');
    }

double probability;
    switch (type) {
      case ProbabilityType.mayorOIgual:
      case ProbabilityType.mayorQue:
        probability = MathUtils.exponentialCdfAtLeast(lambda, xi);
        break;

      case ProbabilityType.menorOIgual:
      case ProbabilityType.menorQue:
        probability = MathUtils.exponentialCdfAtMost(lambda, xi);
        break;

      case ProbabilityType.cerradoRango:
      case ProbabilityType.estrictoRango:
      case ProbabilityType.izqCerradoDerAbierto:
      case ProbabilityType.izqAbiertoDerCerrado:
        final upper = xj ?? xi;
        probability = MathUtils.exponentialCdfAtMost(lambda, upper) -
            MathUtils.exponentialCdfAtMost(lambda, xi);
        break;

      default:
        probability = 0.0;
        break;
    }

    // Rango de graficación: hasta cubrir ~99.5% de la masa de
    // probabilidad, o el punto evaluado, lo que sea mayor.
// Rango de graficación: hasta cubrir ~99.5% de la masa o el punto evaluado máximo
    final maxTarget = xj ?? xi;
    final theoreticalMax = 5.5 / lambda;
    final upperBound =
        theoreticalMax > maxTarget * 1.4 ? theoreticalMax : maxTarget * 1.4 + 1;

    const steps = 140;
    final dx = upperBound / steps;

    final points = <ChartPoint>[];
    for (int i = 0; i <= steps; i++) {
      final xVal = dx * i;
      final y = MathUtils.exponentialPdf(lambda, xVal);
      bool highlighted = false;

      switch (type) {
        case ProbabilityType.mayorOIgual:
        case ProbabilityType.mayorQue:
          highlighted = xVal >= xi;
          break;
        case ProbabilityType.menorOIgual:
        case ProbabilityType.menorQue:
          highlighted = xVal <= xi;
          break;
        case ProbabilityType.cerradoRango:
        case ProbabilityType.estrictoRango:
        case ProbabilityType.izqCerradoDerAbierto:
        case ProbabilityType.izqAbiertoDerCerrado:
          highlighted = xVal >= xi && xVal <= (xj ?? xi);
          break;
        default:
          highlighted = false;
          break;
      }
      points.add(ChartPoint(x: xVal, y: y, highlighted: highlighted));
    }

    return CalculationResult(
      probability: probability,
      mean: 1 / lambda,
      variance: 1 / (lambda * lambda),
      parameterSummary: 'λ = ${lambda.toStringAsFixed(4)}',
      points: points,
      isDiscrete: false,
      evaluatedX: xi,
    );
  }
}
