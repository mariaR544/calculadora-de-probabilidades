import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_title.dart';
import '../../models/database_simulation.dart';

/// Compara, para cada variable simulada, la media y desviación
/// estándar muestral contra el valor teórico esperado según la
/// distribución y λ usados — útil para validar visualmente que la
/// simulación se acerca a la teoría a medida que crecen las
/// observaciones.
class DatabaseSummaryPanel extends StatelessWidget {
  final SimulationResult result;

  const DatabaseSummaryPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              text: 'Muestral vs. teórico',
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 4),
            Text(
              'E[X] teórico = ${result.theoreticalMean.toStringAsFixed(4)}   '
              '·   Var(X) teórico = ${result.theoreticalVariance.toStringAsFixed(4)}',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            for (final v in result.variables) ...[
              _VariableSummaryRow(variable: v),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _VariableSummaryRow extends StatelessWidget {
  final SimulationVariable variable;
  const _VariableSummaryRow({required this.variable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              variable.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: _MiniStat(
              label: 'Media muestral',
              value: variable.sampleMean.toStringAsFixed(4),
            ),
          ),
          Expanded(
            flex: 3,
            child: _MiniStat(
              label: 'σ muestral',
              value: variable.sampleStdDev.toStringAsFixed(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
