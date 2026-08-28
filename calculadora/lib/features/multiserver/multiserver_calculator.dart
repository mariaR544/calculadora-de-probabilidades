import 'dart:math' as math;
import '../../models/multiserver_queue_model_type.dart';
import '../../models/multiserver_queue_result.dart';

/// Motor de cálculo para modelos de líneas de espera multicanal (M/M/c).
///
/// Implementa las fórmulas analíticas formales de la teoría de colas para:
/// - M/M/c sin límite en cola (capacidad infinita)
/// - M/M/c con límite en cola (capacidad total del sistema N)
class MultiserverCalculator {
  MultiserverCalculator._();

  /// Evalúa el modelo de colas multicanal según los parámetros ingresados.
  static MultiserverQueueResult calculate({
    required double lambda,
    required double mu,
    required int servers,
    required MultiserverQueueModelType type,
    int? capacity,
  }) {
    if (lambda <= 0) {
      throw const MultiserverValidationException(
          'La tasa de llegada (λ) debe ser un valor positivo mayor que 0.');
    }
    if (mu <= 0) {
      throw const MultiserverValidationException(
          'La tasa de servicio por servidor (μ) debe ser un valor positivo mayor que 0.');
    }
    if (servers < 1) {
      throw const MultiserverValidationException(
          'El número de servidores (c) debe ser al menos 1.');
    }

    final r = lambda / mu; // Intensidad de tráfico λ/μ
    final rho = lambda / (servers * mu); // Factor de utilización nominal

    if (type == MultiserverQueueModelType.infinite) {
      if (rho >= 1.0) {
        throw MultiserverValidationException(
            'Condición de estabilidad no cumplida: λ ($lambda) debe ser estrictamente menor que c · μ (${(servers * mu).toStringAsFixed(2)}). '
            'El sistema no alcanza un estado estacionario estable y la cola crecería indefinidamente.');
      }
      return _calculateInfinite(
        lambda: lambda,
        mu: mu,
        c: servers,
        r: r,
        rho: rho,
      );
    } else {
      if (capacity == null) {
        throw const MultiserverValidationException(
            'Debes ingresar la capacidad máxima del sistema (N).');
      }
      if (capacity < servers) {
        throw MultiserverValidationException(
            'La capacidad máxima del sistema N ($capacity) debe ser mayor o igual que el número de servidores c ($servers).');
      }
      return _calculateFinite(
        lambda: lambda,
        mu: mu,
        c: servers,
        capacity: capacity,
        r: r,
        rho: rho,
      );
    }
  }

  static double _factorial(int n) {
    if (n <= 1) return 1.0;
    double res = 1.0;
    for (int i = 2; i <= n; i++) {
      res *= i;
    }
    return res;
  }

  // ---------------------------------------------------------------------
  // M/M/c Sin Límite (Capacidad Infinita)
  // ---------------------------------------------------------------------
  static MultiserverQueueResult _calculateInfinite({
    required double lambda,
    required double mu,
    required int c,
    required double r,
    required double rho,
  }) {
    // 1. P0
    double sum = 0.0;
    for (int n = 0; n < c; n++) {
      sum += math.pow(r, n) / _factorial(n);
    }
    final termC = (math.pow(r, c) / _factorial(c)) * (1.0 / (1.0 - rho));
    final p0 = 1.0 / (sum + termC);

    // 2. Lq
    final lq = (p0 * math.pow(r, c) * rho) /
        (_factorial(c) * math.pow(1.0 - rho, 2));

    // 3. Wq
    final wq = lq / lambda;

    // 4. Ws
    final ws = wq + (1.0 / mu);

    // 5. Ls
    final ls = lambda * ws; // Lq + r

    // 6. Métricas de servidores
    final activeServers = r; // Promedio de servidores ocupados
    final idleServers = c - activeServers; // c̄: promedio de servidores inactivos

    // 7. Distribución Pn
    final distribution = <MultiserverDistributionPoint>[];
    double cumulative = 0.0;
    final maxN = math.max(c + 15, 20);

    for (int n = 0; n <= maxN; n++) {
      double pn;
      if (n <= c) {
        pn = (math.pow(r, n) / _factorial(n)) * p0;
      } else {
        pn = (math.pow(r, n) / (_factorial(c) * math.pow(c, n - c))) * p0;
      }
      cumulative += pn;
      distribution.add(MultiserverDistributionPoint(
        n: n,
        probability: pn,
        cumulative: cumulative.clamp(0.0, 1.0),
      ));

      if (n >= c && cumulative >= 0.9999 && n >= 10) break;
    }

    final summary = 'λ = ${lambda.toStringAsFixed(2)} · μ = ${mu.toStringAsFixed(2)} · c = $c';

    return MultiserverQueueResult(
      type: MultiserverQueueModelType.infinite,
      lambda: lambda,
      mu: mu,
      servers: c,
      r: r,
      rho: rho,
      p0: p0,
      ls: ls,
      lq: lq,
      ws: ws,
      wq: wq,
      activeServers: activeServers,
      idleServers: idleServers,
      parameterSummary: summary,
      distribution: distribution,
    );
  }

