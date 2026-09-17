import '../../models/multiserver_queue_result.dart';
import '../../models/stat_procedure.dart';

class MultiserverStatProcedures {
  MultiserverStatProcedures._();

  static List<StatProcedure> build(MultiserverQueueResult result) {
    final lambdaStr = result.lambda.toStringAsFixed(4);
    final muStr = result.mu.toStringAsFixed(4);
    final rStr = result.r.toStringAsFixed(4);
    final rhoStr = result.rho.toStringAsFixed(4);
    final p0Str = result.p0.toStringAsFixed(4);
    final lsStr = result.ls.toStringAsFixed(4);
    final lqStr = result.lq.toStringAsFixed(4);
    final wsStr = result.ws.toStringAsFixed(4);
    final wqStr = result.wq.toStringAsFixed(4);
    final activeStr = result.activeServers.toStringAsFixed(4);
    final idleStr = result.idleServers.toStringAsFixed(4);
    final c = result.servers;

    final effLambda = result.lambdaEff ?? result.lambda;
    final effLambdaStr = effLambda.toStringAsFixed(4);

    // Fórmula P_0 según modelo infinito o finito
    final String p0Formula;
    final String p0Sub;
    if (result.isFinite) {
      final n = result.capacity ?? c;
      // Usando texto plano sin ∑ para evitar ambigüedad en el parser
      p0Formula =
          'P_{0} = [ ∑_{n=0}^{c-1} r^{n}/n! + r^{c}/c! · (1−ρ^{N-c+1})/(1−ρ) ]^{-1}';
      p0Sub =
          'P_{0} = [ ∑_{n=0}^{${c - 1}} (${rStr})^{n}/n! + (${rStr})^{$c}/$c! · '
          '(1−(${rhoStr})^{${n - c + 1}})/(1−$rhoStr) ]^{-1} = $p0Str';
    } else {
      p0Formula =
          'P_{0} = [ ∑_{n=0}^{c-1} r^{n}/n! + r^{c}/c! · 1/(1−ρ) ]^{-1}';
      p0Sub =
          'P_{0} = [ ∑_{n=0}^{${c - 1}} (${rStr})^{n}/n! + (${rStr})^{$c}/$c! · '
          '1/(1−$rhoStr) ]^{-1} = $p0Str';
    }

    final String lqFormula;
    final String lqSub;
    if (result.isFinite) {
      final n = result.capacity ?? c;
      lqFormula = 'L_{q} = ∑_{n=c}^{N} (n−c)·P_{n}';
      lqSub = 'L_{q} = ∑_{n=$c}^{$n} (n−$c)·P_{n} = $lqStr';
    } else {
      lqFormula = 'L_{q} = P_{0}·r^{c}·ρ / [ c!·(1−ρ)^{2} ]';
      lqSub =
          'L_{q} = $p0Str·(${rStr})^{$c}·$rhoStr / [ $c!·(1−$rhoStr)^{2} ] = $lqStr';
    }

    final procedures = <StatProcedure>[
      StatProcedure(
        statLabel: 'ρ · Utilización',
        formula: 'ρ = λ/(c·μ) = r/c',
        substitution: 'ρ = $lambdaStr/($c·$muStr) = $rStr/$c = $rhoStr',
        resultText: '$rhoStr (${(result.rho * 100).toStringAsFixed(2)} %)',
        description:
            'Fracción promedio de la capacidad total utilizada. '
            'Para estabilidad M/M/c infinito se requiere ρ < 1.',
      ),
      StatProcedure(
        statLabel: 'P₀ · Sistema vacío',
        formula: p0Formula,
        substitution: p0Sub,
        resultText: '$p0Str (${(result.p0 * 100).toStringAsFixed(2)} %)',
        description:
            'Probabilidad de que todos los $c servidores estén libres '
            'y no haya ningún cliente en el sistema.',
      ),
      StatProcedure(
        statLabel: 'L_s · Clientes en sistema',
        formula: 'L_{s} = L_{q} + λ_{eff}/μ',
        substitution: 'L_{s} = $lqStr + $effLambdaStr/$muStr = $lsStr',
        resultText: lsStr,
        description:
            'Total promedio de clientes dentro del sistema multicanal '
            '(esperando en cola más los $c servidores activos).',
      ),
      StatProcedure(
        statLabel: 'L_q · Clientes en cola',
        formula: lqFormula,
        substitution: lqSub,
        resultText: lqStr,
        description:
            'Número promedio de clientes esperando a que alguno '
            'de los $c servidores quede libre.',
      ),
      StatProcedure(
        statLabel: 'W_s · Tiempo en sistema',
        formula: 'W_{s} = W_{q} + 1/μ',
        substitution: 'W_{s} = $wqStr + 1/$muStr = $wsStr',
        resultText: wsStr,
        description:
            'Tiempo total promedio desde que llega hasta que el cliente '
            'abandona el sistema (cola + tiempo de servicio).',
      ),
      StatProcedure(
        statLabel: 'W_q · Tiempo en cola',
        formula: 'W_{q} = L_{q}/λ_{eff}',
        substitution: 'W_{q} = $lqStr/$effLambdaStr = $wqStr',
        resultText: wqStr,
        description:
            'Tiempo promedio esperando en fila antes de que uno '
            'de los $c servidores esté disponible.',
      ),
      StatProcedure(
        statLabel: 'Servidores activos (ocupados)',
        formula: 'c_{activos} = λ_{eff}/μ',
        substitution: 'c_{activos} = $effLambdaStr/$muStr = $activeStr',
        resultText: activeStr,
        description:
            'Número promedio de servidores simultáneamente ocupados. '
            'Equivale a la intensidad de tráfico efectiva r = λ_{eff}/μ.',
      ),
      StatProcedure(
        statLabel: 'c̄ · Servidores inactivos (ociosos)',
        formula: 'c̄ = c − λ_{eff}/μ',
        substitution: 'c̄ = $c − $activeStr = $idleStr',
        resultText: idleStr,
        description:
            'Promedio de servidores desocupados en cualquier momento. '
            'c̄ = c − activos.',
      ),
    ];

    if (result.isFinite &&
        result.lambdaEff != null &&
        result.blockingProbability != null) {
      final lambdaEffStr = result.lambdaEff!.toStringAsFixed(4);
      final pnStr = result.blockingProbability!.toStringAsFixed(4);
      final nStr = result.capacity.toString();
      final n = result.capacity!;

      procedures.addAll([
        StatProcedure(
          statLabel: 'λ_{eff} · Llegada efectiva',
          formula: 'λ_{eff} = λ·(1−P_{N})',
          substitution: 'λ_{eff} = $lambdaStr·(1−$pnStr) = $lambdaEffStr',
          resultText: lambdaEffStr,
          description:
              'Tasa real de clientes que ingresan al sistema, '
              'descontando los bloqueados por capacidad llena.',
        ),
        StatProcedure(
          statLabel: 'Tasa de pérdida',
          formula: 'Tasa pérdida = λ−λ_{eff}',
          substitution:
              'Tasa pérdida = $lambdaStr−$lambdaEffStr = '
              '${result.lossRate!.toStringAsFixed(4)}',
          resultText: result.lossRate!.toStringAsFixed(4),
          description:
              'Clientes rechazados por unidad de tiempo porque el '
              'sistema de $c servidores alcanzó su límite N = $nStr.',
        ),
        StatProcedure(
          statLabel: 'P_N · Probabilidad de bloqueo (sistema lleno)',
          formula: 'P_{N} = (r^{N}/(c!·c^{N-c}))·P_{0}',
          substitution:
              'P_{N} = ((${rStr})^{$n}/($c!·${c}^{${n - c}}))·$p0Str = $pnStr',
          resultText:
              '$pnStr (${(result.blockingProbability! * 100).toStringAsFixed(2)} %)',
          description:
              'Probabilidad de que el sistema tenga exactamente N=$nStr clientes '
              'y el próximo cliente sea rechazado.',
        ),
      ]);
    }

    return procedures;
  }
}
