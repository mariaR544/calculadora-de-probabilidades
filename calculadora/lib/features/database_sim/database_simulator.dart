import 'dart:math' as math;
import '../../models/database_simulation.dart';
import '../../models/distribution_type.dart';

/// Genera la "base de datos" simulada: N variables independientes,
/// cada una con un número dado de observaciones, siguiendo la
/// distribución y parámetro λ especificados.
///
/// Ambos generadores usan el **método de la transformación inversa**:
/// se genera U ~ Uniforme(0,1) y se busca el valor x tal que
/// F(x⁻) < U ≤ F(x), invirtiendo la función de distribución acumulada.
class DatabaseSimulator {
  DatabaseSimulator._();

  static const int maxVariables = 10;
  static const int maxObservations = 500;

  static SimulationResult generate({
    required DistributionType distributionType,
    required double lambda,
    required int numVariables,
    required int numObservations,
  }) {
    if (lambda <= 0) {
      throw const SimulationValidationException('λ debe ser mayor que 0.');
    }
    if (numVariables < 1 || numVariables > maxVariables) {
      throw SimulationValidationException(
          'El número de variables debe estar entre 1 y $maxVariables.');
    }
    if (numObservations < 1 || numObservations > maxObservations) {
      throw SimulationValidationException(
          'El número de observaciones debe estar entre 1 y $maxObservations.');
    }

    final rng = math.Random();
    final variables = <SimulationVariable>[];

    for (int v = 1; v <= numVariables; v++) {
      final observations = List<double>.generate(
        numObservations,
        (_) => distributionType.isDiscrete
            ? _poissonInverseTransform(lambda, rng).toDouble()
            : _exponentialInverseTransform(lambda, rng),
      );
      variables.add(SimulationVariable(name: 'Variable $v', observations: observations));
    }

    return SimulationResult(
      distributionType: distributionType,
      lambda: lambda,
      numVariables: numVariables,
      numObservations: numObservations,
      variables: variables,
      generatedAt: DateTime.now(),
    );
  }

  /// Transformación inversa para Poisson: acumula P(X=k) hasta que la
  /// suma supere U, actualizando la PMF de forma recursiva
  /// (P(k) = P(k-1)·λ/k) para evitar el cálculo directo de factoriales.
  static int _poissonInverseTransform(double lambda, math.Random rng) {
    final u = rng.nextDouble();
    double pmf = math.exp(-lambda); // P(X = 0)
    double cumulative = pmf;
    int k = 0;
    while (u > cumulative) {
      k++;
      pmf = pmf * lambda / k;
      cumulative += pmf;
      if (k > 100000) break; // salvaguarda ante λ extremos
    }
    return k;
  }

  /// Transformación inversa para Exponencial: X = -ln(1-U) / λ,
  /// obtenida al invertir F(x) = 1 - e^(-λx).
  static double _exponentialInverseTransform(double lambda, math.Random rng) {
    final u = rng.nextDouble(); // U ∈ [0, 1)
    return -math.log(1 - u) / lambda;
  }
}
