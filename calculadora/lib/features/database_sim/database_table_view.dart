import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_title.dart';
import '../../models/database_simulation.dart';
import '../../models/distribution_type.dart';

/// Muestra la "base de datos" generada en formato tabular: una fila
/// por observación (N°) y una columna por variable simulada. La
/// tabla es desplazable tanto vertical (filas) como horizontalmente
/// (si hay muchas variables).
class DatabaseTableView extends StatelessWidget {
  final SimulationResult result;

  const DatabaseTableView({super.key, required this.result});

  String _formatValue(double value) {
    return result.distributionType.isDiscrete
        ? value.toInt().toString()
        : value.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              text: 'Base de datos generada (${result.numObservations} obs.)',
              icon: Icons.storage_rounded,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.surfaceAlt),
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 38,
                      headingTextStyle: AppTextStyles.label,
                      dataTextStyle: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                      columns: [
                        const DataColumn(label: Text('N°')),
                        for (final v in result.variables)
                          DataColumn(label: Text(v.name)),
                      ],
                      rows: [
                        for (int i = 0; i < result.numObservations; i++)
                          DataRow(
                            color: i.isOdd
                                ? WidgetStateProperty.all(
                                    AppColors.surfaceAlt.withValues(alpha: 0.5))
                                : null,
                            cells: [
                              DataCell(Text('${i + 1}')),
                              for (final v in result.variables)
                                DataCell(Text(_formatValue(v.observations[i]))),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
