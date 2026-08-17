import 'package:flutter/material.dart';
import '../../models/distribution_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'section_title.dart';

/// Tarjeta colapsable con la teoría breve, las fórmulas de PDF/CDF,
/// los momentos (E[X], Var(X)) y las restricciones de validación de la
/// distribución seleccionada.
///
/// Requerimiento: "Fórmulas y Teoría Visibles" — se mantiene siempre
/// visible en pantalla antes y durante el cálculo.
class FormulaCard extends StatelessWidget {
  final DistributionType type;

  const FormulaCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPoisson = type == DistributionType.poisson;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              text: '${type.label} · ${type.natureLabel}',
              icon: Icons.functions_rounded,
            ),
            const SizedBox(height: 10),
            Text(type.description, style: AppTextStyles.body),
            const SizedBox(height: 16),
            _FormulaRow(
              label: isPoisson ? 'PMF' : 'PDF',
              formula: isPoisson
                  ? 'P(X = x) = λ^x·e^(-λ) / x!'
                  : 'f(x) = λ·e^(-λx),  x > 0',
            ),
            const SizedBox(height: 8),
            _FormulaRow(
              label: 'CDF',
              formula: isPoisson
                  ? 'P(X ≤ x) = Σ (λⁱ·e^(-λ) / i!),  i = 0..x'
                  : 'P(X ≤ x) = 1 - e^(-λx)',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MomentTile(
                    label: 'E[X]',
                    formula: isPoisson ? 'λ' : '1 / λ',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MomentTile(
                    label: 'Var(X)',
                    formula: isPoisson ? 'λ' : '1 / λ²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RestrictionsNote(
              text: isPoisson
                  ? 'Restricciones: λ > 0  y  x ∈ ℤ≥0'
                  : 'Restricciones: λ > 0  y  x ≥ 0',
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String formula;

  const _FormulaRow({required this.label, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: AppTextStyles.label),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formula,
              style: AppTextStyles.formula,
            ),
          ),
        ),
      ],
    );
  }
}

class _MomentTile extends StatelessWidget {
  final String label;
  final String formula;

  const _MomentTile({required this.label, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.label),
          const Spacer(),
          Text(formula, style: AppTextStyles.formula),
        ],
      ),
    );
  }
}

class _RestrictionsNote extends StatelessWidget {
  final String text;
  const _RestrictionsNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.subtitle,
          ),
        ),
      ],
    );
  }
}