import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/pdf_formula_builder.dart';
import '../../models/database_simulation.dart';
import '../../models/distribution_type.dart';

/// Genera y comparte/imprime un reporte PDF con los parámetros de la
/// simulación, el resumen muestral vs. teórico, y la tabla completa
/// de observaciones generadas con tipografía Unicode completa.
class DatabaseSimPdfReport {
  DatabaseSimPdfReport._();

  static Future<Uint8List> generate(SimulationResult result) async {
    await PdfFonts.load();
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
        footer: (context) => pw.Align(
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
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result),
          pw.SizedBox(height: 16),
          _buildSummarySection(result),
          pw.SizedBox(height: 20),
          _buildDataTable(result),
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
          'simulacion_${result.distributionType == DistributionType.poisson ? "poisson" : "exponencial"}.pdf',
    );
  }

  static Future<void> print(SimulationResult result) async {
    final bytes = await generate(result);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static pw.Widget _buildHeader(SimulationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Quantis · Simulación de Base de Datos',
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: 16,
                color: kPrimary,
              ),
            ),
            pw.Text(
              result.distributionType == DistributionType.poisson
                  ? 'Poisson'
                  : 'Exponencial',
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

  static pw.Widget _buildParametersSection(SimulationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Parámetros de la simulación'),
        buildPdfMetricRow(
          'Distribución',
          result.distributionType == DistributionType.poisson
              ? 'Poisson (discreta)'
              : 'Exponencial (continua)',
        ),
        buildPdfMetricRow('λ · Parámetro', result.lambda.toStringAsFixed(4)),
        buildPdfMetricRow(
          'Número de variables',
          result.numVariables.toString(),
        ),
        buildPdfMetricRow(
          'Observaciones por variable',
          result.numObservations.toString(),
        ),
        buildPdfMetricRow(
          'Generado el',
          '${result.generatedAt.day}/${result.generatedAt.month}/${result.generatedAt.year} '
              '${result.generatedAt.hour}:${result.generatedAt.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(SimulationResult result) {
    final headerStyle = pw.TextStyle(
      font: PdfFonts.bold,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 9.5,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(
      font: PdfFonts.regular,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 9.5,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Resumen muestral vs. teórico'),
        pw.Text(
          'E[X] teórico = ${result.theoreticalMean.toStringAsFixed(4)}   ·   '
          'Var(X) teórico = ${result.theoreticalVariance.toStringAsFixed(4)}',
          style: pw.TextStyle(
            font: PdfFonts.regular,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 10,
            color: kTextSecondary,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: kBorder, width: 0.6),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: kPrimary),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Variable', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Media muestral', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('σ muestral', style: headerStyle),
                ),
              ],
            ),
            for (final v in result.variables)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(v.name, style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      v.sampleMean.toStringAsFixed(4),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      v.sampleStdDev.toStringAsFixed(4),
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

  static pw.Widget _buildDataTable(SimulationResult result) {
    final headerStyle = pw.TextStyle(
      font: PdfFonts.bold,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 9,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(
      font: PdfFonts.regular,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 8.5,
    );
    final isDiscrete = result.distributionType == DistributionType.poisson;

    String fmt(double v) =>
        isDiscrete ? v.toInt().toString() : v.toStringAsFixed(4);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Base de datos generada'),
        pw.Table(
          border: pw.TableBorder.all(color: kBorder, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: kPrimary),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('N°', style: headerStyle),
                ),
                for (final v in result.variables)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(v.name, style: headerStyle),
                  ),
              ],
            ),
            for (int i = 0; i < result.numObservations; i++)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${i + 1}', style: cellStyle),
                  ),
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
