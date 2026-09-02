import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/pdf_chart_image_builder.dart';
import '../../core/utils/pdf_formula_builder.dart';
import '../../models/queue_model_type.dart';
import '../../models/queue_result.dart';
import 'queue_chart_painter.dart';

/// Formatea un número decimal eliminando ceros innecesarios al final
String _fmt(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  return s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
}

String _fix(double v, [int d = 4]) => v.toStringAsFixed(d);

/// Genera y comparte/imprime un reporte formal en PDF con los parámetros
/// calculados, desglose teórico paso a paso con fórmulas, sustitución real
/// y tabla de distribución de estado del sistema de colas unicanal (M/M/1 y M/M/1/N).
class QueuePdfReport {
  QueuePdfReport._();

  /// Genera los bytes del PDF.
  static Future<Uint8List> generate(QueueResult result) async {
    await PdfFonts.load();

    final chartPainter = QueueChartPainter.fromDistribution(
      result.distribution,
      cumulative: false,
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

  static Future<void> share(QueueResult result) async {
    final bytes = await generate(result);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'reporte_colas_${result.type.isFinite ? "finito" : "infinito"}.pdf',
    );
  }

  static Future<void> print(QueueResult result) async {
    final bytes = await generate(result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------------
  // Secciones del documento
  // ---------------------------------------------------------------------------

  static pw.Widget _buildHeader(QueueResult result) {
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
              'Quantis · Reporte de Líneas de Espera',
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

  static pw.Widget _buildParametersSection(QueueResult result) {
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

  static pw.Widget _buildMetricsSection(QueueResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Métricas del sistema'),
        buildPdfMetricRow(
          'ρ · Factor de utilización',
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

  static pw.Widget _buildFiniteSection(QueueResult result) {
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

  static pw.Widget _buildTheoreticalBreakdownSection(QueueResult result) {
    final double effLambda = result.lambdaEff ?? result.lambda;
    final String lambdaStr = _fmt(result.lambda);
    final String muStr = _fmt(result.mu);
    final String effStr = _fmt(effLambda);
    final String rhoStr = _fmt(result.rho);
    final String rhoFix = _fix(result.rho);
    final String p0Fix = _fix(result.p0);
    final String lsFix = _fix(result.ls);
    final String lqFix = _fix(result.lq);
    final String wsFix = _fix(result.ws);
    final String wqFix = _fix(result.wq);

    String p0Formula;
    String p0Subs;
    if (result.isFinite) {
      final int cap = result.capacity ?? 1;
      if ((result.rho - 1.0).abs() < 1e-9) {
        p0Formula = 'P_0 = 1 / (N + 1)';
        p0Subs = 'P_0 = 1 / ($cap + 1) = $p0Fix';
      } else {
        p0Formula = 'P_0 = (1 - ρ) / (1 - ρ^{N+1})';
        p0Subs = 'P_0 = (1 - $rhoStr) / (1 - ($rhoStr)^{${cap + 1}}) = $p0Fix';
      }
    } else {
      p0Formula = 'P_0 = 1 - ρ';
      p0Subs = 'P_0 = 1 - $rhoStr = $p0Fix';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Desglose teórico y fórmulas paso a paso'),
        buildPdfStepItem(
          title: '1. Factor de Utilización (ρ)',
          formula: 'ρ = λ / μ',
          substitution: 'ρ = $lambdaStr / $muStr = $rhoFix',
          description:
              'Mide la fracción de tiempo que el servidor se encuentra ocupado atendiendo la demanda.',
          valueText: rhoFix,
        ),
        buildPdfStepItem(
          title: '2. Probabilidad de Sistema Vacío (P_0)',
          formula: p0Formula,
          substitution: p0Subs,
          description:
              'Representa la probabilidad exacta de que no haya ningún cliente en el sistema al momento de la llegada.',
          valueText: p0Fix,
        ),
        buildPdfStepItem(
          title: '3. Clientes Esperados en el Sistema (L_s)',
          formula: 'L_s = L_q + (λ_{eff} / μ)',
          substitution: 'L_s = $lqFix + ($effStr / $muStr) = $lsFix',
          description:
              'Número promedio de clientes que se encuentran tanto haciendo fila como siendo atendidos.',
          valueText: lsFix,
        ),
        buildPdfStepItem(
          title: '4. Clientes Esperados en la Cola (L_q)',
          formula: 'L_q = W_q · λ_{eff}',
          substitution: 'L_q = $wqFix · $effStr = $lqFix',
          description:
              'Cantidad media de clientes que esperan en la línea antes de ser atendidos por el servidor.',
          valueText: lqFix,
        ),
        buildPdfStepItem(
          title: '5. Tiempo Esperado en el Sistema (W_s)',
          formula: 'W_s = W_q + (1 / μ)',
          substitution: 'W_s = $wqFix + (1 / $muStr) = $wsFix',
          description:
              'Tiempo total promedio que un cliente pasa dentro del sistema desde que llega hasta que se marcha.',
          valueText: wsFix,
        ),
        buildPdfStepItem(
          title: '6. Tiempo Esperado en la Cola (W_q)',
          formula: 'W_q = L_q / λ_{eff}',
          substitution: 'W_q = $lqFix / $effStr = $wqFix',
          description:
              'Tiempo medio que un cliente debe esperar en la fila antes de iniciar su servicio.',
          valueText: wqFix,
        ),
        if (result.isFinite &&
            result.lambdaEff != null &&
            result.blockingProbability != null) ...[
          buildPdfStepItem(
            title: '7. Tasa de Llegada Efectiva (λ_{eff})',
            formula: 'λ_{eff} = λ · (1 - P_N)',
            substitution:
                'λ_{eff} = $lambdaStr · (1 - ${_fix(result.blockingProbability!)}) = ${_fix(result.lambdaEff!)}',
            description:
                'Tasa media de clientes que efectivamente logran acceder al sistema sin ser rechazados por falta de cupo.',
            valueText: _fix(result.lambdaEff!),
          ),
          buildPdfStepItem(
            title: '8. Probabilidad de Bloqueo (P_N)',
            formula: 'P_N = P_0 · ρ^N',
            substitution:
                'P_N = $p0Fix · ($rhoStr)^{${result.capacity!}} = ${_fix(result.blockingProbability!)}',
            description:
                'Probabilidad de que el sistema alcance su capacidad máxima N y se rechace la llegada.',
            valueText: _fix(result.blockingProbability!),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildChartSection(
    QueueResult result,
    Uint8List chartImageBytes,
  ) {
    const barColor = PdfColor.fromInt(0xFF7EA6F5); // AppColors.primaryLight

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
            _buildLegendItem(
              color: barColor,
              label: 'Probabilidad de estado P_n',
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

  static pw.Widget _buildTableSection(QueueResult result) {
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