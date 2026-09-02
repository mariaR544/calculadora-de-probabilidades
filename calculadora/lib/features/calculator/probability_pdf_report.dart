import 'dart:typed_data';
import 'package:flutter/widgets.dart' show CustomPainter;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/pdf_chart_image_builder.dart';
import '../../core/utils/pdf_formula_builder.dart';
import '../../core/widgets/explanation_bottom_sheet.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../exponential/exponential_chart_painter.dart';
import '../poisson/poisson_chart_painter.dart';

String _fmt(double v) {
  if (v.isNaN || v.isInfinite) return v.toString();
  final s = v.toStringAsFixed(4);
  return s.contains('.')
      ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
      : s;
}

String _fix(double v, [int d = 4]) => v.toStringAsFixed(d);

/// Genera y comparte/imprime reportes formales en PDF para las distribuciones
/// del Módulo 1 (Poisson y Exponencial), con letras griegas (λ, μ, σ),
/// subíndices, superíndices, tabla de valores y gráfico de densidad/probabilidad.
class ProbabilityPdfReport {
  ProbabilityPdfReport._();

  static Future<Uint8List> generate({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) async {
    await PdfFonts.load();

    final explanation = ExplanationTextGenerator.probabilityText(
      result: result,
      distributionType: distributionType,
      probabilityType: probabilityType,
      upperX: upperX,
    );

    final CustomPainter chartPainter =
        distributionType == DistributionType.poisson
            ? PoissonChartPainter(points: result.points)
            : ExponentialChartPainter(points: result.points);

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
        header: (context) => _buildHeader(distributionType),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildParametersSection(result, distributionType, probabilityType),
          pw.SizedBox(height: 16),
          _buildStatisticsSection(result),
          pw.SizedBox(height: 16),
          _buildInterpretationSection(explanation),
          pw.SizedBox(height: 16),
          _buildTheoreticalBreakdownSection(
            result,
            distributionType,
            probabilityType,
            upperX,
          ),
          pw.SizedBox(height: 20),
          _buildChartSection(result, chartImageBytes),
          pw.SizedBox(height: 20),
          _buildTableSection(result),
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
      filename:
          'reporte_${distributionType == DistributionType.poisson ? "poisson" : "exponencial"}.pdf',
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

  // ---------------------------------------------------------------------------
  // Secciones del documento
  // ---------------------------------------------------------------------------

  static pw.Widget _buildHeader(DistributionType type) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Quantis · Reporte de Probabilidad',
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: 16,
                color: kPrimary,
              ),
            ),
            pw.Text(
              type.label,
              style: pw.TextStyle(
                font: PdfFonts.bold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: 12,
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

  static pw.Widget _buildParametersSection(
    CalculationResult result,
    DistributionType distributionType,
    ProbabilityType probabilityType,
  ) {
    final probText = '${(result.probability * 100).toStringAsFixed(4)}%';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Parámetros y resultado evaluado'),
        pw.Text(
          '${distributionType.label} · ${distributionType.natureLabel}',
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
        pw.SizedBox(height: 8),
        buildPdfMetricRow(
          'Probabilidad Calculada: ${probabilityType.shortLabel}',
          probText,
        ),
      ],
    );
  }

  static pw.Widget _buildStatisticsSection(CalculationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Estadísticos descriptivos'),
        buildPdfMetricRow('Media (μ)', result.mean.toStringAsFixed(4)),
        buildPdfMetricRow('Varianza (σ²)', result.variance.toStringAsFixed(4)),
        buildPdfMetricRow(
          'Desviación estándar (σ)',
          result.stdDev.toStringAsFixed(4),
        ),
        buildPdfMetricRow(
          'Asimetría (Skewness)',
          result.skewness.toStringAsFixed(4),
        ),
        buildPdfMetricRow('Curtosis', result.kurtosis.toStringAsFixed(4)),
        buildPdfMetricRow(
          'Coeficiente de variación (CV)',
          '${(result.coefficientOfVariation * 100).toStringAsFixed(2)}%',
        ),
      ],
    );
  }

  static pw.Widget _buildInterpretationSection(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Interpretación del resultado'),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: kSurfaceAlt,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: kBorder),
          ),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: PdfFonts.regular,
              fontFallback: PdfFonts.fontFallback,
              fontSize: 10.5,
              lineSpacing: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTheoreticalBreakdownSection(
    CalculationResult result,
    DistributionType distributionType,
    ProbabilityType probabilityType,
    double? upperX,
  ) {
    if (distributionType == DistributionType.poisson) {
      return _buildPoissonBreakdown(result, probabilityType, upperX);
    } else {
      return _buildExponentialBreakdown(result, probabilityType, upperX);
    }
  }

  static pw.Widget _buildPoissonBreakdown(
    CalculationResult result,
    ProbabilityType probabilityType,
    double? upperX,
  ) {
    final double lambda = result.mean;
    final String lambdaStr = _fmt(lambda);
    final int x = result.evaluatedX.toInt();
    final int? x2 = upperX?.toInt();
    final String probStr = _fix(result.probability, 6);

    String probTitle;
    String probFormula;
    String probSubstitution;
    String probDescription;

    switch (probabilityType) {
      case ProbabilityType.puntual:
        probTitle = '1. Probabilidad Puntual P(X = x)';
        probFormula = 'P(X = x) = (e^{-λ} · λ^x) / x!';
        probSubstitution =
            'P(X = $x) = (e^{-$lambdaStr} · ($lambdaStr)^$x) / $x! = $probStr';
        probDescription =
            'Probabilidad exacta de observar exactamente $x eventos en el intervalo evaluado.';
        break;
      case ProbabilityType.menorOIgual:
        probTitle = '1. Probabilidad Acumulada Inferior P(X ≤ x)';
        probFormula = 'P(X ≤ x) = ∑_{k=0}^x (e^{-λ} · λ^k) / k!';
        probSubstitution =
            'P(X ≤ $x) = ∑_{k=0}^$x (e^{-$lambdaStr} · ($lambdaStr)^k) / k! = $probStr';
        probDescription =
            'Suma de probabilidades puntuales desde k = 0 hasta k = $x.';
        break;
      case ProbabilityType.menorQue:
        final int xm1 = x - 1;
        probTitle = '1. Probabilidad Acumulada Estricta P(X < x)';
        probFormula = 'P(X < x) = P(X ≤ x - 1) = ∑_{k=0}^{x-1} (e^{-λ} · λ^k) / k!';
        probSubstitution = 'P(X < $x) = P(X ≤ $xm1) = $probStr';
        probDescription =
            'Suma de probabilidades puntuales desde k = 0 hasta k = $xm1.';
        break;
      case ProbabilityType.mayorOIgual:
        final int xm1 = x - 1;
        final double compVal = (1.0 - result.probability).clamp(0.0, 1.0);
        probTitle = '1. Probabilidad Acumulada Superior P(X ≥ x)';
        probFormula = 'P(X ≥ x) = 1 - P(X ≤ x - 1)';
        probSubstitution =
            'P(X ≥ $x) = 1 - P(X ≤ $xm1) = 1 - ${_fix(compVal, 6)} = $probStr';
        probDescription =
            'Complemento de la probabilidad acumulada inferior hasta k = $xm1.';
        break;
      case ProbabilityType.mayorQue:
        final double compVal = (1.0 - result.probability).clamp(0.0, 1.0);
        probTitle = '1. Probabilidad Acumulada Superior Estricta P(X > x)';
        probFormula = 'P(X > x) = 1 - P(X ≤ x)';
        probSubstitution =
            'P(X > $x) = 1 - P(X ≤ $x) = 1 - ${_fix(compVal, 6)} = $probStr';
        probDescription =
            'Complemento de la probabilidad acumulada inferior hasta k = $x.';
        break;
      case ProbabilityType.cerradoRango:
        final int x2v = x2 ?? x;
        final int xm1 = x - 1;
        probTitle = '1. Probabilidad en Rango Cerrado P(x_i ≤ X ≤ x_j)';
        probFormula = 'P(x_i ≤ X ≤ x_j) = P(X ≤ x_j) - P(X ≤ x_i - 1)';
        probSubstitution =
            'P($x ≤ X ≤ $x2v) = P(X ≤ $x2v) - P(X ≤ $xm1) = $probStr';
        probDescription =
            'Diferencia entre las probabilidades acumuladas en los límites [$x, $x2v].';
        break;
      case ProbabilityType.estrictoRango:
        final int x2v = x2 ?? x;
        final int x2m1 = x2v - 1;
        probTitle = '1. Probabilidad en Rango Abierto P(x_i < X < x_j)';
        probFormula = 'P(x_i < X < x_j) = P(X ≤ x_j - 1) - P(X ≤ x_i)';
        probSubstitution =
            'P($x < X < $x2v) = P(X ≤ $x2m1) - P(X ≤ $x) = $probStr';
        probDescription =
            'Probabilidad de que el número de eventos esté estrictamente entre $x y $x2v.';
        break;
      case ProbabilityType.izqCerradoDerAbierto:
        final int x2v = x2 ?? x;
        final int x2m1 = x2v - 1;
        final int xm1 = x - 1;
        probTitle = '1. Probabilidad en Rango Semiabierto P(x_i ≤ X < x_j)';
        probFormula = 'P(x_i ≤ X < x_j) = P(X ≤ x_j - 1) - P(X ≤ x_i - 1)';
        probSubstitution =
            'P($x ≤ X < $x2v) = P(X ≤ $x2m1) - P(X ≤ $xm1) = $probStr';
        probDescription =
            'Probabilidad acumulada en el intervalo semiabierto [$x, $x2v).';
        break;
      case ProbabilityType.izqAbiertoDerCerrado:
        final int x2v = x2 ?? x;
        probTitle = '1. Probabilidad en Rango Semiabierto P(x_i < X ≤ x_j)';
        probFormula = 'P(x_i < X ≤ x_j) = P(X ≤ x_j) - P(X ≤ x_i)';
        probSubstitution =
            'P($x < X ≤ $x2v) = P(X ≤ $x2v) - P(X ≤ $x) = $probStr';
        probDescription =
            'Probabilidad acumulada en el intervalo semiabierto ($x, $x2v].';
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Desglose teórico y fórmulas paso a paso'),
        buildPdfStepItem(
          title: probTitle,
          formula: probFormula,
          substitution: probSubstitution,
          description: probDescription,
          valueText: probStr,
        ),
        buildPdfStepItem(
          title: '2. Esperanza Matemática E[X]',
          formula: 'E[X] = λ',
          substitution: 'E[X] = $lambdaStr = ${_fix(result.mean)}',
          description:
              'Valor promedio o media esperada de ocurrencias en el intervalo evaluado.',
          valueText: result.mean.toStringAsFixed(4),
        ),
        buildPdfStepItem(
          title: '3. Varianza Var(X)',
          formula: 'Var(X) = λ',
          substitution: 'Var(X) = $lambdaStr = ${_fix(result.variance)}',
          description:
              'En la distribución de Poisson, la varianza es idéntica a la media λ (equidispersión).',
          valueText: result.variance.toStringAsFixed(4),
        ),
        buildPdfStepItem(
          title: '4. Desviación Estándar (σ)',
          formula: 'σ = √(Var(X)) = √λ',
          substitution: 'σ = √($lambdaStr) = ${_fix(result.stdDev)}',
          description:
              'Medida de dispersión de los datos alrededor del valor medio esperado.',
          valueText: result.stdDev.toStringAsFixed(4),
        ),
      ],
    );
  }

  static pw.Widget _buildExponentialBreakdown(
    CalculationResult result,
    ProbabilityType probabilityType,
    double? upperX,
  ) {
    final double lambda = result.mean > 0 ? 1 / result.mean : 1.0;
    final String lambdaStr = _fmt(lambda);
    final double xi = result.evaluatedX;
    final String xiStr = _fmt(xi);
    final double? xj = upperX;
    final String? xjStr = xj != null ? _fmt(xj) : null;
    final String probStr = _fix(result.probability, 6);

    String probTitle;
    String probFormula;
    String probSubstitution;
    String probDescription;

    switch (probabilityType) {
      case ProbabilityType.mayorOIgual:
      case ProbabilityType.mayorQue:
        final double expV = lambda * xi;
        probTitle = '1. Probabilidad de Cola Superior P(X ≥ x)';
        probFormula = 'P(X ≥ x) = e^{-λ · x}';
        probSubstitution =
            'P(X ≥ $xiStr) = e^{-($lambdaStr) · ($xiStr)} = e^{-${_fmt(expV)}} = $probStr';
        probDescription =
            'Probabilidad de que el tiempo o distancia transcurrido sea al menos $xiStr.';
        break;
      case ProbabilityType.menorOIgual:
      case ProbabilityType.menorQue:
        final double expV = lambda * xi;
        probTitle = '1. Probabilidad Acumulada Inferior P(X ≤ x)';
        probFormula = 'P(X ≤ x) = 1 - e^{-λ · x}';
        probSubstitution =
            'P(X ≤ $xiStr) = 1 - e^{-($lambdaStr) · ($xiStr)} = 1 - e^{-${_fmt(expV)}} = $probStr';
        probDescription =
            'Probabilidad acumulada de que el evento ocurra en un tiempo o distancia ≤ $xiStr.';
        break;
      default:
        final String x2s = xjStr ?? xiStr;
        final double x2d = xj ?? xi;
        final double exp1 = lambda * xi;
        final double exp2 = lambda * x2d;
        probTitle = '1. Probabilidad en Rango P(x_i ≤ X ≤ x_j)';
        probFormula = 'P(x_i ≤ X ≤ x_j) = e^{-λ · x_i} - e^{-λ · x_j}';
        probSubstitution =
            'P($xiStr ≤ X ≤ $x2s) = e^{-${_fmt(exp1)}} - e^{-${_fmt(exp2)}} = $probStr';
        probDescription =
            'Probabilidad de que el tiempo transcurrido se encuentre en el intervalo [$xiStr, $x2s].';
        break;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Desglose teórico y fórmulas paso a paso'),
        buildPdfStepItem(
          title: probTitle,
          formula: probFormula,
          substitution: probSubstitution,
          description: probDescription,
          valueText: probStr,
        ),
        buildPdfStepItem(
          title: '2. Esperanza Matemática E[X]',
          formula: 'E[X] = 1 / λ',
          substitution: 'E[X] = 1 / $lambdaStr = ${_fix(result.mean)}',
          description:
              'Tiempo medio esperado entre llegadas u ocurrencias sucesivas del proceso.',
          valueText: result.mean.toStringAsFixed(4),
        ),
        buildPdfStepItem(
          title: '3. Varianza Var(X)',
          formula: 'Var(X) = 1 / λ^2',
          substitution:
              'Var(X) = 1 / ($lambdaStr)^2 = ${_fix(result.variance)}',
          description:
              'Dispersión cuadrática del tiempo entre eventos en la distribución exponencial continua.',
          valueText: result.variance.toStringAsFixed(4),
        ),
        buildPdfStepItem(
          title: '4. Desviación Estándar (σ)',
          formula: 'σ = 1 / λ',
          substitution: 'σ = 1 / $lambdaStr = ${_fix(result.stdDev)}',
          description:
              'En la distribución exponencial, la desviación estándar es idéntica a la esperanza matemática.',
          valueText: result.stdDev.toStringAsFixed(4),
        ),
      ],
    );
  }

  static pw.Widget _buildChartSection(
    CalculationResult result,
    Uint8List chartImageBytes,
  ) {
    final isDiscrete = result.isDiscrete;
    final generalColor = isDiscrete
        ? const PdfColor.fromInt(0xFFD8E4FA) // AppColors.barBase
        : const PdfColor.fromInt(0xFF1E4FBB); // AppColors.primaryDark
    final highlightColor = isDiscrete
        ? const PdfColor.fromInt(0xFF4C86F0) // AppColors.highlightStrong
        : const PdfColor.fromInt(0xFF9CC2FA); // AppColors.highlight

    final generalLabel =
        isDiscrete ? 'Barras de probabilidad' : 'Curva de densidad';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle(
          isDiscrete
              ? 'Gráfica de Probabilidad (PMF)'
              : 'Gráfica de Densidad (PDF)',
        ),
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
            _buildLegendItem(color: generalColor, label: generalLabel),
            pw.SizedBox(width: 18),
            _buildLegendItem(color: highlightColor, label: 'Región evaluada'),
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

  static pw.Widget _buildTableSection(CalculationResult result) {
    final headerStyle = pw.TextStyle(
      font: PdfFonts.bold,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 10,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(
      font: PdfFonts.regular,
      fontFallback: PdfFonts.fontFallback,
      fontSize: 9,
    );

    final displayPoints = result.points.length > 20
        ? result.points.take(20).toList()
        : result.points;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        buildPdfSectionTitle('Tabla de valores evaluados'),
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
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('x', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    result.isDiscrete ? 'P(X = x)' : 'f(x)',
                    style: headerStyle,
                  ),
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
                    ? const pw.BoxDecoration(color: kSurfaceAlt)
                    : null,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      p.x == p.x.roundToDouble()
                          ? p.x.toInt().toString()
                          : p.x.toStringAsFixed(2),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      p.y.toStringAsFixed(4),
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      p.highlighted ? 'Sí' : 'No',
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
