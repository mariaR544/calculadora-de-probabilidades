import 'multiserver_queue_model_type.dart';

/// Un punto de la distribución de probabilidad de estado n (P_n) del
/// sistema de colas multicanal, junto con su probabilidad acumulada P(N ≤ n).
class MultiserverDistributionPoint {
  final int n;
  final double probability; // P_n
  final double cumulative; // P(N ≤ n)

  const MultiserverDistributionPoint({
    required this.n,
    required this.probability,
    required this.cumulative,
  });
}

/// Resultado completo de la evaluación de un modelo de colas multicanal (M/M/c):
/// todos los parámetros operativos calculados, métricas de servidores y distribución de estados.
class MultiserverQueueResult {
  final MultiserverQueueModelType type;

  // Parámetros de entrada
  final double lambda;
  final double mu;
  final int servers; // c: número de canales / servidores
  final int? capacity; // N: capacidad máxima del sistema (solo modelo finito)

  // Parámetros derivados
  final double r; // Intensidad de carga λ/μ
  final double rho; // Factor de utilización nominal λ / (c * μ)
  final double p0; // Probabilidad de sistema vacío
  final double ls; // Número esperado de clientes en el sistema
  final double lq; // Número esperado de clientes en la cola
  final double ws; // Tiempo esperado en el sistema
  final double wq; // Tiempo esperado en la cola

  // Métricas de servidores
  final double activeServers; // Promedio de servidores ocupados / activos
  final double idleServers; // Promedio de servidores inactivos / desocupados (c̄)

  // Exclusivos del modelo finito
  final double? lambdaEff; // Tasa efectiva de llegada (λ_eff)
  final double? lossRate; // Tasa de pérdida de clientes (λ - λ_eff)
  final double? blockingProbability; // P_N: probabilidad de bloqueo / rechazo

  final String parameterSummary;
  final List<MultiserverDistributionPoint> distribution;

  const MultiserverQueueResult({
    required this.type,
    required this.lambda,
    required this.mu,
    required this.servers,
    this.capacity,
    required this.r,
    required this.rho,
    required this.p0,
    required this.ls,
    required this.lq,
    required this.ws,
    required this.wq,
    required this.activeServers,
    required this.idleServers,
    this.lambdaEff,
    this.lossRate,
    this.blockingProbability,
    required this.parameterSummary,
    required this.distribution,
  });

  bool get isFinite => type.isFinite;
}

/// Excepción de validación de parámetros de entrada para el módulo multicanal.
class MultiserverValidationException implements Exception {
  final String message;
  const MultiserverValidationException(this.message);

  @override
  String toString() => message;
}
