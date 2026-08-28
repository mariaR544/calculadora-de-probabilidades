import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_title.dart';
import '../../models/multiserver_queue_model_type.dart';

/// Tarjeta con la formulación matemática y teoría del modelo multicanal (M/M/c).
class MultiserverFormulaCard extends StatelessWidget {
  final MultiserverQueueModelType type;

  const MultiserverFormulaCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final data = _MultiserverFormulaData.forType(type);

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
            const Text('FÓRMULAS PRINCIPALES DEL MODELO', style: AppTextStyles.label),
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

class _MultiserverFormulaData {
  final List<_Formula> formulas;
  final String restrictions;

  const _MultiserverFormulaData({required this.formulas, required this.restrictions});

  static _MultiserverFormulaData forType(MultiserverQueueModelType type) {
    if (type.isFinite) {
      return const _MultiserverFormulaData(
        formulas: [
          _Formula('r, ρ', 'r = λ / μ    ·    ρ = λ / (c · μ)'),
          _Formula('P₀', 'P₀ = [ ∑ₙ₌₀ᶜ⁻¹ (rⁿ / n!) + (rᶜ / c!) · ((1 − ρᴺ⁻ᶜ⁺¹) / (1 − ρ)) ]⁻¹    [ρ ≠ 1]'),
          _Formula('Pₙ (n≤c)', 'Pₙ = (rⁿ / n!) · P₀    (0 ≤ n ≤ c)'),
          _Formula('Pₙ (n>c)', 'Pₙ = (rⁿ / (c! · cⁿ⁻ᶜ)) · P₀ = (rᶜ / c!) · ρⁿ⁻ᶜ · P₀    (c < n ≤ N)'),
          _Formula('P_N', 'P_N = (rᴺ / (c! · cᴺ⁻ᶜ)) · P₀    (Bloqueo / Sistema lleno)'),
          _Formula('λ_eff', 'λ_eff = λ · (1 − P_N)'),
          _Formula('Pérdida', 'Tasa de pérdida = λ − λ_eff = λ · P_N'),
          _Formula('Lᵩ', 'Lᵩ = ∑ₙ₌ᶜᴺ (n − c) · Pₙ'),
          _Formula('Wᵩ', 'Wᵩ = Lᵩ / λ_eff'),
          _Formula('Wₛ', 'Wₛ = Wᵩ + (1 / μ)'),
          _Formula('Lₛ', 'Lₛ = λ_eff · Wₛ = Lᵩ + (λ_eff / μ)'),
          _Formula('Activos', 'Servidores activos = λ_eff / μ'),
          _Formula('c̄', 'c̄ (inactivos) = c − (λ_eff / μ)'),
        ],
        restrictions:
            'λ > 0,  μ > 0,  c ∈ ℤ≥1,  N ∈ ℤ y N ≥ c. '
            'La capacidad finita N garantiza la estabilidad del sistema sin requerir ρ < 1.',
      );
    }

    return const _MultiserverFormulaData(
      formulas: [
        _Formula('r, ρ', 'r = λ / μ    ·    ρ = λ / (c · μ)'),
        _Formula('P₀', 'P₀ = [ ∑ₙ₌₀ᶜ⁻¹ (rⁿ / n!) + (rᶜ / c!) · (1 / (1 − ρ)) ]⁻¹'),
        _Formula('Pₙ (n≤c)', 'Pₙ = (rⁿ / n!) · P₀    (0 ≤ n ≤ c)'),
        _Formula('Pₙ (n>c)', 'Pₙ = (rⁿ / (c! · cⁿ⁻ᶜ)) · P₀    (n > c)'),
        _Formula('Lᵩ', 'Lᵩ = (P₀ · rᶜ · ρ) / [ c! · (1 − ρ)² ]'),
        _Formula('Wᵩ', 'Wᵩ = Lᵩ / λ'),
        _Formula('Wₛ', 'Wₛ = Wᵩ + (1 / μ)'),
        _Formula('Lₛ', 'Lₛ = λ · Wₛ = Lᵩ + (λ / μ)'),
        _Formula('Activos', 'Servidores activos = λ / μ = r'),
        _Formula('c̄', 'c̄ (inactivos) = c − (λ / μ) = c − r'),
      ],
      restrictions:
          'λ > 0,  μ > 0,  c ∈ ℤ≥1,  y obligatoriamente ρ = λ/(c·μ) < 1 (condición de estabilidad). '
          'Si λ ≥ c·μ, la tasa de llegada supera la capacidad de todos los servidores y la cola crece indefinidamente.',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              formula,
              style: AppTextStyles.formula.copyWith(fontSize: 13),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('CONDICIONES Y RESTRICCIONES', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: AppTextStyles.subtitle.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
