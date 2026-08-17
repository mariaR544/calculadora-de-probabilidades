/// Un punto a graficar en el plano cartesiano.
///
/// [highlighted] indica si este punto (barra en Poisson, o segmento de
/// curva en Exponencial) forma parte de la región que satisface la
/// condición de probabilidad evaluada, y por lo tanto debe pintarse
/// con el color de resalte.
class ChartPoint {
  final double x;
  final double y;
  final bool highlighted;

  const ChartPoint({
    required this.x,
    required this.y,
    required this.highlighted,
  });
}

/// Resultado completo de una evaluación: probabilidad, momentos y los
/// puntos necesarios para dibujar la gráfica correspondiente.
class CalculationResult {
  final double probability;
  final double mean;
  final double variance;
  final String parameterSummary;
  final List<ChartPoint> points;
  final bool isDiscrete;
  final double evaluatedX;

  const CalculationResult({
    required this.probability,
    required this.mean,
    required this.variance,
    required this.parameterSummary,
    required this.points,
    required this.isDiscrete,
    required this.evaluatedX,
  });
}

/// Excepción de validación de parámetros de entrada, con un mensaje
/// listo para mostrar al usuario.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}
