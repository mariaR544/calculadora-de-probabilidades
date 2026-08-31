import 'dart:math' as math;
import '../models/distribution_type.dart';

/// Una variable simulada: un vector de observaciones generadas de
/// forma independiente siguiendo la distribución y parámetro elegidos.
class SimulationVariable {
  final String name;
  final List<double> observations;

  const SimulationVariable({
    required this.name,
    required this.observations,
  });

  double get sampleMean =>
      observations.isEmpty ? 0 : observations.reduce((a, b) => a + b) / observations.length;

  double get sampleVariance {
    if (observations.length < 2) return 0;
    final mean = sampleMean;
    final sumSq = observations
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b);
    return sumSq / (observations.length - 1);
  }

  double get sampleStdDev => math.sqrt(sampleVariance);
}

/// Resultado completo de una simulación: la "base de datos" generada
/// (una o más variables, cada una con N observaciones) junto con los
/// parámetros teóricos usados para generarla.
class SimulationResult {
  final DistributionType distributionType;
  final double lambda;
  final int numVariables;
  final int numObservations;
  final List<SimulationVariable> variables;
  final DateTime generatedAt;

  const SimulationResult({
    required this.distributionType,
    required this.lambda,
    required this.numVariables,
    required this.numObservations,
    required this.variables,
    required this.generatedAt,
  });

  /// Media teórica E[X] según la distribución y λ usados.
  double get theoreticalMean =>
      distributionType.isDiscrete ? lambda : 1 / lambda;

  /// Varianza teórica Var(X) según la distribución y λ usados.
  double get theoreticalVariance =>
      distributionType.isDiscrete ? lambda : 1 / (lambda * lambda);
}

/// Excepción de validación de parámetros de simulación.
class SimulationValidationException implements Exception {
  final String message;
  const SimulationValidationException(this.message);

  @override
  String toString() => message;
}
