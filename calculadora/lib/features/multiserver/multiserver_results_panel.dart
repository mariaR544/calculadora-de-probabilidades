import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/multiserver_queue_result.dart';

/// Formatea un número decimal eliminando ceros innecesarios al final
String _formatNum(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  if (s.contains('.')) {
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// Formatea un resultado a decimales fijos
String _formatFixed(double v, [int decimals = 4]) =>
    v.toStringAsFixed(decimals);

/// Analiza una cadena buscando notación `_` para subíndices y `^` para superíndices,
/// normalizando caracteres Unicode y renderizando mediante [WidgetSpan] con alineación
/// precisa de línea base para soporte universal.
List<InlineSpan> _parseFormulaSpans(String text, TextStyle baseStyle) {
  final normalized = text
      .replaceAll('ₛ', '_s')
      .replaceAll('ᵩ', '_q')
      .replaceAll('₀', '_0')
      .replaceAll('₁', '_1')
      .replaceAll('₂', '_2')
      .replaceAll('₃', '_3')
      .replaceAll('₄', '_4')
      .replaceAll('₅', '_5')
      .replaceAll('₆', '_6')
      .replaceAll('₇', '_7')
      .replaceAll('₈', '_8')
      .replaceAll('₉', '_9')
      .replaceAll('ₙ', '_n')
      .replaceAll('ₘ', '_m')
      .replaceAll('ᵢ', '_i')
      .replaceAll('ⱼ', '_j')
      .replaceAll('ₖ', '_k')
      .replaceAll('⁰', '^0')
      .replaceAll('¹', '^1')
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll('⁴', '^4')
      .replaceAll('⁵', '^5')
      .replaceAll('⁶', '^6')
      .replaceAll('⁷', '^7')
      .replaceAll('⁸', '^8')
      .replaceAll('⁹', '^9')
      .replaceAll('ⁿ', '^n')
      .replaceAll('ᴺ', '^N')
      .replaceAll('⁺', '^+')
      .replaceAll('⁻', '^-');

  final List<InlineSpan> spans = [];
  final double fontSize = baseStyle.fontSize ?? 12.0;
  final double subSupSize = (fontSize * 0.72).clamp(8.0, 16.0);
  final subSupStyle = baseStyle.copyWith(
    fontSize: subSupSize,
    fontWeight: FontWeight.w600,
  );

  int i = 0;
  while (i < normalized.length) {
    if (normalized[i] == '_') {
      i++;
      String sub = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        final closeChar = normalized[i] == '{' ? '}' : ')';
        i++;
        while (i < normalized.length && normalized[i] != closeChar) {
          sub += normalized[i];
          i++;
        }
        if (i < normalized.length) i++;
      } else {
        while (i < normalized.length &&
            RegExp(r'[a-zA-Z0-9]').hasMatch(normalized[i])) {
          sub += normalized[i];
          i++;
        }
      }
      if (sub.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, fontSize * 0.28),
              child: Text(sub, style: subSupStyle),
            ),
          ),
        );
      }
    } else if (normalized[i] == '^') {
      i++;
      String sup = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        i++;
        int depth = 1;
        while (i < normalized.length && depth > 0) {
          if (normalized[i] == '{' || normalized[i] == '(') depth++;
          if (normalized[i] == '}' || normalized[i] == ')') depth--;
          if (depth > 0) sup += normalized[i];
          i++;
        }
      } else {
        while (i < normalized.length &&
            RegExp(r'[a-zA-Z0-9\+\-]').hasMatch(normalized[i])) {
          sup += normalized[i];
          i++;
        }
      }
      if (sup.isNotEmpty) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, -fontSize * 0.38),
              child: Text(sup, style: subSupStyle),
            ),
          ),
        );
      }
    } else {
      String normal = '';
      while (i < normalized.length &&
          normalized[i] != '_' &&
          normalized[i] != '^') {
        normal += normalized[i];
        i++;
      }
      if (normal.isNotEmpty) {
        spans.add(TextSpan(text: normal, style: baseStyle));
      }
    }
  }
  return spans;
}

/// Panel de resultados y métricas operativas del sistema de colas multicanal (M/M/c y M/M/c/N):
/// Parámetros base, métricas de clientes (L, W), métricas de servidores y acordeón con
/// Desglose Teórico y Fórmulas con Sustituciones Numéricas Paso a Paso.
class MultiserverResultsPanel extends StatelessWidget {
  final MultiserverQueueResult result;

