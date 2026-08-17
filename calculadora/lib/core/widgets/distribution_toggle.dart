import 'package:flutter/material.dart';
import '../../models/distribution_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Menú para alternar entre las distribuciones disponibles.
///
/// Requerimiento: "Selección de Distribución: Menú para alternar entre
/// Poisson y Exponencial". Implementado como un selector de dos
/// pestañas para que el cambio sea inmediato y visualmente evidente.
class DistributionToggle extends StatelessWidget {
  final DistributionType value;
  final ValueChanged<DistributionType> onChanged;

  const DistributionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: DistributionType.values.map((type) {
          final selected = type == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  children: [
                    Text(
                      type.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      type.natureLabel,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 11,
                        color: selected
                            ? AppColors.textOnPrimary.withValues(alpha: 0.85)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
