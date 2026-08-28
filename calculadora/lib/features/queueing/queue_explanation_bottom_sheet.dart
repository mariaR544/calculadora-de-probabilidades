import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/queue_result.dart';

/// Modal bottom sheet educativo que traduce y explica los resultados
/// del módulo de líneas de espera (M/M/1 y M/M/1/N) en lenguaje claro y estructurado.
class QueueExplanationBottomSheet extends StatelessWidget {
  final QueueResult result;

  const QueueExplanationBottomSheet({
    super.key,
    required this.result,
  });

  /// Despliega el modal de interpretación con el estilo estándar de la aplicación.
  static Future<void> show(
    BuildContext context, {
    required QueueResult result,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueExplanationBottomSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            _Header(onClose: () => Navigator.of(context).pop()),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExplanationSection(
                      icon: Icons.analytics_outlined,
                      title: 'DIAGNÓSTICO GENERAL DEL SISTEMA',
                      child: _BodyCard(
                        text: QueueExplanationTextGenerator.systemOverview(result),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExplanationSection(
                      icon: Icons.insights_rounded,
                      title: 'SIGNIFICADO DE LAS MÉTRICAS OPERATIVAS',
                      child: Column(
                        children: QueueExplanationTextGenerator.metricsExplanations(result)
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StatExplanationCard(
                                  label: e.label,
                                  text: e.text,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExplanationSection(
                      icon: Icons.bar_chart_rounded,
                      title: 'DISTRIBUCIÓN DE PROBABILIDAD (Pn)',
                      child: _BodyCard(
                        text: QueueExplanationTextGenerator.distributionExplanation(result),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Generador de explicaciones en lenguaje natural
// ---------------------------------------------------------------------

class QueueExplanationTextGenerator {
  const QueueExplanationTextGenerator._();

  /// Genera un diagnóstico general del sistema de colas evaluado.
  static String systemOverview(QueueResult result) {
    final lambda = result.lambda.toStringAsFixed(2);
    final mu = result.mu.toStringAsFixed(2);
    final rhoPct = (result.rho * 100).toStringAsFixed(2);
    final p0Pct = (result.p0 * 100).toStringAsFixed(2);

    if (result.isFinite) {
      final capacity = result.capacity ?? 0;
      final blockingPct = ((result.blockingProbability ?? 0) * 100).toStringAsFixed(2);
      final lossRate = (result.lossRate ?? 0).toStringAsFixed(3);
      final lambdaEff = (result.lambdaEff ?? 0).toStringAsFixed(3);

      return 'El sistema opera bajo el modelo M/M/1/$capacity (Capacidad finita de $capacity clientes). '
          'Llegan en promedio $lambda clientes por unidad de tiempo y el servidor tiene capacidad para atender $mu clientes/tiempo. '
          'La intensidad de tráfico es del $rhoPct%. Debido a la restricción de cupo, existe un $blockingPct% de probabilidad de que el '
          'sistema esté lleno al llegar un cliente, lo que genera una pérdida de $lossRate clientes/tiempo. Por lo tanto, la tasa efectiva de '
          'atención real es de $lambdaEff clientes por unidad de tiempo.';
    } else {
      String statusComment;
      if (result.rho < 0.50) {
        statusComment = 'El sistema se encuentra con baja carga de trabajo y amplia disponibilidad.';
      } else if (result.rho < 0.80) {
        statusComment = 'El sistema opera con un nivel de utilización equilibrado y estable.';
      } else {
        statusComment = 'El sistema opera con alta utilización, lo que genera un incremento significativo en los tiempos de espera.';
      }

      return 'El sistema opera bajo el modelo M/M/1 (Capacidad infinita). '
          'Con una tasa de llegada λ = $lambda y una tasa de atención μ = $mu, el servidor pasa ocupado el $rhoPct% del tiempo '
          'y desocupado el $p0Pct% del tiempo. $statusComment';
    }
  }

  /// Retorna la lista de explicaciones desglosadas para cada métrica calculada.
  static List<QueueMetricExplanation> metricsExplanations(QueueResult result) {
    final rhoPct = (result.rho * 100).toStringAsFixed(2);
    final p0Pct = (result.p0 * 100).toStringAsFixed(2);
    final ls = result.ls.toStringAsFixed(3);
    final lq = result.lq.toStringAsFixed(3);
    final ws = result.ws.toStringAsFixed(3);
    final wq = result.wq.toStringAsFixed(3);

    final list = <QueueMetricExplanation>[
      QueueMetricExplanation(
        label: 'Factor de utilización (ρ = ${result.rho.toStringAsFixed(4)})',
        text: result.isFinite
            ? 'La intensidad de tráfico nominal (λ/μ) es del $rhoPct%. La fracción real del tiempo en la que el servidor está ocupado atendiendo es de ${( (1 - result.p0) * 100 ).toStringAsFixed(2)}%.'
            : 'El servidor permanece ocupado atendiendo clientes el $rhoPct% del tiempo total, manteniéndose desocupado el $p0Pct% restante.',
      ),
      QueueMetricExplanation(
        label: 'Probabilidad de sistema vacío (P₀ = ${result.p0.toStringAsFixed(4)})',
        text: 'Existe un $p0Pct% de probabilidad de que las instalaciones estén totalmente vacías en un instante aleatorio. '
            'Cualquier cliente nuevo que arribe encontrará el servidor libre sin necesidad de hacer fila.',
      ),
      QueueMetricExplanation(
        label: 'Clientes en el sistema (Ls = $ls) y en cola (Lq = $lq)',
        text: 'En promedio se encuentran $ls clientes dentro del sistema en cualquier momento (incluyendo al atendido), '
            'de los cuales $lq clientes están formados en la fila esperando su turno.',
      ),
      QueueMetricExplanation(
        label: 'Tiempo en el sistema (Ws = $ws) y en cola (Wq = $wq)',
        text: 'Un cliente permanece en total un promedio de $ws unidades de tiempo desde que llega hasta que termina de ser atendido. '
            'De ese tiempo total, $wq unidades corresponden al tiempo de espera en la fila antes de ser atendido.',
      ),
    ];

    if (result.isFinite) {
      final lambdaEff = (result.lambdaEff ?? 0).toStringAsFixed(4);
      final lossRate = (result.lossRate ?? 0).toStringAsFixed(4);
      final blockingProb = result.blockingProbability ?? 0;
      final blockingPct = (blockingProb * 100).toStringAsFixed(2);

      list.addAll([
        QueueMetricExplanation(
          label: 'Tasa efectiva de llegada (λ_eff = $lambdaEff)',
          text: 'Es la tasa real de clientes que logran ingresar al sistema. De los ${result.lambda.toStringAsFixed(2)} clientes '
              'que intentan ingresar por unidad de tiempo, entran efectivamente $lambdaEff clientes/tiempo.',
        ),
        QueueMetricExplanation(
          label: 'Tasa de pérdida de clientes (Tasa de pérdida = $lossRate)',
          text: 'Se pierden o rechazan en promedio $lossRate clientes por unidad de tiempo debido a que intentan llegar '
              'cuando el sistema ya ha alcanzado su capacidad máxima (N = ${result.capacity}).',
        ),
        QueueMetricExplanation(
          label: 'Probabilidad de bloqueo (PN = ${blockingProb.toStringAsFixed(4)} · $blockingPct%)',
          text: 'El $blockingPct% del tiempo el sistema está completamente lleno ($result.capacity clientes). '
              'Representa la probabilidad de que un cliente que arribe sea rechazado y no pueda recibir el servicio.',
        ),
      ]);
    }

    return list;
  }

  /// Explicación sobre la distribución discreta Pn del sistema.
  static String distributionExplanation(QueueResult result) {
    final p0Pct = (result.p0 * 100).toStringAsFixed(2);

    return 'La tabla y el gráfico muestran la probabilidad P(n) de encontrar exactamente n clientes en el sistema en estado estacionario. '
        'Por ejemplo, P(0) = $p0Pct% indica la probabilidad de sistema desocupado. '
        'A medida que n aumenta, la probabilidad decrece progresivamente de acuerdo con el factor de utilización.';
  }
}

class QueueMetricExplanation {
  final String label;
  final String text;
  const QueueMetricExplanation({required this.label, required this.text});
}

// ---------------------------------------------------------------------
// Componentes visuales
// ---------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Explicación del resultado',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ExplanationSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _BodyCard extends StatelessWidget {
  final String text;
  const _BodyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.body.copyWith(height: 1.45)),
    );
  }
}

class _StatExplanationCard extends StatelessWidget {
  final String label;
  final String text;

  const _StatExplanationCard({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(text, style: AppTextStyles.body.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