  // ---------------------------------------------------------------------
  // M/M/c Con Límite en Cola (Capacidad N)
  // ---------------------------------------------------------------------
  static MultiserverQueueResult _calculateFinite({
    required double lambda,
    required double mu,
    required int c,
    required int capacity,
    required double r,
    required double rho,
  }) {
    // 1. P0
    double sum = 0.0;
    for (int n = 0; n < c; n++) {
      sum += math.pow(r, n) / _factorial(n);
    }

    double tailSum = 0.0;
    if ((rho - 1.0).abs() < 1e-9) {
      tailSum = (math.pow(r, c) / _factorial(c)) * (capacity - c + 1);
    } else {
      tailSum = (math.pow(r, c) / _factorial(c)) *
          ((1.0 - math.pow(rho, capacity - c + 1)) / (1.0 - rho));
    }
    final p0 = 1.0 / (sum + tailSum);

    // 2. Distribución Pn y P_N
    final distribution = <MultiserverDistributionPoint>[];
    double cumulative = 0.0;
    final pnList = List<double>.filled(capacity + 1, 0.0);

    for (int n = 0; n <= capacity; n++) {
      double pn;
      if (n <= c) {
        pn = (math.pow(r, n) / _factorial(n)) * p0;
      } else {
        pn = (math.pow(r, n) / (_factorial(c) * math.pow(c, n - c))) * p0;
      }
      pnList[n] = pn;
      cumulative += pn;
      distribution.add(MultiserverDistributionPoint(
        n: n,
        probability: pn,
        cumulative: cumulative.clamp(0.0, 1.0),
      ));
    }

    final pN = pnList[capacity]; // Probabilidad de bloqueo
    final lambdaEff = lambda * (1.0 - pN);
    final lossRate = lambda * pN; // Tasa de pérdida

    // 3. Lq: número promedio de clientes en cola
    double lq = 0.0;
    for (int n = c; n <= capacity; n++) {
      lq += (n - c) * pnList[n];
    }

    // 4. Wq
    final wq = lambdaEff > 0 ? lq / lambdaEff : 0.0;

    // 5. Ws
    final ws = wq + (1.0 / mu);

    // 6. Ls
    final ls = lambdaEff * ws; // Lq + lambdaEff / mu

    // 7. Métricas de servidores
    final activeServers = lambdaEff / mu;
    final idleServers = c - activeServers;

    final summary =
        'λ = ${lambda.toStringAsFixed(2)} · μ = ${mu.toStringAsFixed(2)} · c = $c · N = $capacity';

    return MultiserverQueueResult(
      type: MultiserverQueueModelType.finite,
      lambda: lambda,
      mu: mu,
      servers: c,
      capacity: capacity,
      r: r,
      rho: rho,
      p0: p0,
      ls: ls,
      lq: lq,
      ws: ws,
      wq: wq,
      activeServers: activeServers,
      idleServers: idleServers,
      lambdaEff: lambdaEff,
      lossRate: lossRate,
      blockingProbability: pN,
      parameterSummary: summary,
      distribution: distribution,
    );
  }
}