  const MultiserverResultsPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final double effLambda = result.lambdaEff ?? result.lambda;
    final String lambdaStr = _formatNum(result.lambda);
    final String muStr = _formatNum(result.mu);
    final String effLambdaStr = _formatNum(effLambda);
    final String rFixed = _formatFixed(result.r);
    final String rhoFixed = _formatFixed(result.rho);
    final String p0Fixed = _formatFixed(result.p0);
    final String lsFixed = _formatFixed(result.ls);
    final String lqFixed = _formatFixed(result.lq);
    final String wsFixed = _formatFixed(result.ws);
    final String wqFixed = _formatFixed(result.wq);
    final String activeFixed = _formatFixed(result.activeServers);
    final String idleFixed = _formatFixed(result.idleServers);
    final int c = result.servers;

    // Fórmulas y sustituciones específicas de P0 y Lq
    final String p0Formula;
    final String p0Substitution;
    final String lqFormula;
    final String lqSubstitution;

    if (result.isFinite) {
      final int n = result.capacity ?? c;
      p0Formula =
          'P_0 = [ ∑_(n=0)^(c-1) (r^n / n!) + (r^c / c!) · ((1 − ρ^(N-c+1)) / (1 − ρ)) ]^(-1)';
      p0Substitution =
          'P_0 = [ ∑_(n=0)^${c - 1} (($rFixed)^n / n!) + (($rFixed)^$c / $c!) · ((1 − ($rhoFixed)^(${n - c + 1})) / (1 − $rhoFixed)) ]^(-1) = $p0Fixed';
      lqFormula = 'L_q = ∑_(n=c)^N (n − c) · P_n';
      lqSubstitution = 'L_q = ∑_(n=$c)^$n (n − $c) · P_n = $lqFixed';
    } else {
      p0Formula =
          'P_0 = [ ∑_(n=0)^(c-1) (r^n / n!) + (r^c / c!) · (1 / (1 − ρ)) ]^(-1)';
      p0Substitution =
          'P_0 = [ ∑_(n=0)^${c - 1} (($rFixed)^n / n!) + (($rFixed)^$c / $c!) · (1 / (1 − $rhoFixed)) ]^(-1) = $p0Fixed';
      lqFormula = 'L_q = (P_0 · r^c · ρ) / [ c! · (1 − ρ)^2 ]';
      lqSubstitution =
          'L_q = ($p0Fixed · ($rFixed)^$c · $rhoFixed) / [ $c! · (1 − $rhoFixed)^2 ] = $lqFixed';
    }

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MÉTRICAS DEL SISTEMA MULTICANAL',
                    style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(result.parameterSummary, style: AppTextStyles.subtitle),
                const SizedBox(height: 14),

