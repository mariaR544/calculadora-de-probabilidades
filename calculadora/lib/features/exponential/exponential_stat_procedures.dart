import '../../models/calculation_result.dart';
import '../../models/stat_procedure.dart';

class ExponentialStatProcedures {
  ExponentialStatProcedures._();

  static List<StatProcedure> build(CalculationResult result) {
    final lambda = 1.0 / result.mean;
    final lambdaStr = lambda.toStringAsFixed(4);
    final meanStr = result.mean.toStringAsFixed(4);
    final varianceStr = result.variance.toStringAsFixed(4);
    final stdDevStr = result.stdDev.toStringAsFixed(4);
    final cv = result.coefficientOfVariation;

    return [
      StatProcedure(
        statLabel: 'Promedio E[X]',
        formula: 'E[X] = 1/λ',
        substitution: 'E[X] = 1/$lambdaStr = $meanStr',
        resultText: meanStr,
        description:
            'El tiempo medio entre eventos es el recíproco de λ. '
            'A mayor λ, menor tiempo promedio entre ocurrencias.',
      ),
      StatProcedure(
        statLabel: 'Desv. estándar σ',
        formula: 'σ = 1/λ',
        substitution: 'σ = 1/$lambdaStr = $stdDevStr',
        resultText: stdDevStr,
        description:
            'La desviación estándar es igual a la media: σ = E[X] = 1/λ. '
            'Consecuencia directa de la equidispersión de la Exponencial.',
      ),
      StatProcedure(
        statLabel: 'Varianza Var[X]',
        formula: 'Var(X) = 1/λ^{2}',
        substitution: 'Var(X) = 1/($lambdaStr)^{2} = $varianceStr',
        resultText: varianceStr,
        description:
            'La varianza es el cuadrado de la desviación estándar: '
            'Var(X) = (1/λ)² = 1/λ².',
      ),
      StatProcedure(
        statLabel: 'Asimetría',
        formula: 'γ_{1} = 2  (constante)',
        substitution: 'γ_{1} = 2.0000',
        resultText: '2.0000',
        description:
            'La asimetría de la Exponencial es siempre 2, '
            'independientemente de λ. Indica fuerte sesgo hacia la derecha.',
      ),
      StatProcedure(
        statLabel: 'Curtosis',
        formula: 'κ = 9  (constante)',
        substitution: 'κ = 9.0000',
        resultText: '9.0000',
        description:
            'La curtosis de la Exponencial es siempre 9: '
            'colas mucho más pesadas que la distribución normal.',
      ),
      StatProcedure(
        statLabel: 'Coef. variación (CV)',
        formula: 'CV = σ/μ = (1/λ)/(1/λ) = 1  (constante)',
        substitution: 'CV = 1.0000 ≈ 100.00 %',
        resultText: '${(cv * 100).toStringAsFixed(4)} %',
        description:
            'El coeficiente de variación de la Exponencial es siempre 1 (100%). '
            'Es la única distribución continua con propiedad sin memoria.',
      ),
    ];
  }
}
