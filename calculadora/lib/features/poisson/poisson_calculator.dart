import 'dart:math' as math;
import '../../models/calculation_result.dart';
import '../../models/probability_type.dart';
import '../../utils/math_utils.dart';

/// Encapsula toda la lógica de evaluación de la distribución de
/// Poisson: cálculo de probabilidad, momentos, estadísticos
/// descriptivos y generación de los puntos para graficar tanto el
/// histograma puntual (PMF) como el acumulativo (CDF).
///
/// Soporta los 9 tipos de [ProbabilityType]: puntual, los cuatro
/// límites simples (`>`, `<`, `≥`, `≤`) y los cuatro tipos de rango
/// (abierto, cerrado y mixtos). Para los tipos de rango es
/// obligatorio proveer [x2] (el límite superior xⱼ).
class PoissonCalculator {
  PoissonCalculator._();

  /// Calcula el resultado completo para Poisson.
  ///
  /// [x] es el único parámetro requerido para los tipos de límite
  /// simple y puntual (equivale a xᵢ en los tipos de rango). [x2] solo
  /// es obligatorio cuando `type.requiresTwoInputs` es `true`.
  static CalculationResult calculate({
    required double lambda,
    required int x,
    int? x2,
    required ProbabilityType type,
  }) {
    if (lambda <= 0) {
      throw const ValidationException('λ (tasa promedio) debe ser mayor que 0.');
    }
    if (x < 0) {
      throw const ValidationException('x debe ser un entero ≥ 0.');
    }
    if (type.requiresTwoInputs) {
      if (x2 == null) {
        throw const ValidationException(
            'Este tipo de probabilidad requiere el límite xⱼ.');
      }
      if (x2 < x) {
        throw const ValidationException('xⱼ debe ser mayor o igual que xᵢ.');
      }
    }

    final probability = _probabilityFor(lambda, x, x2, type).clamp(0.0, 1.0);

    // --- Estadísticos descriptivos (fórmulas de Poisson) ---
    final stdDev = math.sqrt(lambda);
    final skewness = 1 / math.sqrt(lambda);
    final kurtosis = 3 + (1 / lambda);
    final coefficientOfVariation = 1 / math.sqrt(lambda);

    // Rango de graficación: cubre hasta el límite superior evaluado
    // (x o x2, el que sea mayor) más margen para ver la forma completa.
    final referenceUpper = x2 ?? x;
    final spread = math.sqrt(lambda) * 4 + 6;
    final upperBound =
        (lambda + spread).ceil().clamp(referenceUpper + 3, 80);

    final points = <ChartPoint>[];
    final cumulativePoints = <ChartPoint>[];

    for (int i = 0; i <= upperBound; i++) {
      // --- Página 1: PMF (probabilidad puntual) ---
      final pmf = MathUtils.poissonPmf(lambda, i);
      points.add(
        ChartPoint(
          x: i.toDouble(),
          y: pmf,
          highlighted: _isHighlighted(i, x, x2, type),
        ),
      );

      // --- Página 2: CDF (probabilidad acumulada) ---
      // Se resaltan las barras correspondientes a los límites
      // evaluados (xᵢ y, si aplica, xⱼ), marcando dónde caen sobre la
      // curva acumulada.
      final cdf = MathUtils.poissonCdfAtMost(lambda, i);
      cumulativePoints.add(
        ChartPoint(
          x: i.toDouble(),
          y: cdf,
          highlighted: i == x || (x2 != null && i == x2),
        ),
      );
    }

    return CalculationResult(
      probability: probability,
      mean: lambda,
      variance: lambda,
      stdDev: stdDev,
      skewness: skewness,
      kurtosis: kurtosis,
      coefficientOfVariation: coefficientOfVariation,
      parameterSummary: type.requiresTwoInputs
          ? 'λ = ${lambda.toStringAsFixed(4)}  |  xᵢ = $x  |  xⱼ = $x2'
          : 'λ = ${lambda.toStringAsFixed(4)}  |  x = $x',
      points: points,
      cumulativePoints: cumulativePoints,
      isDiscrete: true,
      evaluatedX: x.toDouble(),
    );
  }

  static double _probabilityFor(
    double lambda,
    int x,
    int? x2,
    ProbabilityType type,
  ) {
    switch (type) {
      case ProbabilityType.puntual:
        return MathUtils.poissonPmf(lambda, x);
      case ProbabilityType.mayorQue:
        // P(X > x) = P(X ≥ x + 1)
        return MathUtils.poissonCdfAtLeast(lambda, x + 1);
      case ProbabilityType.menorQue:
        // P(X < x) = P(X ≤ x - 1)
        return MathUtils.poissonCdfAtMost(lambda, x - 1);
      case ProbabilityType.mayorOIgual:
        return MathUtils.poissonCdfAtLeast(lambda, x);
      case ProbabilityType.menorOIgual:
        return MathUtils.poissonCdfAtMost(lambda, x);
      case ProbabilityType.estrictoRango:
        // P(x < X < x2) = P(X ≤ x2 - 1) - P(X ≤ x)
        return MathUtils.poissonCdfAtMost(lambda, x2! - 1) -
            MathUtils.poissonCdfAtMost(lambda, x);
      case ProbabilityType.cerradoRango:
        // P(x ≤ X ≤ x2) = P(X ≤ x2) - P(X ≤ x - 1)
        return MathUtils.poissonCdfAtMost(lambda, x2!) -
            MathUtils.poissonCdfAtMost(lambda, x - 1);
      case ProbabilityType.izqCerradoDerAbierto:
        // P(x ≤ X < x2) = P(X ≤ x2 - 1) - P(X ≤ x - 1)
        return MathUtils.poissonCdfAtMost(lambda, x2! - 1) -
            MathUtils.poissonCdfAtMost(lambda, x - 1);
      case ProbabilityType.izqAbiertoDerCerrado:
        // P(x < X ≤ x2) = P(X ≤ x2) - P(X ≤ x)
        return MathUtils.poissonCdfAtMost(lambda, x2!) -
            MathUtils.poissonCdfAtMost(lambda, x);
    }
  }

  static bool _isHighlighted(int i, int x, int? x2, ProbabilityType type) {
    switch (type) {
      case ProbabilityType.puntual:
        return i == x;
      case ProbabilityType.mayorQue:
        return i > x;
      case ProbabilityType.menorQue:
        return i < x;
      case ProbabilityType.mayorOIgual:
        return i >= x;
      case ProbabilityType.menorOIgual:
        return i <= x;
      case ProbabilityType.estrictoRango:
        return i > x && i < x2!;
      case ProbabilityType.cerradoRango:
        return i >= x && i <= x2!;
      case ProbabilityType.izqCerradoDerAbierto:
        return i >= x && i < x2!;
      case ProbabilityType.izqAbiertoDerCerrado:
        return i > x && i <= x2!;
    }
  }
}