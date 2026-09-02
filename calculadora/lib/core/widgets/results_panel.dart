import 'package:flutter/material.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Formatea un número decimal eliminando ceros innecesarios al final
String _formatNum(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  if (s.contains('.')) {
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// Formatea un resultado a decimales fijos
String _formatFixed(double v, [int decimals = 4]) =>
    v.toStringAsFixed(decimals);

/// Analiza una cadena buscando notación `_` para subíndices y `^` para superíndices,
/// normalizando caracteres Unicode y renderizando mediante [WidgetSpan] con alineación
/// precisa de línea base para soporte universal.
List<InlineSpan> _parseFormulaSpans(String text, TextStyle baseStyle) {
  final normalized = text
      .replaceAll('ₛ', '_s')
      .replaceAll('ᵩ', '_q')
      .replaceAll('₀', '_0')
      .replaceAll('₁', '_1')
      .replaceAll('₂', '_2')
      .replaceAll('₃', '_3')
      .replaceAll('₄', '_4')
      .replaceAll('₅', '_5')
      .replaceAll('₆', '_6')
      .replaceAll('₇', '_7')
      .replaceAll('₈', '_8')
      .replaceAll('₉', '_9')
      .replaceAll('ₙ', '_n')
      .replaceAll('ₘ', '_m')
      .replaceAll('ᵢ', '_i')
      .replaceAll('ⱼ', '_j')
      .replaceAll('ₖ', '_k')
      .replaceAll('⁰', '^0')
      .replaceAll('¹', '^1')
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll('⁴', '^4')
      .replaceAll('⁵', '^5')
      .replaceAll('⁶', '^6')
      .replaceAll('⁷', '^7')
      .replaceAll('⁸', '^8')
      .replaceAll('⁹', '^9')
      .replaceAll('ⁿ', '^n')
      .replaceAll('ᴺ', '^N')
      .replaceAll('⁺', '^+')
      .replaceAll('⁻', '^-');

  final List<InlineSpan> spans = [];
  final double fontSize = baseStyle.fontSize ?? 12.0;
  final double subSupSize = (fontSize * 0.72).clamp(8.0, 16.0);
  final subSupStyle = baseStyle.copyWith(
    fontSize: subSupSize,
    fontWeight: FontWeight.w600,
  );

  int i = 0;
  while (i < normalized.length) {
    if (normalized[i] == '_') {
      i++;
      String sub = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        final closeChar = normalized[i] == '{' ? '}' : ')';
        i++;
        while (i < normalized.length && normalized[i] != closeChar) {
          sub += normalized[i];
          i++;
        }
        if (i < normalized.length) i++;
      } else {
        while (i < normalized.length &&
            RegExp(r'[a-zA-Z0-9]').hasMatch(normalized[i])) {
          sub += normalized[i];
          i++;
        }
      }
      if (sub.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, fontSize * 0.28),
              child: Text(sub, style: subSupStyle),
            ),
          ),
        );
      }
    } else if (normalized[i] == '^') {
      i++;
      String sup = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        i++;
        int depth = 1;
        while (i < normalized.length && depth > 0) {
          if (normalized[i] == '{' || normalized[i] == '(') depth++;
          if (normalized[i] == '}' || normalized[i] == ')') depth--;
          if (depth > 0) sup += normalized[i];
          i++;
        }
      } else {
        while (i < normalized.length &&
            RegExp(r'[a-zA-Z0-9\+\-]').hasMatch(normalized[i])) {
          sup += normalized[i];
          i++;
        }
      }
      if (sup.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, -fontSize * 0.38),
              child: Text(sup, style: subSupStyle),
            ),
          ),
        );
      }
    } else {
      String normal = '';
      while (i < normalized.length &&
          normalized[i] != '_' &&
          normalized[i] != '^') {
        normal += normalized[i];
        i++;
      }
      if (normal.isNotEmpty) {
        spans.add(TextSpan(text: normal, style: baseStyle));
      }
    }
  }
  return spans;
}

/// Panel que resalta el resultado principal (probabilidad calculada), sub-panel
/// de Esperanza/Varianza y acordeón con Desglose Teórico y Sustituciones Paso a Paso.
class ResultsPanel extends StatelessWidget {
  final CalculationResult result;
  final DistributionType distributionType;
  final ProbabilityType probabilityType;
  final double? upperX;

  const ResultsPanel({
    super.key,
    required this.result,
    required this.distributionType,
    required this.probabilityType,
    this.upperX,
  });

