import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/pdf_chart_image_builder.dart';
import '../../core/utils/pdf_formula_builder.dart';
import '../../models/multiserver_queue_model_type.dart';
import '../../models/multiserver_queue_result.dart';
import 'multiserver_chart_painter.dart';

String _fmt(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  return s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
}

String _fix(double v, [int d = 4]) => v.toStringAsFixed(d);

/// Genera y comparte/imprime reportes formales en PDF para el módulo de
/// colas multicanal M/M/c y M/M/c/N con tipografía matemática completa,
/// letras griegas (λ, μ, ρ, σ), operadores (∑, ≤, ·) y subíndices/superíndices vectoriales.
class MultiserverPdfReport {
  MultiserverPdfReport._();

  static Future<Uint8List> generate(MultiserverQueueResult result) async {
    await PdfFonts.load();

    final chartPainter = MultiserverChartPainter.fromDistribution(
      result.distribution,
      cumulative: false,
      servers: result.servers,
    );
    final chartImageBytes = await PdfChartImageBuilder.renderPainter(
      painter: chartPainter,
    );

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: PdfFonts.regular,
          bold: PdfFonts.bold,
          fontFallback: PdfFonts.fontFallback,
        ),
        header: (context) => _buildHeader(result),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result),
          pw.SizedBox(height: 16),
          _buildMetricsSection(result),
          pw.SizedBox(height: 16),
          _buildServersSection(result),
          if (result.isFinite) ...[
            pw.SizedBox(height: 16),
            _buildFiniteSection(result),
          ],
          pw.SizedBox(height: 16),
          _buildTheoreticalBreakdownSection(result),
          pw.SizedBox(height: 20),
          _buildChartSection(result, chartImageBytes),
          pw.SizedBox(height: 20),
          _buildTableSection(result),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> share(MultiserverQueueResult result) async {
    final bytes = await generate(result);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'reporte_multicanal_${result.type.isFinite ? "finito" : "infinito"}.pdf',
    );
  }

  static Future<void> print(MultiserverQueueResult result) async {
    final bytes = await generate(result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------------
  // Secciones del documento
  // ---------------------------------------------------------------------------

  static pw.Widget _buildHeader(MultiserverQueueResult result) {
    final notation = result.type.kendallNotation
        .replaceAll('\u221E', '∞')
        .replaceAll('inf', '∞');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Quantis · Reporte de Colas Multicanal',
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: 16,
                color: kPrimary,
              ),
            ),
            pw.Text(
              notation,
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: 11,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: kBorder, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: pw.TextStyle(
          font: PdfFonts.regular,
          fontFallback: PdfFonts.fontFallback,
          fontSize: 9,
          color: kTextSecondary,
        ),
      ),
    );
  }

  static pw.Widget _buildParametersSection(MultiserverQueueResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Modelo y parámetros de entrada'),
        pw.Text(
          result.type.label,
          style: pw.TextStyle(
            font: PdfFonts.bold,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 13,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          result.parameterSummary,
          style: pw.TextStyle(
            font: PdfFonts.regular,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMetricsSection(MultiserverQueueResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Métricas del sistema multicanal'),
        buildPdfMetricRow(
          'ρ · Utilización nominal',
          '${_fix(result.rho)} (${(result.rho * 100).toStringAsFixed(2)}%)',
        ),
        buildPdfMetricRow(
          'P_0 · Probabilidad de sistema vacío',
          '${_fix(result.p0)} (${(result.p0 * 100).toStringAsFixed(2)}%)',
        ),
        buildPdfMetricRow(
          'L_s · Clientes esperados en el sistema',
          _fix(result.ls),
        ),
        buildPdfMetricRow(
          'L_q · Clientes esperados en la cola',
          _fix(result.lq),
        ),
        buildPdfMetricRow(
          'W_s · Tiempo esperado en el sistema',
          _fix(result.ws),
        ),
        buildPdfMetricRow(
          'W_q · Tiempo esperado en la cola',
          _fix(result.wq),
        ),
      ],
    );
  }

  static pw.Widget _buildServersSection(MultiserverQueueResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle(
          'Estado de los servidores (c = ${result.servers})',
        ),
        buildPdfMetricRow(
          'Servidores activos (ocupados)',
          _fix(result.activeServers),
        ),
        buildPdfMetricRow(
          'c̄ · Servidores inactivos (ociosos)',
          _fix(result.idleServers),
        ),
      ],
    );
  }

  static pw.Widget _buildFiniteSection(MultiserverQueueResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Capacidad finita (N = ${result.capacity})'),
        buildPdfMetricRow(
          'λ_{eff} · Tasa de llegada efectiva',
          _fix(result.lambdaEff!),
        ),
        buildPdfMetricRow(
          'Tasa de pérdida de clientes',
          _fix(result.lossRate!),
        ),
        buildPdfMetricRow(
          'P_N · Probabilidad de bloqueo (sistema lleno)',
          '${_fix(result.blockingProbability!)} (${(result.blockingProbability! * 100).toStringAsFixed(2)}%)',
        ),
      ],
    );
  }

  static pw.Widget _buildTheoreticalBreakdownSection(
    MultiserverQueueResult result,
  ) {
    final double effLambda = result.lambdaEff ?? result.lambda;
    final String lambdaStr = _fmt(result.lambda);
    final String muStr = _fmt(result.mu);
    final String effStr = _fmt(effLambda);
    final String rFixed = _fix(result.r);
    final String rhoFixed = _fix(result.rho);
    final String rhoStr = _fmt(result.rho);
    final String p0Fix = _fix(result.p0);
    final String lsFix = _fix(result.ls);
    final String lqFix = _fix(result.lq);
    final String wsFix = _fix(result.ws);
    final String wqFix = _fix(result.wq);
    final String activeFix = _fix(result.activeServers);
    final String idleFix = _fix(result.idleServers);
    final int c = result.servers;

    String p0Formula;
    String p0Subs;
    String lqFormula;
    String lqSubs;

    if (result.isFinite) {
      final int n = result.capacity ?? c;
      p0Formula =
          'P_0 = [ ∑_{n=0}^{c-1} (r^n / n!) + (r^c / c!) · ((1 - ρ^{N-c+1}) / (1 - ρ)) ]^{-1}';
      p0Subs =
          'P_0 = [ ∑_{n=0}^{${c - 1}} (($rFixed)^n / n!) + (($rFixed)^$c / $c!) · ((1 - ($rhoStr)^{${n - c + 1}}) / (1 - $rhoStr)) ]^{-1} = $p0Fix';
      lqFormula = 'L_q = ∑_{n=c}^N (n - c) · P_n';
      lqSubs = 'L_q = ∑_{n=$c}^$n (n - $c) · P_n = $lqFix';
    } else {
      p0Formula =
          'P_0 = [ ∑_{n=0}^{c-1} (r^n / n!) + (r^c / c!) · (1 / (1 - ρ)) ]^{-1}';
      p0Subs =
          'P_0 = [ ∑_{n=0}^{${c - 1}} (($rFixed)^n / n!) + (($rFixed)^$c / $c!) · (1 / (1 - $rhoStr)) ]^{-1} = $p0Fix';
      lqFormula = 'L_q = (P_0 · r^c · ρ) / [ c! · (1 - ρ)^2 ]';
      lqSubs =
          'L_q = ($p0Fix · ($rFixed)^$c · $rhoStr) / [ $c! · (1 - $rhoStr)^2 ] = $lqFix';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Desglose teórico y fórmulas paso a paso'),
        buildPdfStepItem(
          title: '1. Intensidad de Tráfico (r)',
          formula: 'r = λ / μ',
          substitution: 'r = $lambdaStr / $muStr = $rFixed',
          description:
              'Número teórico de servidores requeridos para absorber la tasa media de llegada entrante.',
          valueText: rFixed,
        ),
        buildPdfStepItem(
          title: '2. Factor de Utilización Nominal (ρ)',
          formula: 'ρ = λ / (c · μ) = r / c',
          substitution:
              'ρ = $lambdaStr / ($c · $muStr) = $rFixed / $c = $rhoFixed',
          description:
              'Fracción promedio de ocupación de la capacidad global instalada a través de los $c servidores.',
          valueText: rhoFixed,
        ),
        buildPdfStepItem(
          title: '3. Probabilidad de Sistema Vacío (P_0)',
          formula: p0Formula,
          substitution: p0Subs,
          description:
              'Probabilidad exacta de que no haya ningún cliente en el sistema y todos los $c servidores se encuentren libres.',
          valueText: p0Fix,
        ),
        buildPdfStepItem(
          title: '4. Clientes Esperados en la Cola (L_q)',
          formula: lqFormula,
          substitution: lqSubs,
          description:
              'Cantidad media de clientes que esperan en la fila antes de ser atendidos por los servidores.',
          valueText: lqFix,
        ),
        buildPdfStepItem(
          title: '5. Tiempo Esperado en la Cola (W_q)',
          formula: 'W_q = L_q / λ_{eff}',
          substitution: 'W_q = $lqFix / $effStr = $wqFix',
          description:
              'Tiempo medio que un cliente debe esperar en la fila antes de iniciar su atención.',
          valueText: wqFix,
        ),
        buildPdfStepItem(
          title: '6. Tiempo Esperado en el Sistema (W_s)',
          formula: 'W_s = W_q + (1 / μ)',
          substitution: 'W_s = $wqFix + (1 / $muStr) = $wsFix',
          description:
              'Tiempo total promedio que un cliente pasa dentro del sistema multicanal.',
          valueText: wsFix,
        ),
        buildPdfStepItem(
          title: '7. Clientes Esperados en el Sistema (L_s)',
          formula: 'L_s = L_q + (λ_{eff} / μ)',
          substitution: 'L_s = $lqFix + ($effStr / $muStr) = $lsFix',
          description:
              'Número promedio total de clientes dentro del sistema (en cola y en atención simultánea).',
          valueText: lsFix,
        ),
        buildPdfStepItem(
          title: '8. Servidores Activos Ocupados (c_{activos})',
          formula: 'c_{activos} = λ_{eff} / μ',
          substitution: 'c_{activos} = $effStr / $muStr = $activeFix',
          description:
              'Número promedio de servidores ocupados simultáneamente atendiendo clientes.',
          valueText: activeFix,
        ),
        buildPdfStepItem(
          title: '9. Servidores Inactivos Ociosos (c̄)',
          formula: 'c̄ = c - (λ_{eff} / μ)',
          substitution: 'c̄ = $c - $activeFix = $idleFix',
          description:
              'Promedio de servidores disponibles o libres sin demanda asignada.',
          valueText: idleFix,
        ),
        if (result.isFinite &&
            result.lambdaEff != null &&
            result.blockingProbability != null) ...[
          buildPdfStepItem(
            title: '10. Tasa de Llegada Efectiva (λ_{eff})',
            formula: 'λ_{eff} = λ · (1 - P_N)',
            substitution:
                'λ_{eff} = $lambdaStr · (1 - ${_fix(result.blockingProbability!)}) = ${_fix(result.lambdaEff!)}',
            description:
                'Tasa real de clientes que logran ingresar al sistema sin ser rechazados por falta de cupo.',
            valueText: _fix(result.lambdaEff!),
          ),
          buildPdfStepItem(
            title: '11. Probabilidad de Bloqueo (P_N)',
            formula: 'P_N = (r^N / (c! · c^{N-c})) · P_0',
            substitution:
                'P_N = (($rFixed)^{${result.capacity!}} / ($c! · $c^{${result.capacity! - c}})) · $p0Fix = ${_fix(result.blockingProbability!)}',
            description:
                'Probabilidad de que el sistema alcance su capacidad máxima N y se rechace la llegada.',
            valueText: _fix(result.blockingProbability!),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildChartSection(
    MultiserverQueueResult result,
    Uint8List chartImageBytes,
  ) {
    const barColor = PdfColor.fromInt(0xFF7EA6F5); // AppColors.primaryLight
    const serverColor = PdfColor.fromInt(0xFF2F6FED); // AppColors.primary

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Gráfica de Probabilidad de Estado (P_n)'),
        pw.Container(
          width: double.infinity,
          height: 190,
          child: pw.Image(
            pw.MemoryImage(chartImageBytes),
            fit: pw.BoxFit.contain,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildLegendItem(color: barColor, label: 'Probabilidad de estado P_n'),
            pw.SizedBox(width: 18),
            _buildLegendItem(
              color: serverColor,
              label: 'Umbral de servidores (c = ${result.servers})',
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLegendItem({
    required PdfColor color,
    required String label,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: PdfFonts.regular,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 8.5,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableSection(MultiserverQueueResult result) {
    final headerStyle = pw.TextStyle(
      font: PdfFonts.bold,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 9.5,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(
      font: PdfFonts.regular,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 8.5,
    );
    final points = result.distribution.length > 15
        ? result.distribution.take(15).toList()
        : result.distribution;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle(
          'Tabla de probabilidades de estado (${points.length} estados)',
        ),
        pw.Table(
          border: pw.TableBorder.all(color: kBorder, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: kPrimary),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('n (Clientes)', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('P(N = n)', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('P(N ≤ n)', style: headerStyle),
                ),
              ],
            ),
            for (final p in points)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(p.n.toString(), style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      p.probability.toStringAsFixed(4),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      p.cumulative.toStringAsFixed(4),
                      style: cellStyle,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}