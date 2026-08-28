import '../../models/queue_model_type.dart';
import '../../models/queue_result.dart';
import '../../utils/queue_math_utils.dart';

/// Encapsula toda la lógica de evaluación de los modelos de colas
/// M/M/1 (sin límite) y M/M/1/N (con límite), calculando parámetros
/// operativos y la distribución completa de probabilidad de estado.
class QueueCalculator {
  QueueCalculator._();

  static QueueResult calculate({
    required double lambda,
    required double mu,
    required QueueModelType type,
    int? capacity, // N, obligatorio si type == QueueModelType.finite
  }) {
    if (lambda <= 0) {
      throw const QueueValidationException(
          'λ (tasa de llegada) debe ser mayor que 0.');
    }
    if (mu <= 0) {
      throw const QueueValidationException(
          'μ (tasa de servicio) debe ser mayor que 0.');
    }

    final rho = lambda / mu;

    if (type == QueueModelType.infinite) {
      if (rho >= 1) {
        throw QueueValidationException(
            'El sistema es inestable (ρ = ${rho.toStringAsFixed(4)} ≥ 1). '
            'Para un modelo sin límite en cola, λ debe ser menor que μ '
            '(la cola crecería indefinidamente).');
      }
      return _calculateInfinite(lambda: lambda, mu: mu, rho: rho);
    }

    if (capacity == null || capacity < 1) {
      throw const QueueValidationException(
          'N (capacidad del sistema) debe ser un entero ≥ 1.');
    }
    return _calculateFinite(
      lambda: lambda,
      mu: mu,
      rho: rho,
      n: capacity,
    );
  }

  // ---------------------------------------------------------------------
  // M/M/1 sin límite
  // ---------------------------------------------------------------------

  static QueueResult _calculateInfinite({
    required double lambda,
    required double mu,
    required double rho,
  }) {
    final p0 = QueueMathUtils.infiniteP0(rho);
    final ls = QueueMathUtils.infiniteLs(rho);
    final lq = QueueMathUtils.infiniteLq(rho);
    final ws = QueueMathUtils.infiniteWs(lambda, mu);
    final wq = QueueMathUtils.infiniteWq(lambda, mu, rho);

    // Corte de graficación: hasta cubrir ~99.9% de la masa de
    // probabilidad, con un máximo razonable para no saturar la tabla.
    int cutoff = 0;
    double cumulative = 0;
    final points = <QueueDistributionPoint>[];
    while (cutoff <= 200) {
      final pn = QueueMathUtils.infinitePn(rho, cutoff);
      cumulative += pn;
      points.add(QueueDistributionPoint(
        n: cutoff,
        probability: pn,
        cumulative: cumulative.clamp(0.0, 1.0),
      ));
      if ((cumulative >= 0.999 && cutoff >= 8) || cutoff >= 60) break;
      cutoff++;
    }

    return QueueResult(
      type: QueueModelType.infinite,
      lambda: lambda,
      mu: mu,
      rho: rho,
      p0: p0,
      ls: ls,
      lq: lq,
      ws: ws,
      wq: wq,
      parameterSummary:
          'λ = ${lambda.toStringAsFixed(4)}  |  μ = ${mu.toStringAsFixed(4)}  |  ρ = ${rho.toStringAsFixed(4)}',
      distribution: points,
    );
  }

  // ---------------------------------------------------------------------
  // M/M/1 con límite N
  // ---------------------------------------------------------------------

  static QueueResult _calculateFinite({
    required double lambda,
    required double mu,
    required double rho,
    required int n,
  }) {
    final p0 = QueueMathUtils.finiteP0(rho, n);
    final ls = QueueMathUtils.finiteLs(rho, n);

    final points = <QueueDistributionPoint>[];
    double cumulative = 0;
    late double pN;
    for (int k = 0; k <= n; k++) {
      final pk = QueueMathUtils.finitePn(p0, rho, k);
      cumulative += pk;
      points.add(QueueDistributionPoint(
        n: k,
        probability: pk,
        cumulative: cumulative.clamp(0.0, 1.0),
      ));
      if (k == n) pN = pk;
    }

    final lambdaEff = lambda * (1 - pN);
    final lossRate = lambda - lambdaEff; // = lambda * pN
    final lq = ls - (1 - p0);
    final ws = ls / lambdaEff;
    final wq = lq / lambdaEff;

    return QueueResult(
      type: QueueModelType.finite,
      lambda: lambda,
      mu: mu,
      capacity: n,
      rho: rho,
      p0: p0,
      ls: ls,
      lq: lq,
      ws: ws,
      wq: wq,
      lambdaEff: lambdaEff,
      lossRate: lossRate,
      blockingProbability: pN,
      parameterSummary:
          'λ = ${lambda.toStringAsFixed(4)}  |  μ = ${mu.toStringAsFixed(4)}  |  ρ = ${rho.toStringAsFixed(4)}  |  N = $n',
      distribution: points,
    );
  }
}
