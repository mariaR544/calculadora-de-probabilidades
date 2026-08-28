import 'dart:math' as math;

/// Funciones matemáticas puras del modelo de colas M/M/1, separadas de
/// la UI para facilitar pruebas unitarias y reutilización.
class QueueMathUtils {
  QueueMathUtils._();

  // ---------------------------------------------------------------------
  // M/M/1 : DG/∞/∞  (sin límite en cola)
  // ---------------------------------------------------------------------

  static double infiniteP0(double rho) => 1 - rho;

  static double infinitePn(double rho, int n) =>
      (1 - rho) * math.pow(rho, n);

  static double infiniteLs(double rho) => rho / (1 - rho);

  static double infiniteLq(double rho) => (rho * rho) / (1 - rho);

  static double infiniteWs(double lambda, double mu) => 1 / (mu - lambda);

  static double infiniteWq(double lambda, double mu, double rho) =>
      rho / (mu - lambda);

  // ---------------------------------------------------------------------
  // M/M/1 : DG/N/∞  (con límite en cola, capacidad N)
  // ---------------------------------------------------------------------

  static bool _isRhoOne(double rho) => (rho - 1).abs() < 1e-9;

  static double finiteP0(double rho, int n) {
    if (_isRhoOne(rho)) return 1 / (n + 1);
    return (1 - rho) / (1 - math.pow(rho, n + 1));
  }

  static double finitePn(double p0, double rho, int k) =>
      p0 * math.pow(rho, k);

  /// Número esperado de clientes en el sistema (L_s) para capacidad N.
  static double finiteLs(double rho, int n) {
    if (_isRhoOne(rho)) return n / 2.0;
    final rhoN = math.pow(rho, n);
    final rhoN1 = math.pow(rho, n + 1);
    final numerator = rho * (1 - (n + 1) * rhoN + n * rhoN1);
    final denominator = (1 - rho) * (1 - rhoN1);
    return numerator / denominator;
  }
}
