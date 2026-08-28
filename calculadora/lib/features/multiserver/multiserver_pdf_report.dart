import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/multiserver_queue_model_type.dart';
import '../../models/multiserver_queue_result.dart';

/// Genera y comparte/imprime un reporte formal en PDF con los
/// parámetros calculados, métricas operativas, servidores activos/inactivos,
/// tabla de probabilidades y gráfico de la distribución para sistemas multicanal (M/M/c).
class MultiserverPdfReport {
  MultiserverPdfReport._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF2F6FED);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF62728A);
  static const PdfColor _border = PdfColor.fromInt(0xFFDCE6F5);
  static const PdfColor _surfaceAlt = PdfColor.fromInt(0xFFEAF1FC);

  /// Genera los bytes del documento PDF.
  static Future<Uint8List> generate(MultiserverQueueResult result) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(result, fontBold),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result, fontBold),
          pw.SizedBox(height: 16),
          _buildMetricsSection(result, fontBold),
          pw.SizedBox(height: 16),
          _buildServersSection(result, fontBold),
          if (result.isFinite) ...[
            pw.SizedBox(height: 16),
            _buildFiniteSection(result, fontBold),
          ],
          pw.SizedBox(height: 20),
          _buildChartSection(result, fontBold),
          pw.SizedBox(height: 20),
          _buildTableSection(result, fontBold),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> share(MultiserverQueueResult result) async {
    final bytes = await generate(result);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_multicanal_${result.type.isFinite ? "finito" : "infinito"}.pdf',
    );
  }

  static Future<void> print(MultiserverQueueResult result) async {
    final bytes = await generate(result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------
  // Secciones del documento
  // ---------------------------------------------------------------------

  static pw.Widget _buildHeader(MultiserverQueueResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Quantis · Reporte de Líneas de Espera Multicanal',
                style: pw.TextStyle(font: fontBold, fontSize: 15, color: _primary)),
            pw.Text(result.type.kendallNotation,
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: _textSecondary)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _border, thickness: 1),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _textSecondary),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(font: fontBold, fontSize: 11, color: _primary, letterSpacing: 0.5),
      ),
    );
  }

  static pw.Widget _buildParametersSection(MultiserverQueueResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Modelo y parámetros de entrada', fontBold),
        pw.Text(result.type.label, style: pw.TextStyle(font: fontBold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.Text(result.parameterSummary, style: const pw.TextStyle(fontSize: 10.5)),
      ],
    );
  }

  static pw.Widget _metricRow(String label, String value, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(
        color: _surfaceAlt,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10.5, color: _textSecondary)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricsSection(MultiserverQueueResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Métricas del sistema multicanal', fontBold),
        _metricRow('ρ · Factor de utilización nominal',
            '${result.rho.toStringAsFixed(4)} (${(result.rho * 100).toStringAsFixed(2)}%)', fontBold),
        _metricRow('P₀ · Probabilidad de sistema totalmente vacío',
            '${result.p0.toStringAsFixed(4)} (${(result.p0 * 100).toStringAsFixed(2)}%)', fontBold),
        _metricRow('Lₛ · Clientes esperados en el sistema', result.ls.toStringAsFixed(4), fontBold),
        _metricRow('Lᵩ · Clientes esperados en la cola', result.lq.toStringAsFixed(4), fontBold),
        _metricRow('Wₛ · Tiempo esperado en el sistema', result.ws.toStringAsFixed(4), fontBold),
        _metricRow('Wᵩ · Tiempo esperado en la cola', result.wq.toStringAsFixed(4), fontBold),
      ],
    );
  }

  static pw.Widget _buildServersSection(MultiserverQueueResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Estado de los servidores (c = ${result.servers})', fontBold),
        _metricRow('Servidores activos (ocupados)', result.activeServers.toStringAsFixed(4), fontBold),
        _metricRow('c̄ · Servidores inactivos (ociosos)', result.idleServers.toStringAsFixed(4), fontBold),
      ],
    );
  }

  static pw.Widget _buildFiniteSection(MultiserverQueueResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Capacidad finita (N = ${result.capacity})', fontBold),
        _metricRow('λ_eff · Tasa de llegada efectiva', result.lambdaEff!.toStringAsFixed(4), fontBold),
        _metricRow('Tasa de pérdida de clientes', result.lossRate!.toStringAsFixed(4), fontBold),
        _metricRow(
          'P_N · Probabilidad de bloqueo',
          '${result.blockingProbability!.toStringAsFixed(4)} (${(result.blockingProbability! * 100).toStringAsFixed(2)}%)',
          fontBold,
        ),
      ],
    );
  }

  static pw.Widget _buildChartSection(MultiserverQueueResult result, pw.Font fontBold) {
    final maxP = result.distribution
        .map((p) => p.probability)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final barMax = maxP <= 0 ? 1.0 : maxP * 1.15;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Distribución de probabilidad Pₙ', fontBold),
        pw.Container(
          height: 160,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final point in result.distribution)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          height: 120 * (point.probability / barMax),
                          decoration: pw.BoxDecoration(
                            color: point.n == result.servers
                                ? _primary
                                : const PdfColor.fromInt(0xFF7EA6F5),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          point.n.toString(),
                          style: const pw.TextStyle(fontSize: 6, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableSection(MultiserverQueueResult result, pw.Font fontBold) {
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white);
    final cellStyle = const pw.TextStyle(fontSize: 9.5);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tabla de probabilidades de estado', fontBold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.6),
          columnWidths: const {
            0: pw.FlexColumnWidth(1),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('n', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Pₙ (absoluta)', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('P(N ≤ n) (acumulada)', style: headerStyle),
                ),
              ],
            ),
            for (final point in result.distribution)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      point.n == result.servers ? '${point.n} (c)' : point.n.toString(),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(point.probability.toStringAsFixed(4), style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(point.cumulative.toStringAsFixed(4), style: cellStyle),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
