import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/multiserver_queue_result.dart';

/// Panel de resultados y métricas operativas del sistema de colas multicanal (M/M/c):
/// Parámetros base, métricas de clientes (L, W), métricas de servidores (c̄ ocupados/inactivos)
/// y sección de capacidad finita cuando aplica.
class MultiserverResultsPanel extends StatelessWidget {
  final MultiserverQueueResult result;

  const MultiserverResultsPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MÉTRICAS DEL SISTEMA MULTICANAL', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(result.parameterSummary, style: AppTextStyles.subtitle),
            const SizedBox(height: 14),

            // Métricas principales
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'ρ · Utilización',
                    value: '${result.rho.toStringAsFixed(4)} (${(result.rho * 100).toStringAsFixed(2)}%)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'P₀ · Sistema vacío',
                    value: '${result.p0.toStringAsFixed(4)} (${(result.p0 * 100).toStringAsFixed(2)}%)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Lₛ · Clientes en sistema',
                    value: result.ls.toStringAsFixed(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Lᵩ · Clientes en cola',
                    value: result.lq.toStringAsFixed(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Wₛ · Tiempo en sistema',
                    value: result.ws.toStringAsFixed(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Wᵩ · Tiempo en cola',
                    value: result.wq.toStringAsFixed(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Sección de servidores
            Row(
              children: const [
                Icon(Icons.people_outline_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text('ESTADO DE LOS SERVIDORES (c = can.)', style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Servidores activos (ocupados)',
                    value: result.activeServers.toStringAsFixed(4),
                    accent: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'c̄ · Servidores inactivos (ociosos)',
                    value: result.idleServers.toStringAsFixed(4),
                    accent: true,
                  ),
                ),
              ],
            ),

            // Sección exclusiva de capacidad finita N
            if (result.isFinite) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Icon(Icons.block_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('CAPACIDAD FINITA (N)', style: AppTextStyles.label),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'λ_eff · Llegada efectiva',
                      value: result.lambdaEff!.toStringAsFixed(4),
                      accent: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'Tasa de pérdida',
                      value: result.lossRate!.toStringAsFixed(4),
                      accent: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetricTile(
                label: 'P_N · Probabilidad de bloqueo (sistema lleno)',
                value:
                    '${result.blockingProbability!.toStringAsFixed(4)}  (${(result.blockingProbability! * 100).toStringAsFixed(2)}%)',
                accent: true,
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final bool fullWidth;

  const _MetricTile({
    required this.label,
    required this.value,
    this.accent = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accent ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: accent ? AppColors.primaryLight : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.subtitle.copyWith(fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              color: accent ? AppColors.primaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
