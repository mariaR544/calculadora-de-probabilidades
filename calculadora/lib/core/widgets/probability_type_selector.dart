import 'package:flutter/material.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Selector de tipo de probabilidad.
///
/// Muestra únicamente la expresión con el signo de la opción
/// actualmente seleccionada (por ejemplo `P(X = k)`). Al pulsarlo, se
/// despliega un pequeño menú con las demás opciones disponibles para
/// la distribución (puntual solo aplica a distribuciones discretas).
class ProbabilityTypeSelector extends StatelessWidget {
  final DistributionType distributionType;
  final ProbabilityType value;
  final ValueChanged<ProbabilityType> onChanged;

  const ProbabilityTypeSelector({
    super.key,
    required this.distributionType,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = ProbabilityTypeX.optionsFor(distributionType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIPO DE PROBABILIDAD', style: AppTextStyles.label),
        const SizedBox(height: 8),
        PopupMenuButton<ProbabilityType>(
          initialValue: value,
          onSelected: onChanged,
          offset: const Offset(0, 50),
          color: AppColors.surface,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          itemBuilder: (context) => options
              .map(
                (o) => PopupMenuItem(
                  value: o,
                  child: Row(
                    children: [
                      Text(
                        o.formulaFor(distributionType),
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: o == value
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (o == value) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded,
                            size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(
                  value.formulaFor(distributionType),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.unfold_more_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}