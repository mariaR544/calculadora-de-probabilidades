import 'package:flutter/material.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Panel que resalta el resultado principal (probabilidad calculada) y,
/// debajo, un sub-panel dedicado a la Esperanza Matemática y la
/// Varianza, tal como pide el requerimiento de "Cálculo y Muestreo de
/// Momentos".
class ResultsPanel extends StatelessWidget {
  final CalculationResult result;
  final DistributionType distributionType;
  final ProbabilityType probabilityType;

  const ResultsPanel({
    super.key,
    required this.result,
    required this.distributionType,
    required this.probabilityType,
  });

  @override
  Widget build(BuildContext context) {
    final formula = probabilityType.formulaFor(distributionType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESULTADO', style: AppTextStyles.label),
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
    );
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
