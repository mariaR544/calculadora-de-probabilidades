import '../../models/queue_result.dart';
import '../../models/stat_procedure.dart';

class QueueStatProcedures {
  QueueStatProcedures._();

  static List<StatProcedure> build(QueueResult result) {
    final lambdaStr = result.lambda.toStringAsFixed(4);
    final muStr = result.mu.toStringAsFixed(4);
    final rhoStr = result.rho.toStringAsFixed(4);
    final p0Str = result.p0.toStringAsFixed(4);
    final lsStr = result.ls.toStringAsFixed(4);
    final lqStr = result.lq.toStringAsFixed(4);
    final wsStr = result.ws.toStringAsFixed(4);
    final wqStr = result.wq.toStringAsFixed(4);

    final effLambda = result.lambdaEff ?? result.lambda;
    final effLambdaStr = effLambda.toStringAsFixed(4);

    // Fórmula P_0 según modelo
    final String p0Formula;
    final String p0Sub;
    if (result.isFinite) {
      final n = result.capacity ?? 1;
      if ((result.rho - 1.0).abs() < 1e-9) {
        p0Formula = 'P_{0} = 1/(N+1)';
        p0Sub = 'P_{0} = 1/($n+1) = $p0Str';
      } else {
        p0Formula = 'P_{0} = (1−ρ)/(1−ρ^{N+1})';
        p0Sub = 'P_{0} = (1−$rhoStr)/(1−($rhoStr)^{${n + 1}}) = $p0Str';
      }
    } else {
      p0Formula = 'P_{0} = 1−ρ';
      p0Sub = 'P_{0} = 1−$rhoStr = $p0Str';
    }

    final procedures = <StatProcedure>[
      StatProcedure(
        statLabel: 'ρ · Utilización',
        formula: 'ρ = λ/μ',
        substitution: 'ρ = $lambdaStr/$muStr = $rhoStr',
        resultText: rhoStr,
        description:
            'Fracción de tiempo que el servidor está ocupado. '
            'Para estabilidad M/M/1 se requiere ρ < 1.',
      ),
      StatProcedure(
        statLabel: 'P_0 · Sistema vacío',
        formula: p0Formula,
        substitution: p0Sub,
        resultText: p0Str,
        description:
            'Probabilidad de que no haya ningún cliente en el sistema '
            'en un instante arbitrario.',
      ),
      StatProcedure(
        statLabel: 'L_s · Clientes en sistema',
        formula: 'L_{s} = L_{q} + λ_{eff}/μ',
        substitution: 'L_{s} = $lqStr + $effLambdaStr/$muStr = $lsStr',
        resultText: lsStr,
        description:
            'Número promedio de clientes en el sistema (en cola + en servicio). '
            'Ley de Little: L_{s} = λ_{eff} · W_{s}.',
      ),
      StatProcedure(
        statLabel: 'L_q · Clientes en cola',
        formula: 'L_{q} = W_{q} · λ_{eff}',
        substitution: 'L_{q} = $wqStr · $effLambdaStr = $lqStr',
        resultText: lqStr,
        description:
            'Número promedio de clientes esperando servicio '
            '(sin contar al que se está atendiendo).',
      ),
      StatProcedure(
        statLabel: 'W_s · Tiempo en sistema',
        formula: 'W_{s} = W_{q} + 1/μ',
        substitution: 'W_{s} = $wqStr + 1/$muStr = $wsStr',
        resultText: wsStr,
        description:
            'Tiempo total promedio desde que llega hasta que abandona el sistema. '
            'Incluye espera en cola más tiempo de servicio.',
      ),
      StatProcedure(
        statLabel: 'W_q · Tiempo en cola',
        formula: 'W_{q} = L_{q}/λ_{eff}',
        substitution: 'W_{q} = $lqStr/$effLambdaStr = $wqStr',
        resultText: wqStr,
        description:
            'Tiempo promedio esperando en fila antes de ser atendido. '
            'Relacionado con L_{q} por la Ley de Little.',
      ),
    ];

    if (result.isFinite &&
        result.lambdaEff != null &&
        result.blockingProbability != null) {
      final lambdaEffStr = result.lambdaEff!.toStringAsFixed(4);
      final pnStr = result.blockingProbability!.toStringAsFixed(4);
      final nStr = result.capacity.toString();

      procedures.addAll([
        StatProcedure(
          statLabel: 'λ_{eff} · Llegada efectiva',
          formula: 'λ_{eff} = λ·(1−P_{N})',
          substitution: 'λ_{eff} = $lambdaStr·(1−$pnStr) = $lambdaEffStr',
          resultText: lambdaEffStr,
          description:
              'Tasa real de clientes que ingresan al sistema, '
              'descontando los rechazados por encontrarlo lleno.',
        ),
        StatProcedure(
          statLabel: 'Tasa de pérdida',
          formula: 'Tasa pérdida = λ−λ_{eff}',
          substitution:
              'Tasa pérdida = $lambdaStr−$lambdaEffStr = '
              '${result.lossRate!.toStringAsFixed(4)}',
          resultText: result.lossRate!.toStringAsFixed(4),
          description:
              'Clientes por unidad de tiempo que llegan pero son rechazados '
              'porque el sistema alcanzó su capacidad máxima N.',
        ),
        StatProcedure(
          statLabel: 'P(N) · Probabilidad de bloqueo (sistema lleno)',
          formula: 'P_{N} = P_{0}·ρ^{N}',
          substitution: 'P_{N} = $p0Str·($rhoStr)^{$nStr} = $pnStr',
          resultText:
              '$pnStr (${(result.blockingProbability! * 100).toStringAsFixed(2)} %)',
          description:
              'Probabilidad de que el sistema esté completamente lleno '
              'y el próximo cliente sea rechazado.',
        ),
      ]);
    }

    return procedures;
  }
}
