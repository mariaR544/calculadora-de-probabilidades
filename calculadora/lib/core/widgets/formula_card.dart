import 'package:flutter/material.dart';
import '../../models/distribution_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'section_title.dart';

/// Tarjeta con la teoría breve, las fórmulas principales (PMF/PDF y
/// CDF), la cuadrícula de fórmulas de los 6 estadísticos descriptivos
/// y las restricciones de validación de la distribución seleccionada.
///
/// Se muestra dentro del panel deslizable de "Fórmulas" en
/// [DistributionScreen].
class FormulaCard extends StatelessWidget {
  final DistributionType type;

  const FormulaCard({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final data = _FormulaData.forType(type);

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

            const SizedBox(height: 20),
            Text('FÓRMULAS PRINCIPALES', style: AppTextStyles.label),
            const SizedBox(height: 10),
            _FormulaBadgeTile(
              badge: data.densityBadge,
              formula: data.densityFormula,
              domain: data.densityDomain,
            ),
            const SizedBox(height: 10),
            _FormulaBadgeTile(
              badge: 'CDF',
              formula: data.cdfFormula,
              domain: data.cdfDomain,
            ),

            const SizedBox(height: 22),
            Text('ESTADÍSTICOS DESCRIPTIVOS', style: AppTextStyles.label),
            const SizedBox(height: 10),
            _StatFormulaGrid(items: data.statFormulas),

            const SizedBox(height: 18),
            _RestrictionsBox(text: data.restrictions),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Datos de fórmulas por distribución
// ---------------------------------------------------------------------

class _StatFormula {
  final String label;
  final String formula;
  const _StatFormula(this.label, this.formula);
}

class _FormulaData {
  final String densityBadge; // 'PMF' (Poisson) o 'PDF' (Exponencial)
  final String densityFormula;
  final String densityDomain;
  final String cdfFormula;
  final String cdfDomain;
  final List<_StatFormula> statFormulas;
  final String restrictions;

  const _FormulaData({
    required this.densityBadge,
    required this.densityFormula,
    required this.densityDomain,
    required this.cdfFormula,
    required this.cdfDomain,
    required this.statFormulas,
    required this.restrictions,
  });

  static _FormulaData forType(DistributionType type) {
    if (type == DistributionType.poisson) {
      return const _FormulaData(
        densityBadge: 'PMF',
        densityFormula: 'P(X = x)  =  (λˣ · e⁻λ) / x!',
        densityDomain: 'x ∈ {0, 1, 2, ...}',
        cdfFormula: 'P(X ≤ x)  =  Σ (λⁱ · e⁻λ) / i!    (i = 0 → x)',
        cdfDomain: 'x ∈ {0, 1, 2, ...}',
        statFormulas: [
          _StatFormula('E[X] · Media', 'λ'),
          _StatFormula('Var(X) · Varianza', 'λ'),
          _StatFormula('σ · Desv. estándar', '√λ'),
          _StatFormula('Asimetría', '1 / √λ'),
          _StatFormula('Curtosis', '3 + 1/λ'),
          _StatFormula('CV', '1 / √λ'),
        ],
        restrictions: 'λ > 0   y   x ∈ {0, 1, 2, 3, ...}',
      );
    }

    return const _FormulaData(
      densityBadge: 'PDF',
      densityFormula: 'f(x)  =  λ · e⁻λˣ     (x > 0)',
      densityDomain: 'x > 0',
      cdfFormula: 'F(x)  =  1 − e⁻λˣ     (x ≥ 0)',
      cdfDomain: 'x ≥ 0',
      statFormulas: [
        _StatFormula('E[X] · Media', '1 / λ'),
        _StatFormula('Var(X) · Varianza', '1 / λ²'),
        _StatFormula('σ · Desv. estándar', '1 / λ'),
        _StatFormula('Asimetría', '2'),
        _StatFormula('Curtosis', '9'),
        _StatFormula('CV', '1   (100%)'),
      ],
      restrictions: 'λ > 0   y   x ≥ 0',
    );
  }
}

// ---------------------------------------------------------------------
// Widgets de presentación
// ---------------------------------------------------------------------

/// Tarjeta de fórmula principal (PMF/PDF o CDF) con un badge de color
/// que identifica el tipo de función, la fórmula en tipografía
/// monoespaciada y el dominio de la variable a la derecha.
class _FormulaBadgeTile extends StatelessWidget {
  final String badge;
  final String formula;
  final String domain;

  const _FormulaBadgeTile({
    required this.badge,
    required this.formula,
    required this.domain,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textOnPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(domain, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formula,
              style: AppTextStyles.formula.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula de 2 columnas × 3 filas con las fórmulas de los 6
/// estadísticos descriptivos.
class _StatFormulaGrid extends StatelessWidget {
  final List<_StatFormula> items;

  const _StatFormulaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 10 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _StatFormulaCell(item: items[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < items.length
                        ? _StatFormulaCell(item: items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatFormulaCell extends StatelessWidget {
  final _StatFormula item;
  const _StatFormulaCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: AppTextStyles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            item.formula,
            style: AppTextStyles.formula,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Caja informativa sutil con las restricciones de validación de la
/// distribución (dominio de λ y de la variable aleatoria).
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