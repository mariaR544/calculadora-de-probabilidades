import '../../models/calculation_result.dart';
import '../../models/probability_type.dart';
import '../../utils/math_utils.dart';

/// Encapsula toda la lógica de evaluación de la distribución
/// Exponencial: cálculo de probabilidad, momentos, estadísticos
/// descriptivos y generación de los puntos para graficar tanto la
/// curva de densidad (PDF) como la acumulada (CDF).
class ExponentialCalculator {
  ExponentialCalculator._();

  static CalculationResult calculate({
    required double lambda,
    required double xi, // Renombrado para consistencia con la guía
    double? xj, // Límite superior, solo para tipos de rango
    required ProbabilityType type,
  }) {
    if (lambda <= 0) {
      throw const ValidationException('λ debe ser mayor que 0.');
    }
    if (xi < 0 || (xj != null && xj < 0)) {
      throw const ValidationException(
          'Los valores de x deben ser mayores o iguales que 0.');
    }
    if (type == ProbabilityType.puntual) {
      throw const ValidationException(
          'La probabilidad puntual no aplica a distribuciones continuas.');
    }
    if (type.requiresTwoInputs) {
      if (xj == null) {
        throw const ValidationException(
            'Este tipo de probabilidad requiere el límite xⱼ.');
      }
      if (xj < xi) {
        throw const ValidationException('xⱼ debe ser mayor o igual que xᵢ.');
      }
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
    probability = probability.clamp(0.0, 1.0);

    // --- Estadísticos descriptivos (fórmulas de la Exponencial) ---
    // Son constantes: no dependen de λ (salvo media/varianza/σ).
    final stdDev = 1 / lambda;
    const skewness = 2.0;
    const kurtosis = 9.0;
    const coefficientOfVariation = 1.0;

    // Rango de graficación: hasta cubrir ~99.5% de la masa de
    // probabilidad, o el punto evaluado máximo, lo que sea mayor.
    final maxTarget = xj ?? xi;
    final theoreticalMax = 5.5 / lambda;
    final upperBound =
        theoreticalMax > maxTarget * 1.4 ? theoreticalMax : maxTarget * 1.4 + 1;

    const steps = 140;
    final dx = upperBound / steps;

    final points = <ChartPoint>[];
    final cumulativePoints = <ChartPoint>[];

    for (int i = 0; i <= steps; i++) {
      final xVal = dx * i;
      bool highlighted;

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

      // --- Página 1: PDF (densidad) ---
      final pdfY = MathUtils.exponentialPdf(lambda, xVal);
      points.add(ChartPoint(x: xVal, y: pdfY, highlighted: highlighted));

      // --- Página 2: CDF (acumulada) ---
      final cdfY = MathUtils.exponentialCdfAtMost(lambda, xVal);
      cumulativePoints
          .add(ChartPoint(x: xVal, y: cdfY, highlighted: highlighted));
    }

    return CalculationResult(
      probability: probability,
      mean: 1 / lambda,
      variance: 1 / (lambda * lambda),
      stdDev: stdDev,
      skewness: skewness,
      kurtosis: kurtosis,
      coefficientOfVariation: coefficientOfVariation,
      parameterSummary: 'λ = ${lambda.toStringAsFixed(4)}',
      points: points,
      cumulativePoints: cumulativePoints,
      isDiscrete: false,
      evaluatedX: xi,
    );
  }
}