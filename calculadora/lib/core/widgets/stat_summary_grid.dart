import 'package:flutter/material.dart';
import '../../models/calculation_result.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Grid responsivo de estadísticos descriptivos.
///
/// Muestra siempre el Promedio (E[X]) y la Desviación Estándar (σ) —
/// las dos métricas principales — y permite desplegar/colapsar las
/// otras cuatro (Varianza, Asimetría, Curtosis y Coeficiente de
/// Variación) mediante un botón con ícono `expand_more`/`expand_less`,
/// para mantener la pantalla limpia por defecto.
class StatSummaryGrid extends StatefulWidget {
  final CalculationResult result;

  const StatSummaryGrid({super.key, required this.result});

  @override
  State<StatSummaryGrid> createState() => _StatSummaryGridState();
}

class _StatSummaryGridState extends State<StatSummaryGrid> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ESTADÍSTICOS DESCRIPTIVOS', style: AppTextStyles.label),
            const SizedBox(height: 12),

            // --- Siempre visibles: Promedio y Desviación estándar ---
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Promedio E[X]',
                    valueText: r.mean.toStringAsFixed(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Desv. estándar σ',
                    valueText: r.stdDev.toStringAsFixed(4),
                  ),
                ),
              ],
            ),

            // --- Colapsables: Varianza, Asimetría, Curtosis, CV ---
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Varianza Var[X]',
                                  valueText: r.variance.toStringAsFixed(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Asimetría',
                                  valueText: r.skewness.toStringAsFixed(4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Curtosis',
                                  valueText: r.kurtosis.toStringAsFixed(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Coef. variación (CV)',
                                  valueText:
                                      '${(r.coefficientOfVariation * 100).toStringAsFixed(4)}%',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),

            // --- Botón expandir / colapsar ---
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                ),
                label: Text(_expanded ? 'Ver menos' : 'Ver más estadísticos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valueText;

  const _StatCard({required this.label, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(valueText, style: AppTextStyles.momentValue),
        ],
      ),
    );
  }
}