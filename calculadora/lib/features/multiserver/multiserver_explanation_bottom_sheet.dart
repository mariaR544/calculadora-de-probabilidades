import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/multiserver_queue_result.dart';

/// Modal bottom sheet educativo que traduce y explica los resultados
/// del módulo de líneas de espera de múltiples servidores (M/M/c y M/M/c/N).
class MultiserverExplanationBottomSheet extends StatelessWidget {
  final MultiserverQueueResult result;

  const MultiserverExplanationBottomSheet({
    super.key,
    required this.result,
  });

  /// Despliega el modal de interpretación con el estilo estándar de la aplicación.
  static Future<void> show(
    BuildContext context, {
    required MultiserverQueueResult result,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiserverExplanationBottomSheet(result: result),
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
                      title: 'DIAGNÓSTICO GENERAL DEL SISTEMA MULTICANAL',
                      child: _BodyCard(
                        text: MultiserverExplanationTextGenerator.systemOverview(result),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExplanationSection(
                      icon: Icons.people_outline_rounded,
                      title: 'ANÁLISIS DE RENDIMIENTO DE LOS SERVIDORES',
                      child: _BodyCard(
                        text: MultiserverExplanationTextGenerator.serverAnalysis(result),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ExplanationSection(
                      icon: Icons.insights_rounded,
                      title: 'SIGNIFICADO DE LAS MÉTRICAS OPERATIVAS',
                      child: Column(
                        children: MultiserverExplanationTextGenerator.metricsExplanations(result)
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
                      title: 'COMPORTAMIENTO DE LA DISTRIBUCIÓN (Pn)',
                      child: _BodyCard(
                        text: MultiserverExplanationTextGenerator.distributionExplanation(result),
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
// Generador de texto pedagógico
// ---------------------------------------------------------------------

class MultiserverExplanationTextGenerator {
  const MultiserverExplanationTextGenerator._();

  /// Diagnóstico global del sistema multicanal.
  static String systemOverview(MultiserverQueueResult result) {
    final lambda = result.lambda.toStringAsFixed(2);
    final mu = result.mu.toStringAsFixed(2);
    final c = result.servers;
    final totalCapacityRate = (c * result.mu).toStringAsFixed(2);
    final rhoPct = (result.rho * 100).toStringAsFixed(2);
    final p0Pct = (result.p0 * 100).toStringAsFixed(2);

    if (result.isFinite) {
      final capacity = result.capacity ?? 0;
      final maxQueue = capacity - c;
      final blockingPct = ((result.blockingProbability ?? 0) * 100).toStringAsFixed(2);
      final lossRate = (result.lossRate ?? 0).toStringAsFixed(3);
      final lambdaEff = (result.lambdaEff ?? 0).toStringAsFixed(3);

      return 'El sistema opera bajo el modelo multicanal M/M/$c/$capacity con capacidad finita de $capacity clientes ($c en servidores y máximo $maxQueue en cola). '
          'Llegan en promedio $lambda clientes por unidad de tiempo y los $c servidores juntos pueden procesar hasta $totalCapacityRate clientes/tiempo ($mu c/u). '
          'La intensidad de tráfico es del $rhoPct%. Debido al límite de capacidad, existe un $blockingPct% de probabilidad de bloqueo '
          'al estar el sistema lleno, provocando el rechazo de $lossRate clientes/tiempo. La tasa efectiva real que ingresa al sistema es de $lambdaEff clientes por unidad de tiempo.';
    } else {
      String statusComment;
      if (result.rho < 0.50) {
        statusComment = 'Los servidores operan con baja carga de trabajo y holgura en su capacidad de atención conjunta.';
      } else if (result.rho < 0.80) {
        statusComment = 'El sistema mantiene un equilibrio óptimo entre utilización del personal y tiempos de espera de los usuarios.';
      } else {
        statusComment = 'El sistema experimenta alta utilización global ($rhoPct%), lo que produce colas más frecuentes en horas pico.';
      }

      return 'El sistema opera bajo el modelo multicanal M/M/$c con capacidad infinita (sin límite en cola). '
          'Cuenta con $c servidores paralelos con capacidad global de atención de $totalCapacityRate clientes/tiempo. '
          'Dado que la tasa de llegada (λ = $lambda) es inferior a la capacidad total conjunta, el sistema es estable. '
          'El factor de utilización promedio por servidor es del $rhoPct%, y la probabilidad de encontrar todos los servidores desocupados es del $p0Pct%. $statusComment';
    }
  }

  /// Análisis especializado sobre los servidores activos e inactivos.
  static String serverAnalysis(MultiserverQueueResult result) {
    final c = result.servers;
    final active = result.activeServers.toStringAsFixed(3);
    final idle = result.idleServers.toStringAsFixed(3);
    final activePct = ((result.activeServers / c) * 100).toStringAsFixed(2);
    final idlePct = ((result.idleServers / c) * 100).toStringAsFixed(2);

    return 'De los $c servidores disponibles en el sistema, en promedio se encuentran $active servidores ocupados atendiendo ($activePct% del personal) '
        'y $idle servidores inactivos/desocupados ($idlePct% de capacidad ociosa, c̄). '
        'Esto significa que un cliente nuevo que llega tiene altas probabilidades de ser atendido de inmediato si hay menos de $c personas en el sistema.';
  }

  /// Desglose de cada una de las métricas operativas.
  static List<MultiserverMetricExplanation> metricsExplanations(MultiserverQueueResult result) {
    final rhoPct = (result.rho * 100).toStringAsFixed(2);
    final p0Pct = (result.p0 * 100).toStringAsFixed(2);
    final ls = result.ls.toStringAsFixed(3);
    final lq = result.lq.toStringAsFixed(3);
    final ws = result.ws.toStringAsFixed(3);
    final wq = result.wq.toStringAsFixed(3);
    final c = result.servers;

    final list = <MultiserverMetricExplanation>[
      MultiserverMetricExplanation(
        label: 'Factor de utilización global (ρ = ${result.rho.toStringAsFixed(4)})',
        text: 'Representa la fracción de tiempo promedio que cada uno de los $c servidores pasa ocupado. '
            'Equivale a un $rhoPct% de ocupación por canal.',
      ),
      MultiserverMetricExplanation(
        label: 'Probabilidad de sistema totalmente vacío (P₀ = ${result.p0.toStringAsFixed(4)})',
        text: 'Existe un $p0Pct% de probabilidad de que no haya ningún cliente en el sistema. '
            'En ese estado, los $c servidores se encuentran simultáneamente desocupados y listos para atender.',
      ),
      MultiserverMetricExplanation(
        label: 'Clientes en el sistema (Ls = $ls) y en cola (Lq = $lq)',
        text: 'En promedio coexisten $ls clientes en las instalaciones (entre los que están en los puestos de atención y en fila). '
            'Exclusivamente en la fila de espera aguardan en promedio $lq clientes.',
      ),
      MultiserverMetricExplanation(
        label: 'Tiempo en el sistema (Ws = $ws) y en cola (Wq = $wq)',
        text: 'Un cliente invierte en promedio $ws unidades de tiempo en total desde que entra hasta que se retira atendido. '
            'De ese lapso, permanece formado en la cola un promedio de $wq unidades de tiempo.',
      ),
      MultiserverMetricExplanation(
        label: 'Servidores ocupados (${result.activeServers.toStringAsFixed(4)}) e inactivos c̄ (${result.idleServers.toStringAsFixed(4)})',
        text: 'En régimen permanente, se mantienen ocupados en promedio ${result.activeServers.toStringAsFixed(3)} servidores, '
            'quedando ${result.idleServers.toStringAsFixed(3)} servidores inactivos listos para recibir nuevos usuarios.',
      ),
    ];

    if (result.isFinite) {
      final lambdaEff = (result.lambdaEff ?? 0).toStringAsFixed(4);
      final lossRate = (result.lossRate ?? 0).toStringAsFixed(4);
      final blockingProb = result.blockingProbability ?? 0;
      final blockingPct = (blockingProb * 100).toStringAsFixed(2);

      list.addAll([
        MultiserverMetricExplanation(
          label: 'Tasa efectiva de llegada (λ_eff = $lambdaEff)',
          text: 'Tasa real de clientes que son admitidos por unidad de tiempo. De los ${result.lambda.toStringAsFixed(2)} que intentan arribar, '
              'ingresan $lambdaEff clientes/tiempo debido al límite de capacidad.',
        ),
        MultiserverMetricExplanation(
          label: 'Tasa de pérdida de clientes (Tasa de pérdida = $lossRate)',
          text: 'Se pierden o rechazan en promedio $lossRate clientes por unidad de tiempo por encontrar el cupo máximo ($result.capacity) colmado.',
        ),
        MultiserverMetricExplanation(
          label: 'Probabilidad de bloqueo (PN = ${blockingProb.toStringAsFixed(4)} · $blockingPct%)',
          text: 'Existe un $blockingPct% de probabilidad de que el sistema esté al 100% de su capacidad ($result.capacity clientes), '
              'rechazando de inmediato cualquier nueva llegada.',
        ),
      ]);
    }

    return list;
  }

  /// Explicación sobre la distribución discreta Pn en sistemas multicanal.
  static String distributionExplanation(MultiserverQueueResult result) {
    final c = result.servers;
    return 'En un sistema multicanal, la distribución de probabilidades opera en dos fases:\n'
        '1. Cuando n ≤ $c (hasta $c clientes): la tasa de servicio crece proporcionalmente al número de clientes activos (n · μ), ya que cada cliente es atendido por un servidor independiente.\n'
        '2. Cuando n > $c: todos los $c servidores están ocupados a máxima capacidad conjunta (c · μ) y los clientes adicionales forman la fila de espera, haciendo que la probabilidad P(n) disminuya en factor geométrico ρ.';
  }
}

class MultiserverMetricExplanation {
  final String label;
  final String text;
  const MultiserverMetricExplanation({required this.label, required this.text});
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
              'Explicación del resultado multicanal',
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
