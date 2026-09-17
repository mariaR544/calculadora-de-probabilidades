/// Procedimiento paso a paso (fórmula + sustitución numérica) para un
/// estadístico descriptivo.
///
/// Usado por el módulo 1 (Poisson) para mostrar al usuario cómo se llegó
/// a cada valor al tocar su tarjeta en [StatSummaryGrid].
///
/// Las cadenas [formula] y [substitution] aceptan la notación DSL de
/// [FormulaText]: `_{sub}` y `^{sup}` para subíndices y superíndices;
/// las letras griegas se escriben directamente en Unicode (λ, σ, γ, κ, √).
class StatProcedure {
  /// Clave de búsqueda: debe coincidir exactamente con el [label]
  /// de la tarjeta en [StatSummaryGrid] (ej: 'Promedio E[X]').
  final String statLabel;

  /// Fórmula simbólica general, mostrada en el paso 1 del modal.
  ///
  /// Ejemplo: `'E[X] = λ'`, `'σ = √λ'`, `'γ_{1} = 1 / √λ'`
  final String formula;

  /// Sustitución numérica con los valores reales del cálculo, mostrada
  /// en el paso 2 del modal.
  ///
  /// Ejemplo: `'E[X] = 3.0000'`, `'γ_{1} = 1 / √3.0000 = 0.5774'`
  final String substitution;

  /// Valor final formateado que se muestra en el recuadro de resultado.
  final String resultText;

  /// Descripción conceptual breve del estadístico (1-2 frases).
  final String description;

  const StatProcedure({
    required this.statLabel,
    required this.formula,
    required this.substitution,
    required this.resultText,
    required this.description,
  });
}
