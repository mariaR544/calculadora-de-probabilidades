import 'package:flutter/material.dart';
import '../../models/calculation_result.dart';
import '../../models/stat_procedure.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'stat_procedure_dialog.dart';

/// Grid responsivo de estadísticos descriptivos.
///
/// Muestra siempre el Promedio (E[X]) y la Desviación Estándar (σ) —
/// las dos métricas principales — y permite desplegar/colapsar las
/// otras cuatro (Varianza, Asimetría, Curtosis y Coeficiente de
/// Variación) mediante un botón con ícono `expand_more`/`expand_less`,
/// para mantener la pantalla limpia por defecto.
class StatSummaryGrid extends StatefulWidget {
  final CalculationResult result;

  /// Procedimientos paso a paso opcionales.
  /// Cuando se pasan, cada tarjeta muestra un ícono ⓘ y abre
  /// [StatProcedureDialog] al ser tocada.
  /// La clave del mapa debe coincidir exactamente con el [label] de la tarjeta.
  final List<StatProcedure>? procedures;

  const StatSummaryGrid({
    super.key,
    required this.result,
    this.procedures,
  });

  @override
  State<StatSummaryGrid> createState() => _StatSummaryGridState();
}

class _StatSummaryGridState extends State<StatSummaryGrid> {
  bool _expanded = false;

  /// Mapa de label → procedimiento para lookup O(1).
  Map<String, StatProcedure> get _procMap {
    final procs = widget.procedures;
    if (procs == null) return const {};
    return {for (final p in procs) p.statLabel: p};
  }

  void _onCardTap(BuildContext context, String label) {
    final proc = _procMap[label];
    if (proc == null) return;
    StatProcedureDialog.show(context, procedure: proc);
  }

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
                    onTap: _procMap.containsKey('Promedio E[X]')
                        ? () => _onCardTap(context, 'Promedio E[X]')
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Desv. estándar σ',
                    valueText: r.stdDev.toStringAsFixed(4),
                    onTap: _procMap.containsKey('Desv. estándar σ')
                        ? () => _onCardTap(context, 'Desv. estándar σ')
                        : null,
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
                                  onTap: _procMap.containsKey('Varianza Var[X]')
                                      ? () => _onCardTap(context, 'Varianza Var[X]')
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Asimetría',
                                  valueText: r.skewness.toStringAsFixed(4),
                                  onTap: _procMap.containsKey('Asimetría')
                                      ? () => _onCardTap(context, 'Asimetría')
                                      : null,
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
                                  onTap: _procMap.containsKey('Curtosis')
                                      ? () => _onCardTap(context, 'Curtosis')
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  label: 'Coef. variación (CV)',
                                  valueText:
                                      '${(r.coefficientOfVariation * 100).toStringAsFixed(4)}%',
                                  onTap: _procMap.containsKey('Coef. variación (CV)')
                                      ? () => _onCardTap(context, 'Coef. variación (CV)')
                                      : null,
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

  /// Cuando no es null la tarjeta se vuelve tappable y muestra el ícono ⓘ.
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.valueText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;

    // Ink permite que InkWell dibuje el ripple sobre la decoración.
    return Ink(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: interactive
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: interactive ? 0.07 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primaryLight.withValues(alpha: 0.20),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: AppTextStyles.label)),
                  if (interactive)
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(valueText, style: AppTextStyles.momentValue),
            ],
          ),
        ),
      ),
    );
  }
}