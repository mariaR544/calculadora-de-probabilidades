import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_title.dart';
import '../../models/multiserver_queue_result.dart';

/// Tabla con la distribución de probabilidad de estado del sistema multicanal:
/// n, P_n (probabilidad absoluta) y P(N ≤ n) (probabilidad acumulada),
/// con indicación visual del umbral de servidores (c).
class MultiserverDistributionTable extends StatelessWidget {
  final MultiserverQueueResult result;

  const MultiserverDistributionTable({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              text: 'Tabla de probabilidades de estado',
              icon: Icons.table_rows_rounded,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _TableRow(
                    n: 'n',
                    pn: 'Pₙ',
                    cumulative: 'P(N ≤ n)',
                    isHeader: true,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < result.distribution.length; i++)
                            _TableRow(
                              n: result.distribution[i].n == result.servers
                                  ? '${result.distribution[i].n} (c)'
                                  : result.distribution[i].n.toString(),
                              pn: result.distribution[i].probability
                                  .toStringAsFixed(4),
                              cumulative: result.distribution[i].cumulative
                                  .toStringAsFixed(4),
                              striped: i.isOdd,
                              highlight: result.distribution[i].n == result.servers,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String n;
  final String pn;
  final String cumulative;
  final bool isHeader;
  final bool striped;
  final bool highlight;

  const _TableRow({
    required this.n,
    required this.pn,
    required this.cumulative,
    this.isHeader = false,
    this.striped = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? AppTextStyles.label
        : AppTextStyles.body.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
          );

    return Container(
      color: isHeader
          ? AppColors.surfaceAlt
          : (highlight
              ? AppColors.highlight.withValues(alpha: 0.25)
              : (striped ? AppColors.surfaceAlt.withValues(alpha: 0.4) : null)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(n, style: style)),
          Expanded(flex: 4, child: Text(pn, style: style)),
          Expanded(flex: 4, child: Text(cumulative, style: style)),
        ],
      ),
    );
  }
}
