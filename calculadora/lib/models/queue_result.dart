import 'queue_model_type.dart';

/// Un punto de la distribución de probabilidad de estado n (P_n) del
/// sistema de colas, junto con su probabilidad acumulada P(N ≤ n).
class QueueDistributionPoint {
  final int n;
  final double probability; // P_n
  final double cumulative; // P(N ≤ n)

  const QueueDistributionPoint({
    required this.n,
    required this.probability,
    required this.cumulative,
  });
}

/// Resultado completo de la evaluación de un modelo de colas: todos
/// los parámetros operativos calculados y la distribución de
/// probabilidad de estado del sistema (para tabla y gráficos).
class QueueResult {
  final QueueModelType type;

  // Parámetros de entrada
  final double lambda;
  final double mu;
  final int? capacity; // N, solo aplica al modelo finito

  // Parámetros derivados
  final double rho; // Factor de utilización λ/μ
  final double p0; // Probabilidad de sistema vacío
  final double ls; // Número esperado de clientes en el sistema
  final double lq; // Número esperado de clientes en la cola
  final double ws; // Tiempo esperado en el sistema
  final double wq; // Tiempo esperado en la cola

  // Exclusivos del modelo finito
  final double? lambdaEff; // Tasa efectiva de llegada (λ_eff)
  final double? lossRate; // Tasa de pérdida de clientes (λ - λ_eff)
  final double? blockingProbability; // P_N: probabilidad de rechazo

  final String parameterSummary;
  final List<QueueDistributionPoint> distribution;

  const QueueResult({
    required this.type,
    required this.lambda,
    required this.mu,
    this.capacity,
    required this.rho,
    required this.p0,
    required this.ls,
    required this.lq,
    required this.ws,
    required this.wq,
    this.lambdaEff,
    this.lossRate,
    this.blockingProbability,
    required this.parameterSummary,
    required this.distribution,
  });

  bool get isFinite => type.isFinite;
}

/// Excepción de validación de parámetros de entrada del módulo de
/// colas, con un mensaje listo para mostrar al usuario.
class QueueValidationException implements Exception {
  final String message;
  const QueueValidationException(this.message);

  @override
  String toString() => message;
}
