import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/widgets/explanation_bottom_sheet.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';

/// Genera y comparte/imprime reportes formales en PDF para las distribuciones
/// del Módulo 1 (Poisson y Exponencial), incluyendo parámetros, estadísticos,
/// interpretación educativa, gráfico y tabla de probabilidades.
class ProbabilityPdfReport {
  ProbabilityPdfReport._();

  static const PdfColor _primary = PdfColor.fromInt(0xFF2F6FED);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF62728A);
  static const PdfColor _border = PdfColor.fromInt(0xFFDCE6F5);
  static const PdfColor _surfaceAlt = PdfColor.fromInt(0xFFEAF1FC);
  static const PdfColor _highlight = PdfColor.fromInt(0xFF9CC2FA);

  /// Genera los bytes del PDF.
  static Future<Uint8List> generate({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final explanation = ExplanationTextGenerator.probabilityText(
      result: result,
      distributionType: distributionType,
      probabilityType: probabilityType,
      upperX: upperX,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => _buildHeader(distributionType, fontBold),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result, distributionType, probabilityType, upperX, fontBold),
          pw.SizedBox(height: 16),
          _buildStatisticsSection(result, fontBold),
          pw.SizedBox(height: 16),
          _buildInterpretationSection(explanation, fontBold),
          pw.SizedBox(height: 20),
          _buildChartSection(result, fontBold),
          pw.SizedBox(height: 20),
          _buildTableSection(result, fontBold),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> share({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) async {
    final bytes = await generate(
      result: result,
      distributionType: distributionType,
      probabilityType: probabilityType,
      upperX: upperX,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'reporte_${distributionType == DistributionType.poisson ? "poisson" : "exponencial"}.pdf',
    );
  }

  static Future<void> print({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) async {
    final bytes = await generate(
      result: result,
      distributionType: distributionType,
      probabilityType: probabilityType,
      upperX: upperX,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ---------------------------------------------------------------------
  // Componentes y Secciones
  // ---------------------------------------------------------------------

  static pw.Widget _buildHeader(DistributionType type, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Quantis · Reporte de Probabilidad',
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: _primary)),
            pw.Text(type.label,
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: _textSecondary)),
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

  static pw.Widget _buildParametersSection(
    CalculationResult result,
    DistributionType distributionType,
    ProbabilityType probabilityType,
    double? upperX,
    pw.Font fontBold,
  ) {
    final probText = '${(result.probability * 100).toStringAsFixed(4)}%';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Parámetros y resultado evaluado', fontBold),
        pw.Text('${distributionType.label} · ${distributionType.natureLabel}',
            style: pw.TextStyle(font: fontBold, fontSize: 13)),
        pw.SizedBox(height: 6),
        pw.Text(result.parameterSummary, style: const pw.TextStyle(fontSize: 10.5)),
        pw.SizedBox(height: 8),
        _metricRow('Probabilidad Calculada: ${probabilityType.shortLabel}', probText, fontBold),
      ],
    );
  }

  static pw.Widget _buildStatisticsSection(CalculationResult result, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Estadísticos descriptivos', fontBold),
        _metricRow('Media (μ)', result.mean.toStringAsFixed(4), fontBold),
        _metricRow('Varianza (σ²)', result.variance.toStringAsFixed(4), fontBold),
        _metricRow('Desviación estándar (σ)', result.stdDev.toStringAsFixed(4), fontBold),
        _metricRow('Asimetría (Skewness)', result.skewness.toStringAsFixed(4), fontBold),
        _metricRow('Curtosis', result.kurtosis.toStringAsFixed(4), fontBold),
        _metricRow('Coeficiente de variación (CV)',
            '${(result.coefficientOfVariation * 100).toStringAsFixed(2)}%', fontBold),
      ],
    );
  }

  static pw.Widget _buildInterpretationSection(String text, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Interpretación del resultado', fontBold),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _surfaceAlt,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 1.3)),
        ),
      ],
    );
  }

  static pw.Widget _buildChartSection(CalculationResult result, pw.Font fontBold) {
    final maxY = result.points.map((p) => p.y).fold<double>(0, (a, b) => a > b ? a : b);
    final barMax = maxY <= 0 ? 1.0 : maxY * 1.15;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          result.isDiscrete ? 'Gráfica de Probabilidad (PMF)' : 'Gráfica de Densidad (PDF)',
          fontBold,
        ),
        pw.Container(
          height: 150,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final point in result.points)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Container(
                          height: 110 * (point.y / barMax),
                          decoration: pw.BoxDecoration(
                            color: point.highlighted ? _primary : _highlight,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          point.x == point.x.roundToDouble()
                              ? point.x.toInt().toString()
                              : point.x.toStringAsFixed(1),
                          style: const pw.TextStyle(fontSize: 5.5, color: _textSecondary),
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

  static pw.Widget _buildTableSection(CalculationResult result, pw.Font fontBold) {
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white);
    final cellStyle = const pw.TextStyle(fontSize: 9);

    final displayPoints = result.points.length > 20
        ? result.points.take(20).toList()
        : result.points;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tabla de valores evaluados', fontBold),
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
                  child: pw.Text('x', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(result.isDiscrete ? 'P(X = x)' : 'f(x)', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Evaluado', style: headerStyle),
                ),
              ],
            ),
            for (final p in displayPoints)
              pw.TableRow(
                decoration: p.highlighted
                    ? const pw.BoxDecoration(color: _surfaceAlt)
                    : null,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      p.x == p.x.roundToDouble() ? p.x.toInt().toString() : p.x.toStringAsFixed(2),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(p.y.toStringAsFixed(4), style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(p.highlighted ? 'Sí' : 'No', style: cellStyle),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
