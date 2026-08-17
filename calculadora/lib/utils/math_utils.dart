import 'dart:math' as math;

/// Funciones matemáticas puras usadas por las calculadoras de
/// distribución. Se mantienen aisladas de la UI para poder reutilizarlas
/// en futuros módulos y facilitar pruebas unitarias.
class MathUtils {
  MathUtils._();

  /// ln(k!) calculado como suma de logaritmos, para evitar el
  /// desbordamiento numérico que tendría calcular k! directamente
  /// para valores de k relativamente grandes.
  static double lnFactorial(int k) {
    double sum = 0;
    for (int i = 2; i <= k; i++) {
      sum += math.log(i);
    }
    return sum;
  }

  // ---------------------------------------------------------------------
  // Poisson (discreta)
  // ---------------------------------------------------------------------

  /// P(X = k) — Función de Masa de Probabilidad (PMF).
  static double poissonPmf(double lambda, int k) {
    if (lambda <= 0 || k < 0) return 0;
    final lnP = -lambda + k * math.log(lambda) - lnFactorial(k);
    return math.exp(lnP);
  }

  /// P(X ≤ k) — Acumulada inferior.
  static double poissonCdfAtMost(double lambda, int k) {
    if (k < 0) return 0;
    double sum = 0;
    for (int i = 0; i <= k; i++) {
      sum += poissonPmf(lambda, i);
    }
    return sum.clamp(0, 1);
  }

  /// P(X ≥ k) — Acumulada superior.
  static double poissonCdfAtLeast(double lambda, int k) {
    if (k <= 0) return 1;
    return (1 - poissonCdfAtMost(lambda, k - 1)).clamp(0, 1);
  }

  // ---------------------------------------------------------------------
  // Exponencial (continua)
  // ---------------------------------------------------------------------

  /// f(x) = λe^(-λx) — Función de Densidad de Probabilidad (PDF).
  static double exponentialPdf(double lambda, double x) {
    if (x < 0 || lambda <= 0) return 0;
    return lambda * math.exp(-lambda * x);
  }

  /// P(X ≤ x) = 1 - e^(-λx).
  static double exponentialCdfAtMost(double lambda, double x) {
    if (x < 0) return 0;
    return (1 - math.exp(-lambda * x)).clamp(0, 1);
  }

  /// P(X ≥ x) = e^(-λx).
  static double exponentialCdfAtLeast(double lambda, double x) {
    if (x < 0) return 1;
    return math.exp(-lambda * x).clamp(0, 1);
  }
}
