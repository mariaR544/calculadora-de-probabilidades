import '../../models/calculation_result.dart';
import '../../models/stat_procedure.dart';

class PoissonStatProcedures {
  PoissonStatProcedures._();

  static List<StatProcedure> build(CalculationResult result) {
    final lambda = result.mean;
    final lambdaStr = lambda.toStringAsFixed(4);
    final stdDev = result.stdDev;
    final cv = result.coefficientOfVariation;

    return [
      StatProcedure(
        statLabel: 'Promedio E[X]',
        formula: 'E[X] = λ',
        substitution: 'E[X] = $lambdaStr',
        resultText: result.mean.toStringAsFixed(4),
        description:
            'En Poisson el valor esperado es igual al parámetro λ: '
            'es el promedio de ocurrencias por intervalo.',
      ),
      StatProcedure(
        statLabel: 'Desv. estándar σ',
        formula: 'σ = √λ',
        substitution: 'σ = √$lambdaStr = ${stdDev.toStringAsFixed(4)}',
        resultText: stdDev.toStringAsFixed(4),
        description:
            'La desviación estándar es la raíz cuadrada de λ. '
            'Mide la dispersión típica alrededor de la media.',
      ),
      StatProcedure(
        statLabel: 'Varianza Var[X]',
        formula: 'Var(X) = λ',
        substitution:
            'Var(X) = $lambdaStr = ${result.variance.toStringAsFixed(4)}',
        resultText: result.variance.toStringAsFixed(4),
        description:
            'Poisson es equidispersa: la varianza es idéntica a la media. '
            'Ambas son iguales a λ.',
      ),
      StatProcedure(
        statLabel: 'Asimetría',
        formula: 'γ_{1} = 1 / √λ',
        substitution:
            'γ_{1} = 1 / √$lambdaStr = ${result.skewness.toStringAsFixed(4)}',
        resultText: result.skewness.toStringAsFixed(4),
        description:
            'Siempre positiva: indica que la distribución tiene cola '
            'más larga hacia los valores grandes.',
      ),
      StatProcedure(
        statLabel: 'Curtosis',
        formula: 'κ = 3 + 1/λ',
        substitution:
            'κ = 3 + 1/$lambdaStr = ${result.kurtosis.toStringAsFixed(4)}',
        resultText: result.kurtosis.toStringAsFixed(4),
        description:
            'Siempre mayor que 3 (leptocúrtica). Se acerca a 3 cuando λ → ∞.',
      ),
      StatProcedure(
        statLabel: 'Coef. variación (CV)',
        formula: 'CV = σ/μ = √λ/λ = 1/√λ',
        substitution:
            'CV = 1/√$lambdaStr = ${cv.toStringAsFixed(4)} ≈ ${(cv * 100).toStringAsFixed(2)} %',
        resultText: '${(cv * 100).toStringAsFixed(4)} %',
        description:
            'Mide la variabilidad relativa respecto a la media. '
            'Decrece a medida que λ aumenta.',
      ),
    ];
  }
}