                // Métricas principales
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'ρ · Utilización',
                        value:
                            '${result.rho.toStringAsFixed(4)} (${(result.rho * 100).toStringAsFixed(2)}%)',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'P_0 · Sistema vacío',
                        value:
                            '${result.p0.toStringAsFixed(4)} (${(result.p0 * 100).toStringAsFixed(2)}%)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'L_s · Clientes en sistema',
                        value: result.ls.toStringAsFixed(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'L_q · Clientes en cola',
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
                        label: 'W_s · Tiempo en sistema',
                        value: result.ws.toStringAsFixed(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'W_q · Tiempo en cola',
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
                    Icon(Icons.people_outline_rounded,
                        size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('ESTADO DE LOS SERVIDORES (c = can.)',
                        style: AppTextStyles.label),
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
                      Icon(Icons.block_rounded,
                          size: 15, color: AppColors.primary),
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
        ),

        const SizedBox(height: 12),

        // --- Módulo Educativo: Desglose Teórico y Fórmulas Paso a Paso ---
        Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.functions_rounded,
              color: AppColors.primary,
            ),
            title: Text(
              'Desglose Teórico y Fórmulas',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Toca para ver el desarrollo y sustitución numérica',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 4),
                    _StepItem(
                      title: '1. Intensidad de Tráfico (r)',
                      formula: 'r = λ / μ',
                      substitution: 'r = $lambdaStr / $muStr = $rFixed',
                      description:
                          'Representa el número teórico de servidores requeridos para absorber la tasa de llegada.',
                      valueText: result.r.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '2. Factor de Utilización Nominal (ρ)',
                      formula: 'ρ = λ / (c · μ) = r / c',
                      substitution:
                          'ρ = $lambdaStr / ($c · $muStr) = $rFixed / $c = $rhoFixed',
                      description:
                          'Fracción media de capacidad operativa ocupada por la demanda a través de los $c servidores.',
                      valueText: result.rho.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '3. Probabilidad de Sistema Vacío (P_0)',
                      formula: p0Formula,
                      substitution: p0Substitution,
                      description:
                          'Probabilidad exacta de que no haya ningún cliente en el sistema y todos los $c servidores estén libres.',
                      valueText: result.p0.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '4. Clientes Esperados en la Cola (L_q)',
                      formula: lqFormula,
                      substitution: lqSubstitution,
                      description:
                          'Cantidad media de clientes que esperan en la línea antes de ser atendidos por los servidores.',
                      valueText: result.lq.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '5. Tiempo Esperado en la Cola (W_q)',
                      formula: 'W_q = L_q / λ_eff',
                      substitution: 'W_q = $lqFixed / $effLambdaStr = $wqFixed',
                      description:
                          'Tiempo medio que un cliente debe esperar en la fila antes de iniciar su atención.',
                      valueText: result.wq.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '6. Tiempo Esperado en el Sistema (W_s)',
                      formula: 'W_s = W_q + (1 / μ)',
                      substitution:
                          'W_s = $wqFixed + (1 / $muStr) = $wsFixed',
                      description:
                          'Tiempo total promedio que un cliente pasa dentro del sistema multicanal.',
                      valueText: result.ws.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '7. Clientes Esperados en el Sistema (L_s)',
                      formula: 'L_s = L_q + (λ_eff / μ)',
                      substitution:
                          'L_s = $lqFixed + ($effLambdaStr / $muStr) = $lsFixed',
                      description:
                          'Número promedio total de clientes dentro del sistema (en cola y en servicio).',
                      valueText: result.ls.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '8. Servidores Activos Ocupados (c_activos)',
                      formula: 'c_activos = λ_eff / μ',
                      substitution:
                          'c_activos = $effLambdaStr / $muStr = $activeFixed',
                      description:
                          'Número promedio de servidores ocupados simultáneamente atendiendo clientes.',
                      valueText: result.activeServers.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '9. Servidores Inactivos Ociosos (c̄)',
                      formula: 'c̄ = c − (λ_eff / μ)',
                      substitution: 'c̄ = $c − $activeFixed = $idleFixed',
                      description:
                          'Promedio de servidores desocupados o disponibles sin clientes asignados.',
                      valueText: result.idleServers.toStringAsFixed(4),
                    ),
                    if (result.isFinite &&
                        result.lambdaEff != null &&
                        result.blockingProbability != null) ...[
                      const SizedBox(height: 14),
                      _StepItem(
                        title: '10. Tasa de Llegada Efectiva (λ_eff)',
                        formula: 'λ_eff = λ · (1 − P_N)',
                        substitution:
                            'λ_eff = $lambdaStr · (1 − ${_formatFixed(result.blockingProbability!)}) = ${_formatFixed(result.lambdaEff!)}',
                        description:
                            'Tasa real de clientes que acceden al sistema sin ser rechazados por falta de cupo.',
                        valueText: result.lambdaEff!.toStringAsFixed(4),
                      ),
                      const SizedBox(height: 14),
                      _StepItem(
                        title: '11. Probabilidad de Bloqueo (P_N)',
                        formula: 'P_N = (r^N / (c! · c^(N-c))) · P_0',
                        substitution:
                            'P_N = (($rFixed)^${result.capacity!} / ($c! · $c^(${result.capacity! - c}))) · $p0Fixed = ${_formatFixed(result.blockingProbability!)}',
                        description:
                            'Probabilidad de que el sistema alcance su capacidad máxima N y se rechace la llegada.',
                        valueText: result.blockingProbability!.toStringAsFixed(4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style:
                  AppTextStyles.subtitle.copyWith(fontSize: 11.5),
              children: _parseFormulaSpans(
                label,
                AppTextStyles.subtitle.copyWith(fontSize: 11.5),
              ),
            ),
          ),
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

class _StepItem extends StatelessWidget {
  final String title;
  final String formula;
  final String substitution;
  final String description;
  final String valueText;

  const _StepItem({
    required this.title,
    required this.formula,
    required this.substitution,
    required this.description,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final formulaBaseStyle = const TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: [
        'Segoe UI',
        'Roboto',
        'Noto Sans',
        'Arial',
        'sans-serif',
      ],
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                    children: _parseFormulaSpans(
                      title,
                      AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Res: $valueText',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Bloque 1: Fórmula teórica general ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: RichText(
              text: TextSpan(
                style: formulaBaseStyle,
                children: [
                  TextSpan(
                    text: 'Fórmula: ',
                    style: formulaBaseStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ..._parseFormulaSpans(formula, formulaBaseStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // --- Bloque 2: Sustitución con los datos ingresados ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: RichText(
              text: TextSpan(
                style: formulaBaseStyle,
                children: [
                  TextSpan(
                    text: 'Sustitución: ',
                    style: formulaBaseStyle.copyWith(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ..._parseFormulaSpans(substitution, formulaBaseStyle),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.subtitle.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
