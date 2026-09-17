import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/stat_procedure_dialog.dart';
import '../../models/queue_result.dart';
import 'queue_stat_procedures.dart';

/// Formatea un número decimal eliminando ceros innecesarios al final
String _formatNum(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  if (s.contains('.')) {
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s;
}

/// Formatea un resultado a 4 decimales fijos
String _formatFixed(double v) => v.toStringAsFixed(4);

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

/// Panel de métricas operativas del sistema de colas con desglose teórico
/// paso a paso utilizando símbolos oficiales (ρ, λ, μ) y notación limpia.
class QueueResultsPanel extends StatelessWidget {
  final QueueResult result;

  const QueueResultsPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Genera procedimientos y construye mapa label → procedimiento
    final procs = QueueStatProcedures.build(result);
    final procMap = {for (final p in procs) p.statLabel: p};

    void onTile(String label) {
      final proc = procMap[label];
      if (proc == null) return;
      StatProcedureDialog.show(context, procedure: proc);
    }

    final double effLambda = result.lambdaEff ?? result.lambda;
    final String lambdaStr = _formatNum(result.lambda);
    final String muStr = _formatNum(result.mu);
    final String effLambdaStr = _formatNum(effLambda);
    final String rhoStr = _formatNum(result.rho);
    final String rhoFixed = _formatFixed(result.rho);
    final String p0Fixed = _formatFixed(result.p0);
    final String lsFixed = _formatFixed(result.ls);
    final String lqFixed = _formatFixed(result.lq);
    final String wsFixed = _formatFixed(result.ws);
    final String wqFixed = _formatFixed(result.wq);

    // Sustituciones específicas para P0
    final String p0Formula;
    final String p0Substitution;
    if (result.isFinite) {
      final int cap = result.capacity ?? 1;
      if ((result.rho - 1.0).abs() < 1e-9) {
        p0Formula = 'P_0 = 1 / (N + 1)';
        p0Substitution = 'P_0 = 1 / ($cap + 1) = $p0Fixed';
      } else {
        p0Formula = 'P_0 = (1 − ρ) / (1 − ρ^(N+1))';
        p0Substitution =
            'P_0 = (1 − $rhoStr) / (1 − ($rhoStr)^(${cap + 1})) = $p0Fixed';
      }
    } else {
      p0Formula = 'P_0 = 1 − ρ';
      p0Substitution = 'P_0 = 1 − $rhoStr = $p0Fixed';
    }

    return Column(
      children: [
        // --- Panel Principal de Métricas ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MÉTRICAS DEL SISTEMA', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(result.parameterSummary, style: AppTextStyles.subtitle),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'ρ · Utilización',
                        value: result.rho.toStringAsFixed(4),
                        onTap: () => onTile('ρ · Utilización'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'P_0 · Sistema vacío',
                        value: result.p0.toStringAsFixed(4),
                        onTap: () => onTile('P_0 · Sistema vacío'),
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
                        onTap: () => onTile('L_s · Clientes en sistema'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'L_q · Clientes en cola',
                        value: result.lq.toStringAsFixed(4),
                        onTap: () => onTile('L_q · Clientes en cola'),
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
                        onTap: () => onTile('W_s · Tiempo en sistema'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: 'W_q · Tiempo en cola',
                        value: result.wq.toStringAsFixed(4),
                        onTap: () => onTile('W_q · Tiempo en cola'),
                      ),
                    ),
                  ],
                ),
                if (result.isFinite) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Icon(
                        Icons.block_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text('CAPACIDAD FINITA (N)', style: AppTextStyles.label),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'λ_{eff} · Llegada efectiva',
                          value: result.lambdaEff!.toStringAsFixed(4),
                          accent: true,
                          onTap: () => onTile('λ_{eff} · Llegada efectiva'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Tasa de pérdida',
                          value: result.lossRate!.toStringAsFixed(4),
                          accent: true,
                          onTap: () => onTile('Tasa de pérdida'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _MetricTile(
                    label: 'P(N) · Probabilidad de bloqueo (sistema lleno)',
                    value:
                        '${result.blockingProbability!.toStringAsFixed(4)}  (${(result.blockingProbability! * 100).toStringAsFixed(2)}%)',
                    accent: true,
                    fullWidth: true,
                    onTap:
                        () => onTile(
                          'P(N) · Probabilidad de bloqueo (sistema lleno)',
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- Módulo Educativo: Desglose Teórico Paso a Paso ---
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
              'Toca para ver el desarrollo de cada métrica',
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
                      title: '1. Factor de Utilización (ρ)',
                      formula: 'ρ = λ / μ',
                      substitution: 'ρ = $lambdaStr / $muStr = $rhoFixed',
                      description:
                          'Mide la fracción de tiempo que el servidor se encuentra ocupado atendiendo la demanda.',
                      valueText: result.rho.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '2. Probabilidad de Sistema Vacío (P_0)',
                      formula: p0Formula,
                      substitution: p0Substitution,
                      description:
                          'Representa la probabilidad exacta de que no haya ningún cliente en el sistema al momento de la llegada.',
                      valueText: result.p0.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '3. Clientes Esperados en el Sistema (L_s)',
                      formula: 'L_s = L_q + (λ_eff / μ)',
                      substitution:
                          'L_s = $lqFixed + ($effLambdaStr / $muStr) = $lsFixed',
                      description:
                          'Número promedio de clientes que se encuentran tanto haciendo fila como siendo atendidos.',
                      valueText: result.ls.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '4. Clientes Esperados en la Cola (L_q)',
                      formula: 'L_q = W_q · λ_eff',
                      substitution: 'L_q = $wqFixed · $effLambdaStr = $lqFixed',
                      description:
                          'Cantidad media de clientes que esperan en la línea antes de ser atendidos por los servidores.',
                      valueText: result.lq.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '5. Tiempo Esperado en el Sistema (W_s)',
                      formula: 'W_s = W_q + (1 / μ)',
                      substitution: 'W_s = $wqFixed + (1 / $muStr) = $wsFixed',
                      description:
                          'Tiempo total promedio que un cliente pasa dentro del sistema desde que llega hasta que se marcha.',
                      valueText: result.ws.toStringAsFixed(4),
                    ),
                    const SizedBox(height: 14),
                    _StepItem(
                      title: '6. Tiempo Esperado en la Cola (W_q)',
                      formula: 'W_q = L_q / λ_eff',
                      substitution: 'W_q = $lqFixed / $effLambdaStr = $wqFixed',
                      description:
                          'Tiempo medio que un cliente debe esperar en la fila antes de iniciar su servicio.',
                      valueText: result.wq.toStringAsFixed(4),
                    ),
                    if (result.isFinite &&
                        result.lambdaEff != null &&
                        result.blockingProbability != null) ...[
                      const SizedBox(height: 14),
                      _StepItem(
                        title: '7. Tasa de Llegada Efectiva (λ_eff)',
                        formula: 'λ_eff = λ · (1 − P_N)',
                        substitution:
                            'λ_eff = $lambdaStr · (1 − ${_formatFixed(result.blockingProbability!)}) = ${_formatFixed(result.lambdaEff!)}',
                        description:
                            'Tasa media de clientes que efectivamente ingresan al sistema tras descartar los bloqueos.',
                        valueText: result.lambdaEff!.toStringAsFixed(4),
                      ),
                      const SizedBox(height: 14),
                      _StepItem(
                        title: '8. Probabilidad de Bloqueo (P_N)',
                        formula: 'P_N = P_0 · ρ^N',
                        substitution:
                            'P_N = $p0Fixed · ($rhoStr)^(${result.capacity!}) = ${_formatFixed(result.blockingProbability!)}',
                        description:
                            'Probabilidad de que el sistema alcance su capacidad máxima N y se rechace la llegada.',
                        valueText: result.blockingProbability!.toStringAsFixed(
                          4,
                        ),
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
  final VoidCallback? onTap;

  const _MetricTile({
    required this.label,
    required this.value,
    this.accent = false,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final borderColor =
        accent
            ? (interactive ? AppColors.primaryLight : AppColors.primaryLight)
            : (interactive
                ? AppColors.primary.withValues(alpha: 0.30)
                : AppColors.border);

    return Ink(
      decoration: BoxDecoration(
        color: accent ? AppColors.surfaceAlt : AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        splashColor: AppColors.primaryLight.withValues(alpha: 0.20),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppTextStyles.label,
                        children: _parseFormulaSpans(
                          label,
                          AppTextStyles.label,
                        ),
                      ),
                    ),
                  ),
                  if (interactive) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.primary.withValues(alpha: 0.55),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(value, style: AppTextStyles.momentValue),
            ],
          ),
        ),
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
