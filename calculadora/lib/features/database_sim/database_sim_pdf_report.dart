import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/database_simulation.dart';
import '../../models/distribution_type.dart';

/// Genera y comparte/imprime un reporte PDF con los parámetros de la
/// simulación, el resumen muestral vs. teórico, y la tabla completa
/// de observaciones generadas.
class DatabaseSimPdfReport {
  DatabaseSimPdfReport._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF2F6FED);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF62728A);
  static const PdfColor _border = PdfColor.fromInt(0xFFDCE6F5);
  static const PdfColor _surfaceAlt = PdfColor.fromInt(0xFFEAF1FC);

  static Future<Uint8List> generate(SimulationResult result) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(result, fontBold),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _textSecondary),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result, fontBold),
          pw.SizedBox(height: 16),
          _buildSummarySection(result, fontBold),
          pw.SizedBox(height: 20),
          _buildDataTable(result, fontBold),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> share(SimulationResult result) async {
    final bytes = await generate(result);
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'simulacion_${result.distributionType.isDiscrete ? "poisson" : "exponencial"}.pdf',
    );
  }

  static Future<void> print(SimulationResult result) async {
    final bytes = await generate(result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static pw.Widget _buildHeader(SimulationResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Quantis · Simulación de Base de Datos',
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: _primary)),
            pw.Text(
              result.distributionType.isDiscrete ? 'Poisson' : 'Exponencial',
              style: pw.TextStyle(font: fontBold, fontSize: 11, color: _textSecondary),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _border, thickness: 1),
      ],
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

  static pw.Widget _metricRow(String label, String value, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      margin: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(color: _surfaceAlt, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10.5, color: _textSecondary)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildParametersSection(SimulationResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Parámetros de la simulación', fontBold),
        _metricRow('Distribución',
            result.distributionType.isDiscrete ? 'Poisson (discreta)' : 'Exponencial (continua)',
            fontBold),
        _metricRow('λ (parámetro)', result.lambda.toStringAsFixed(4), fontBold),
        _metricRow('Número de variables', result.numVariables.toString(), fontBold),
        _metricRow('Observaciones por variable', result.numObservations.toString(), fontBold),
        _metricRow('Generado el',
            '${result.generatedAt.day}/${result.generatedAt.month}/${result.generatedAt.year} '
            '${result.generatedAt.hour}:${result.generatedAt.minute.toString().padLeft(2, '0')}',
            fontBold),
      ],
    );
  }

  static pw.Widget _buildSummarySection(SimulationResult result, pw.Font fontBold) {
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.white);
    final cellStyle = const pw.TextStyle(fontSize: 9.5);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Resumen muestral vs. teórico', fontBold),
        pw.Text(
          'E[X] teórico = ${result.theoreticalMean.toStringAsFixed(4)}   ·   '
          'Var(X) teórico = ${result.theoreticalVariance.toStringAsFixed(4)}',
          style: const pw.TextStyle(fontSize: 10, color: _textSecondary),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.6),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Variable', style: headerStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Media muestral', style: headerStyle)),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('σ muestral', style: headerStyle)),
              ],
            ),
            for (final v in result.variables)
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v.name, style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v.sampleMean.toStringAsFixed(4), style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v.sampleStdDev.toStringAsFixed(4), style: cellStyle)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDataTable(SimulationResult result, pw.Font fontBold) {
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white);
    final cellStyle = const pw.TextStyle(fontSize: 8.5);
    final isDiscrete = result.distributionType.isDiscrete;

    String fmt(double v) => isDiscrete ? v.toInt().toString() : v.toStringAsFixed(4);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Base de datos generada', fontBold),
        pw.Table(
          border: pw.TableBorder.all(color: _border, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('N°', style: headerStyle)),
                for (final v in result.variables)
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v.name, style: headerStyle)),
              ],
            ),
            for (int i = 0; i < result.numObservations; i++)
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: cellStyle)),
                  for (final v in result.variables)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(fmt(v.observations[i]), style: cellStyle),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
