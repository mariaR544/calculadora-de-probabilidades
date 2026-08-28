import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_title.dart';
import '../../models/queue_model_type.dart';

/// Tarjeta con la teoría breve y las fórmulas del modelo de colas
/// seleccionado. Mismo lenguaje visual que `FormulaCard` del Módulo 1
/// (badges, grid de fórmulas, caja de restricciones).
class QueueFormulaCard extends StatelessWidget {
  final QueueModelType type;

  const QueueFormulaCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final data = _QueueFormulaData.forType(type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              text: '${type.label} · ${type.kendallNotation}',
              icon: Icons.functions_rounded,
            ),
            const SizedBox(height: 10),
            Text(type.description, style: AppTextStyles.body),

            const SizedBox(height: 20),
            Text('FÓRMULAS PRINCIPALES', style: AppTextStyles.label),
            const SizedBox(height: 10),
            for (final f in data.formulas) ...[
              _FormulaBadgeTile(badge: f.badge, formula: f.formula),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 12),
            _RestrictionsBox(text: data.restrictions),
          ],
        ),
      ),
    );
  }
}

class _Formula {
  final String badge;
  final String formula;
  const _Formula(this.badge, this.formula);
}

class _QueueFormulaData {
  final List<_Formula> formulas;
  final String restrictions;

  const _QueueFormulaData({required this.formulas, required this.restrictions});

  static _QueueFormulaData forType(QueueModelType type) {
    if (type.isFinite) {
      return const _QueueFormulaData(
        formulas: [
          _Formula('ρ', 'ρ = λ / μ'),
          _Formula('P₀', 'P₀ = (1 − ρ) / (1 − ρ^(N+1))    [ρ ≠ 1]'),
          _Formula('Pₙ', 'Pₙ = P₀ · ρⁿ ,   0 ≤ n ≤ N'),
          _Formula('λ_eff', 'λ_eff = λ · (1 − P_N)'),
          _Formula('Pérdida', 'Tasa de pérdida = λ − λ_eff = λ · P_N'),
          _Formula('Lₛ',
              'Lₛ = ρ[1 − (N+1)ρᴺ + Nρ^(N+1)] / [(1−ρ)(1−ρ^(N+1))]'),
          _Formula('Lᵩ', 'Lᵩ = Lₛ − (1 − P₀)'),
          _Formula('Wₛ', 'Wₛ = Lₛ / λ_eff'),
          _Formula('Wᵩ', 'Wᵩ = Lᵩ / λ_eff'),
        ],
        restrictions:
            'λ > 0,  μ > 0,  N ∈ ℤ≥1.  No se requiere ρ < 1: la '
            'capacidad finita garantiza un sistema estable incluso si '
            'λ ≥ μ (el exceso de clientes simplemente se rechaza).',
      );
    }

    return const _QueueFormulaData(
      formulas: [
        _Formula('ρ', 'ρ = λ / μ'),
        _Formula('P₀', 'P₀ = 1 − ρ'),
        _Formula('Pₙ', 'Pₙ = (1 − ρ) · ρⁿ'),
        _Formula('Lₛ', 'Lₛ = ρ / (1 − ρ) = λ / (μ − λ)'),
        _Formula('Lᵩ', 'Lᵩ = ρ² / (1 − ρ)'),
        _Formula('Wₛ', 'Wₛ = 1 / (μ − λ)'),
        _Formula('Wᵩ', 'Wᵩ = ρ / (μ − λ)'),
      ],
      restrictions:
          'λ > 0,  μ > 0,  y obligatoriamente ρ = λ/μ < 1 (condición '
          'de estabilidad). Si λ ≥ μ, la cola crece indefinidamente y '
          'el sistema no alcanza estado estacionario.',
    );
  }
}

class _FormulaBadgeTile extends StatelessWidget {
  final String badge;
  final String formula;

  const _FormulaBadgeTile({required this.badge, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badge,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textOnPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formula,
                style: AppTextStyles.formula.copyWith(fontSize: 14.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictionsBox extends StatelessWidget {
  final String text;
  const _RestrictionsBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3.5),
            top: BorderSide(color: AppColors.border),
            right: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RESTRICCIONES', style: AppTextStyles.label),
                  const SizedBox(height: 3),
                  Text(text, style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