  @override
  Widget build(BuildContext context) {
    final formula = probabilityType.formulaFor(distributionType);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESULTADO', style: AppTextStyles.label),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      result.probability.toStringAsFixed(6),
                      style: AppTextStyles.resultValue,
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(formula, style: AppTextStyles.subtitle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(result.parameterSummary, style: AppTextStyles.subtitle),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MomentBlock(
                        label: 'Esperanza  E[X]',
                        value: result.mean,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _MomentBlock(
                        label: 'Varianza  Var(X)',
                        value: result.variance,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- Módulo Educativo: Desglose Teórico y Fórmulas Paso a Paso ---
        Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.functions_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'Desglose Teórico y Fórmulas',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Toca para ver el desarrollo y sustitución numérica',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 4),
                    ..._buildSteps(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSteps() {
    if (distributionType == DistributionType.poisson) {
      return _buildPoissonSteps();
    } else {
      return _buildExponentialSteps();
    }
  }

  List<Widget> _buildPoissonSteps() {
    final double lambda = result.mean;
    final String lambdaStr = _formatNum(lambda);
    final int x = result.evaluatedX.toInt();
    final int? x2 = upperX?.toInt();
    final String probStr = _formatFixed(result.probability, 6);

    String probTitle;
    String probFormula;
    String probSubstitution;
    String probDescription;

    switch (probabilityType) {
      case ProbabilityType.puntual:
        probTitle = '1. Probabilidad Puntual P(X = x)';
        probFormula = 'P(X = x) = (e^(-λ) · λ^x) / x!';
        probSubstitution =
            'P(X = $x) = (e^(-$lambdaStr) · ($lambdaStr)^$x) / $x! = $probStr';
        probDescription =
            'Probabilidad exacta de observar exactamente $x eventos en el intervalo evaluado.';
        break;

      case ProbabilityType.menorOIgual:
        probTitle = '1. Probabilidad Acumulada Inferior P(X ≤ x)';
        probFormula = 'P(X ≤ x) = ∑_(k=0)^x (e^(-λ) · λ^k) / k!';
        probSubstitution =
            'P(X ≤ $x) = ∑_(k=0)^$x (e^(-$lambdaStr) · ($lambdaStr)^k) / k! = $probStr';
        probDescription =
            'Suma de probabilidades puntuales desde k = 0 hasta k = $x.';
        break;

      case ProbabilityType.menorQue:
        final int xMinus1 = x - 1;
        probTitle = '1. Probabilidad Acumulada Estricta P(X < x)';
        probFormula = 'P(X < x) = P(X ≤ x − 1) = ∑_(k=0)^(x-1) (e^(-λ) · λ^k) / k!';
        probSubstitution =
            'P(X < $x) = P(X ≤ $xMinus1) = $probStr';
        probDescription =
            'Suma de probabilidades puntuales desde k = 0 hasta k = $xMinus1.';
        break;

      case ProbabilityType.mayorOIgual:
        final int xMinus1 = x - 1;
        final double compVal = (1.0 - result.probability).clamp(0.0, 1.0);
        probTitle = '1. Probabilidad Acumulada Superior P(X ≥ x)';
        probFormula = 'P(X ≥ x) = 1 − P(X ≤ x − 1)';
        probSubstitution =
            'P(X ≥ $x) = 1 − P(X ≤ $xMinus1) = 1 − ${_formatFixed(compVal, 6)} = $probStr';
        probDescription =
            'Complemento de la probabilidad acumulada inferior hasta k = $xMinus1.';
        break;

      case ProbabilityType.mayorQue:
        final double compVal = (1.0 - result.probability).clamp(0.0, 1.0);
        probTitle = '1. Probabilidad Acumulada Superior Estricta P(X > x)';
        probFormula = 'P(X > x) = 1 − P(X ≤ x)';
        probSubstitution =
            'P(X > $x) = 1 − P(X ≤ $x) = 1 − ${_formatFixed(compVal, 6)} = $probStr';
        probDescription =
            'Complemento de la probabilidad acumulada inferior hasta k = $x.';
        break;

      case ProbabilityType.cerradoRango:
        final int x2Val = x2 ?? x;
        final int xMinus1 = x - 1;
        probTitle = '1. Probabilidad en Rango Cerrado P(x_i ≤ X ≤ x_j)';
        probFormula = 'P(x_i ≤ X ≤ x_j) = P(X ≤ x_j) − P(X ≤ x_i − 1)';
        probSubstitution =
            'P($x ≤ X ≤ $x2Val) = P(X ≤ $x2Val) − P(X ≤ $xMinus1) = $probStr';
        probDescription =
            'Diferencia entre las probabilidades acumuladas en los límites [$x, $x2Val].';
        break;

      case ProbabilityType.estrictoRango:
        final int x2Val = x2 ?? x;
        final int x2Minus1 = x2Val - 1;
        probTitle = '1. Probabilidad en Rango Abierto P(x_i < X < x_j)';
        probFormula = 'P(x_i < X < x_j) = P(X ≤ x_j − 1) − P(X ≤ x_i)';
        probSubstitution =
            'P($x < X < $x2Val) = P(X ≤ $x2Minus1) − P(X ≤ $x) = $probStr';
        probDescription =
            'Probabilidad de que el número de eventos esté estrictamente entre $x y $x2Val.';
        break;

      case ProbabilityType.izqCerradoDerAbierto:
        final int x2Val = x2 ?? x;
        final int x2Minus1 = x2Val - 1;
        final int xMinus1 = x - 1;
        probTitle = '1. Probabilidad en Rango Semiabierto P(x_i ≤ X < x_j)';
        probFormula = 'P(x_i ≤ X < x_j) = P(X ≤ x_j − 1) − P(X ≤ x_i − 1)';
        probSubstitution =
            'P($x ≤ X < $x2Val) = P(X ≤ $x2Minus1) − P(X ≤ $xMinus1) = $probStr';
        probDescription =
            'Probabilidad acumulada en el intervalo semiabierto [$x, $x2Val).';
        break;

      case ProbabilityType.izqAbiertoDerCerrado:
        final int x2Val = x2 ?? x;
        probTitle = '1. Probabilidad en Rango Semiabierto P(x_i < X ≤ x_j)';
        probFormula = 'P(x_i < X ≤ x_j) = P(X ≤ x_j) − P(X ≤ x_i)';
        probSubstitution =
            'P($x < X ≤ $x2Val) = P(X ≤ $x2Val) − P(X ≤ $x) = $probStr';
        probDescription =
            'Probabilidad acumulada en el intervalo semiabierto ($x, $x2Val].';
        break;
    }

    return [
      _StepItem(
        title: probTitle,
        formula: probFormula,
        substitution: probSubstitution,
        description: probDescription,
        valueText: probStr,
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '2. Esperanza Matemática E[X]',
        formula: 'E[X] = λ',
        substitution: 'E[X] = $lambdaStr = ${_formatFixed(result.mean)}',
        description:
            'Valor promedio o media esperada de ocurrencias en el intervalo evaluado.',
        valueText: result.mean.toStringAsFixed(4),
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '3. Varianza Var(X)',
        formula: 'Var(X) = λ',
        substitution: 'Var(X) = $lambdaStr = ${_formatFixed(result.variance)}',
        description:
            'En la distribución de Poisson, la varianza es idéntica a la media λ (propiedad de equidispersion).',
        valueText: result.variance.toStringAsFixed(4),
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '4. Desviación Estándar (σ)',
        formula: 'σ = √(Var(X)) = √λ',
        substitution: 'σ = √($lambdaStr) = ${_formatFixed(result.stdDev)}',
        description:
            'Medida de dispersión de los datos alrededor del valor medio esperado.',
        valueText: result.stdDev.toStringAsFixed(4),
      ),
    ];
  }

  List<Widget> _buildExponentialSteps() {
    final double lambda = result.mean > 0 ? 1 / result.mean : 1.0;
    final String lambdaStr = _formatNum(lambda);
    final double xi = result.evaluatedX;
    final String xiStr = _formatNum(xi);
    final double? xj = upperX;
    final String? xjStr = xj != null ? _formatNum(xj) : null;
    final String probStr = _formatFixed(result.probability, 6);

    String probTitle;
    String probFormula;
    String probSubstitution;
    String probDescription;

    switch (probabilityType) {
      case ProbabilityType.mayorOIgual:
      case ProbabilityType.mayorQue:
        final double expVal = lambda * xi;
        probTitle = '1. Probabilidad de Cola Superior P(X ≥ x)';
        probFormula = 'P(X ≥ x) = e^(-λ · x)';
        probSubstitution =
            'P(X ≥ $xiStr) = e^(-($lambdaStr) · ($xiStr)) = e^(-${_formatNum(expVal)}) = $probStr';
        probDescription =
            'Probabilidad de que el tiempo o distancia transcurrido sea al menos $xiStr.';
        break;

      case ProbabilityType.menorOIgual:
      case ProbabilityType.menorQue:
        final double expVal = lambda * xi;
        probTitle = '1. Probabilidad Acumulada Inferior P(X ≤ x)';
        probFormula = 'P(X ≤ x) = 1 − e^(-λ · x)';
        probSubstitution =
            'P(X ≤ $xiStr) = 1 − e^(-($lambdaStr) · ($xiStr)) = 1 − e^(-${_formatNum(expVal)}) = $probStr';
        probDescription =
            'Probabilidad acumulada de que el evento ocurra en un tiempo o distancia ≤ $xiStr.';
        break;

      case ProbabilityType.cerradoRango:
      case ProbabilityType.estrictoRango:
      case ProbabilityType.izqCerradoDerAbierto:
      case ProbabilityType.izqAbiertoDerCerrado:
        final String x2S = xjStr ?? xiStr;
        final double x2D = xj ?? xi;
        final double exp1 = lambda * xi;
        final double exp2 = lambda * x2D;
        probTitle = '1. Probabilidad en Rango P(x_i ≤ X ≤ x_j)';
        probFormula = 'P(x_i ≤ X ≤ x_j) = e^(-λ · x_i) − e^(-λ · x_j)';
        probSubstitution =
            'P($xiStr ≤ X ≤ $x2S) = e^(-${_formatNum(exp1)}) − e^(-${_formatNum(exp2)}) = $probStr';
        probDescription =
            'Probabilidad de que el tiempo transcurrido se encuentre en el intervalo [$xiStr, $x2S].';
        break;

      default:
        probTitle = '1. Probabilidad Acumulada';
        probFormula = 'P(X) = F(x)';
        probSubstitution = 'P(X) = $probStr';
        probDescription = 'Probabilidad evaluada.';
        break;
    }

    return [
      _StepItem(
        title: probTitle,
        formula: probFormula,
        substitution: probSubstitution,
        description: probDescription,
        valueText: probStr,
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '2. Esperanza Matemática E[X]',
        formula: 'E[X] = 1 / λ',
        substitution: 'E[X] = 1 / $lambdaStr = ${_formatFixed(result.mean)}',
        description:
            'Tiempo medio esperado entre llegadas u ocurrencias sucesivas del proceso.',
        valueText: result.mean.toStringAsFixed(4),
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '3. Varianza Var(X)',
        formula: 'Var(X) = 1 / λ^2',
        substitution:
            'Var(X) = 1 / ($lambdaStr)^2 = ${_formatFixed(result.variance)}',
        description:
            'Dispersión cuadrática del tiempo entre eventos en la distribución exponencial continua.',
        valueText: result.variance.toStringAsFixed(4),
      ),
      const SizedBox(height: 14),
      _StepItem(
        title: '4. Desviación Estándar (σ)',
        formula: 'σ = 1 / λ',
        substitution: 'σ = 1 / $lambdaStr = ${_formatFixed(result.stdDev)}',
        description:
            'En la distribución exponencial, la desviación estándar es numéricamente igual a la esperanza matemática.',
        valueText: result.stdDev.toStringAsFixed(4),
      ),
    ];
  }
}

class _MomentBlock extends StatelessWidget {
  final String label;
  final double value;
  final bool alignEnd;

  const _MomentBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? 16 : 0,
        right: alignEnd ? 0 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(4), style: AppTextStyles.momentValue),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String title;
  final String formula;
  final String substitution;
  final String description;
  final String valueText;

  const _StepItem({
    required this.title,
    required this.formula,
    required this.substitution,
    required this.description,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final formulaBaseStyle = const TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: [
        'Segoe UI',
        'Roboto',
        'Noto Sans',
        'Arial',
        'sans-serif',
      ],
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                    children: _parseFormulaSpans(
                      title,
                      AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Res: $valueText',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Bloque 1: Fórmula teórica general ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: RichText(
              text: TextSpan(
                style: formulaBaseStyle,
                children: [
                  TextSpan(
                    text: 'Fórmula: ',
                    style: formulaBaseStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ..._parseFormulaSpans(formula, formulaBaseStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // --- Bloque 2: Sustitución con los datos ingresados ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: RichText(
              text: TextSpan(
                style: formulaBaseStyle,
                children: [
                  TextSpan(
                    text: 'Sustitución: ',
                    style: formulaBaseStyle.copyWith(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ..._parseFormulaSpans(substitution, formulaBaseStyle),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.subtitle.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
