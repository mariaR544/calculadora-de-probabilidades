import 'package:flutter/material.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bottom sheet educativo que traduce el resultado numérico y los
/// estadísticos descriptivos a lenguaje coloquial.
///
/// Requerimiento: "Explicaciones Educativas de Resultados" — se invoca
/// desde cualquier panel de distribución mediante [ExplanationBottomSheet.show].
class ExplanationBottomSheet extends StatelessWidget {
  final CalculationResult result;
  final DistributionType distributionType;
  final ProbabilityType probabilityType;

  /// Límite superior (xⱼ), solo aplica cuando [probabilityType]
  /// requiere dos entradas (rangos).
  final double? upperX;

  const ExplanationBottomSheet({
    super.key,
    required this.result,
    required this.distributionType,
    required this.probabilityType,
    this.upperX,
  });

  /// Punto de entrada único: despliega el modal con el estilo estándar
  /// (bordes redondeados, altura acotada, fondo transparente para que
  /// se vea el `borderRadius` del contenedor interno).
  static Future<void> show(
    BuildContext context, {
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExplanationBottomSheet(
        result: result,
        distributionType: distributionType,
        probabilityType: probabilityType,
        upperX: upperX,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            _Header(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExplanationSection(
                      icon: Icons.percent_rounded,
                      title: 'INTERPRETACIÓN DEL RESULTADO',
                      child: _BodyCard(
                        text: ExplanationTextGenerator.probabilityText(
                          result: result,
                          distributionType: distributionType,
                          probabilityType: probabilityType,
                          upperX: upperX,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExplanationSection(
                      icon: Icons.insights_rounded,
                      title: 'SIGNIFICADO DE LOS ESTADÍSTICOS',
                      child: Column(
                        children: ExplanationTextGenerator
                            .statisticsExplanations(
                          result: result,
                          distributionType: distributionType,
                        )
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StatExplanationCard(
                                  label: e.label,
                                  text: e.text,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Generación de texto dinámico
// ---------------------------------------------------------------------

/// Traduce los resultados numéricos de [CalculationResult] a texto
/// coloquial. Separado de la UI para poder testearlo de forma aislada.
class ExplanationTextGenerator {
  const ExplanationTextGenerator._();

  static String probabilityText({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) {
    final pct = (result.probability * 100).toStringAsFixed(2);
    final mean = result.mean.toStringAsFixed(2);
    final x = _formatX(result.evaluatedX);
    final xj = upperX != null ? _formatX(upperX) : x;
    final isDiscrete = distributionType.isDiscrete;
    final unit = isDiscrete ? 'eventos' : 'unidades de tiempo/espacio';

    switch (probabilityType) {
      case ProbabilityType.puntual:
        return 'Existe un $pct% de probabilidad de que ocurran '
            'exactamente $x $unit en el intervalo, dado un promedio '
            'esperado de $mean $unit.';

      case ProbabilityType.mayorQue:
        return isDiscrete
            ? 'Existe un $pct% de probabilidad de que ocurran más de $x '
                'eventos, dado un promedio esperado de $mean eventos.'
            : 'Existe un $pct% de probabilidad de que el evento ocurra '
                'después de $x unidades de tiempo/espacio.';

      case ProbabilityType.menorQue:
        return isDiscrete
            ? 'Existe un $pct% de probabilidad de que ocurran menos de '
                '$x eventos, dado un promedio esperado de $mean eventos.'
            : 'Existe un $pct% de probabilidad de que el evento ocurra '
                'antes de $x unidades de tiempo/espacio.';

      case ProbabilityType.mayorOIgual:
        return isDiscrete
            ? 'Existe un $pct% de probabilidad de que ocurran $x o más '
                'eventos, dado un promedio esperado de $mean eventos.'
            : 'Existe un $pct% de probabilidad de que el evento ocurra '
                'en un tiempo igual o mayor a $x unidades.';

      case ProbabilityType.menorOIgual:
        return isDiscrete
            ? 'Existe un $pct% de probabilidad de que ocurran $x o menos '
                'eventos, dado un promedio esperado de $mean eventos.'
            : 'Existe un $pct% de probabilidad de que el evento ocurra '
                'en un tiempo igual o menor a $x unidades.';

      case ProbabilityType.estrictoRango:
        return 'Existe un $pct% de probabilidad de que el valor '
            'observado quede estrictamente entre $x y $xj $unit '
            '(ambos límites excluidos).';

      case ProbabilityType.cerradoRango:
        return 'Existe un $pct% de probabilidad de que el valor '
            'observado quede entre $x y $xj $unit (ambos límites '
            'incluidos).';

      case ProbabilityType.izqCerradoDerAbierto:
        return 'Existe un $pct% de probabilidad de que el valor '
            'observado quede entre $x (incluido) y $xj $unit '
            '(excluido).';

      case ProbabilityType.izqAbiertoDerCerrado:
        return 'Existe un $pct% de probabilidad de que el valor '
            'observado quede entre $x (excluido) y $xj $unit '
            '(incluido).';
    }
  }

  static List<StatExplanation> statisticsExplanations({
    required CalculationResult result,
    required DistributionType distributionType,
  }) {
    final mean = result.mean.toStringAsFixed(4);
    final stdDev = result.stdDev.toStringAsFixed(4);
    final unit = distributionType.isDiscrete ? 'ocurrencias' : 'unidades';

    return [
      StatExplanation(
        label: 'Promedio (μ) y Desviación estándar (σ)',
        text: 'En promedio se esperan $mean $unit en el intervalo '
            'definido, con una dispersión típica de ±$stdDev $unit '
            'respecto a ese valor central.',
      ),
      StatExplanation(
        label: 'Asimetría (Skewness)',
        text: _skewnessInterpretation(result.skewness),
      ),
      StatExplanation(
        label: 'Curtosis',
        text: _kurtosisInterpretation(result.kurtosis),
      ),
      StatExplanation(
        label: 'Coeficiente de variación (CV)',
        text: _cvInterpretation(result.coefficientOfVariation),
      ),
    ];
  }

  static String _formatX(double x) {
    // Enteros sin decimales (Poisson); continuos con 2 decimales.
    return x == x.roundToDouble()
        ? x.toInt().toString()
        : x.toStringAsFixed(2);
  }

  static String _skewnessInterpretation(double skew) {
    final v = skew.toStringAsFixed(4);
    if (skew > 0.05) {
      return 'El valor de asimetría ($v) es positivo: la distribución '
          'está sesgada a la derecha. La mayoría de los valores se '
          'concentran en la parte baja, con una cola larga hacia '
          'valores más altos.';
    } else if (skew < -0.05) {
      return 'El valor de asimetría ($v) es negativo: la distribución '
          'está sesgada a la izquierda. Predominan los valores altos, '
          'con una cola hacia valores más bajos.';
    }
    return 'El valor de asimetría ($v) es cercano a cero: la '
        'distribución es aproximadamente simétrica alrededor de su '
        'promedio.';
  }

  static String _kurtosisInterpretation(double kurtosis) {
    final v = kurtosis.toStringAsFixed(4);
    if (kurtosis > 3.05) {
      return 'La curtosis ($v) es mayor a 3: la distribución es '
          'leptocúrtica, con colas más pesadas y un pico más '
          'pronunciado que una distribución normal (mayor probabilidad '
          'de valores extremos).';
    } else if (kurtosis < 2.95) {
      return 'La curtosis ($v) es menor a 3: la distribución es '
          'platicúrtica, con colas más ligeras y una forma más '
          'aplanada que una distribución normal.';
    }
    return 'La curtosis ($v) es cercana a 3: la forma de la '
        'distribución es similar a la de una distribución normal '
        '(mesocúrtica).';
  }

  static String _cvInterpretation(double cv) {
    final pct = (cv * 100).toStringAsFixed(2);
    if (cv < 0.10) {
      return 'El coeficiente de variación es de $pct%, lo que refleja '
          'una variabilidad baja: los valores tienden a mantenerse '
          'cercanos al promedio.';
    } else if (cv <= 0.30) {
      return 'El coeficiente de variación es de $pct%, lo que refleja '
          'una variabilidad moderada respecto al promedio.';
    }
    return 'El coeficiente de variación es de $pct%, lo que refleja '
        'una variabilidad alta: los valores pueden alejarse '
        'considerablemente del promedio.';
  }
}

/// Par label/texto usado para renderizar cada tarjeta de estadístico.
class StatExplanation {
  final String label;
  final String text;
  const StatExplanation({required this.label, required this.text});
}

// ---------------------------------------------------------------------
// Sub-widgets de presentación
// ---------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Explicación del resultado',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ExplanationSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BodyCard extends StatelessWidget {
  final String text;
  const _BodyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.body.copyWith(height: 1.4)),
    );
  }
}

class _StatExplanationCard extends StatelessWidget {
  final String label;
  final String text;

  const _StatExplanationCard({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(text, style: AppTextStyles.body.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}