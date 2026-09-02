import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Gestión centralizada de fuentes TrueType empaquetadas como assets para los reportes PDF.
/// Garantiza la cobertura total de caracteres griegos (λ, μ, ρ, σ), operadores matemáticos
/// (∑, ≤, ≥, √, ∞, ·, −) y notación científica tanto en línea como sin conexión a internet.
class PdfFonts {
  PdfFonts._();

  static pw.Font? _regular;
  static pw.Font? _bold;
  static pw.Font? _math;

  /// Carga todas las fuentes desde assets. Debe invocarse antes de renderizar páginas PDF.
  static Future<void> load() async {
    if (_regular != null && _bold != null && _math != null) return;
    final regularData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final mathData =
        await rootBundle.load('assets/fonts/NotoSansMath-Regular.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
    _math = pw.Font.ttf(mathData);
  }

  static pw.Font get regular {
    assert(
      _regular != null,
      'Llama a PdfFonts.load() antes de acceder a PdfFonts.regular',
    );
    return _regular!;
  }

  static pw.Font get bold {
    assert(
      _bold != null,
      'Llama a PdfFonts.load() antes de acceder a PdfFonts.bold',
    );
    return _bold!;
  }

  static pw.Font get math {
    assert(
      _math != null,
      'Llama a PdfFonts.load() antes de acceder a PdfFonts.math',
    );
    return _math!;
  }

  /// Lista de fuentes de respaldo ordenadas para asegurar que todo símbolo
  /// Unicode (incluyendo caracteres griegos y operadores matemáticos) se dibuje.
  static List<pw.Font> get fontFallback {
    return [
      if (_math != null) _math!,
      if (_regular != null) _regular!,
      if (_bold != null) _bold!,
    ];
  }
}

// ---------------------------------------------------------------------------
// Paleta de Colores de Quantis
// ---------------------------------------------------------------------------
const PdfColor kPrimary = PdfColor.fromInt(0xFF2F6FED);
const PdfColor kTextSecondary = PdfColor.fromInt(0xFF62728A);
const PdfColor kBorder = PdfColor.fromInt(0xFFDCE6F5);
const PdfColor kSurfaceAlt = PdfColor.fromInt(0xFFEAF1FC);
const PdfColor kTeal = PdfColor.fromInt(0xFF00796B);
const PdfColor kHighlight = PdfColor.fromInt(0xFF9CC2FA);

// ---------------------------------------------------------------------------
// Formateo y Parser de Fórmulas Matemáticas para PDF
// ---------------------------------------------------------------------------

/// Normaliza caracteres especiales y variantes de subíndices/superíndices
/// a la sintaxis canónica `_` y `^`.
String _normalizeFormula(String text) {
  return text
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
}

/// Caracteres delimitadores para cortes seguros de tokens en subíndices/superíndices sin llaves.
final RegExp _tokenBreak = RegExp(r'[\s_\^=\*,;:\(\)\[\]\+·/]');

/// Parsea una fórmula y produce una lista de [pw.InlineSpan] con [pw.WidgetSpan]
/// y desplazamiento vectorial exacto para subíndices y superíndices.
List<pw.InlineSpan> parsePdfFormulaSpans(
  String text,
  pw.TextStyle baseStyle,
) {
  final normalized = _normalizeFormula(text);
  final List<pw.InlineSpan> spans = [];
  final double fontSize = baseStyle.fontSize ?? 9.0;
  final double subSupSize = (fontSize * 0.72).clamp(6.0, 14.0);

  final subSupStyle = baseStyle.copyWith(
    fontSize: subSupSize,
    fontFallback: PdfFonts.fontFallback,
  );

  int i = 0;
  while (i < normalized.length) {
    if (normalized[i] == '_') {
      i++; // saltar '_'
      String sub = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        final closeChar = normalized[i] == '{' ? '}' : ')';
        i++;
        while (i < normalized.length && normalized[i] != closeChar) {
          sub += normalized[i++];
        }
        if (i < normalized.length) i++; // saltar cierre
      } else {
        while (i < normalized.length && !_tokenBreak.hasMatch(normalized[i])) {
          sub += normalized[i++];
        }
      }
      if (sub.isNotEmpty) {
        spans.add(
          pw.WidgetSpan(
            child: pw.Transform.translate(
              // En PDF el eje Y positivo va hacia arriba; para subíndice desplazamos hacia abajo (negativo)
              offset: PdfPoint(0, -fontSize * 0.22),
              child: pw.Text(sub, style: subSupStyle),
            ),
          ),
        );
      }
    } else if (normalized[i] == '^') {
      i++; // saltar '^'
      String sup = '';
      if (i < normalized.length &&
          (normalized[i] == '{' || normalized[i] == '(')) {
        final closeChar = normalized[i] == '{' ? '}' : ')';
        i++;
        while (i < normalized.length && normalized[i] != closeChar) {
          sup += normalized[i++];
        }
        if (i < normalized.length) i++; // saltar cierre
      } else {
        while (i < normalized.length && !_tokenBreak.hasMatch(normalized[i])) {
          sup += normalized[i++];
        }
      }
      if (sup.isNotEmpty) {
        spans.add(
          pw.WidgetSpan(
            child: pw.Transform.translate(
              // Desplazamiento hacia arriba para superíndices / exponentes
              offset: PdfPoint(0, fontSize * 0.38),
              child: pw.Text(sup, style: subSupStyle),
            ),
          ),
        );
      }
    } else {
      String normal = '';
      while (i < normalized.length &&
          normalized[i] != '_' &&
          normalized[i] != '^') {
        normal += normalized[i++];
      }
      if (normal.isNotEmpty) {
        spans.add(
          pw.TextSpan(
            text: normal,
            style: baseStyle.copyWith(fontFallback: PdfFonts.fontFallback),
          ),
        );
      }
    }
  }

  return spans;
}

/// Genera un widget [pw.RichText] que renderiza fórmulas matemáticas con
/// subíndices, superíndices, letras griegas y operadores con alineación perfecta.
pw.Widget buildPdfFormula(
  String formula, {
  pw.Font? font,
  double fontSize = 9.0,
  PdfColor color = PdfColors.black,
  bool bold = false,
}) {
  final f = font ?? (bold ? PdfFonts.bold : PdfFonts.regular);
  final baseStyle = pw.TextStyle(
    font: f,
    fontFallback: PdfFonts.fontFallback,
    fontSize: fontSize,
    color: color,
  );

  return pw.RichText(
    text: pw.TextSpan(
      style: baseStyle,
      children: parsePdfFormulaSpans(formula, baseStyle),
    ),
  );
}

/// Construye una línea con prefijo coloreado y fórmula formateada.
pw.Widget buildPdfFormulaLine({
  required String prefix,
  required String formula,
  required PdfColor prefixColor,
  pw.Font? font,
  double fontSize = 9.0,
}) {
  final f = font ?? PdfFonts.regular;
  final baseStyle = pw.TextStyle(
    font: f,
    fontFallback: PdfFonts.fontFallback,
    fontSize: fontSize,
    color: PdfColors.black,
  );

  return pw.RichText(
    text: pw.TextSpan(
      children: [
        if (prefix.isNotEmpty)
          pw.TextSpan(
            text: prefix,
            style: baseStyle.copyWith(
              font: PdfFonts.bold,
              color: prefixColor,
            ),
          ),
        ...parsePdfFormulaSpans(formula, baseStyle),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Bloque de Paso Pedagógico Compartido para los PDFs
// ---------------------------------------------------------------------------

/// Bloque estandarizado para cada paso del desglose teórico en el PDF:
/// Incluye título formateado con subíndices/griegos, resultado final,
/// recuadro blanco de fórmula teórica, recuadro blanco de sustitución numérica
/// y texto explicativo del concepto.
pw.Widget buildPdfStepItem({
  required String title,
  required String formula,
  required String substitution,
  required String description,
  required String valueText,
}) {
  final font = PdfFonts.regular;
  final fontBold = PdfFonts.bold;
  const double fs = 9.0;

  final formulaStyle = pw.TextStyle(
    font: font,
    fontFallback: PdfFonts.fontFallback,
    fontSize: fs,
    color: PdfColors.black,
  );

  final titleStyle = pw.TextStyle(
    font: fontBold,
    fontFallback: PdfFonts.fontFallback,
    fontSize: fs + 0.5,
    color: kPrimary,
  );

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: kSurfaceAlt,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: kBorder, width: 0.8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Encabezado: Título con fórmulas + Resultado numérico
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  style: titleStyle,
                  children: parsePdfFormulaSpans(title, titleStyle),
                ),
              ),
            ),
            pw.Text(
              'Res: $valueText',
              style: pw.TextStyle(
                font: fontBold,
                fontFallback: PdfFonts.fontFallback,
                fontSize: fs + 0.5,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Bloque 1: Fórmula teórica general
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: kBorder, width: 0.5),
          ),
          child: pw.RichText(
            text: pw.TextSpan(
              style: formulaStyle,
              children: [
                pw.TextSpan(
                  text: 'Fórmula:  ',
                  style: formulaStyle.copyWith(
                    font: fontBold,
                    color: kPrimary,
                  ),
                ),
                ...parsePdfFormulaSpans(formula, formulaStyle),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 3),

        // Bloque 2: Sustitución numérica
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: kBorder, width: 0.5),
          ),
          child: pw.RichText(
            text: pw.TextSpan(
              style: formulaStyle,
              children: [
                pw.TextSpan(
                  text: 'Sustitución:  ',
                  style: formulaStyle.copyWith(
                    font: fontBold,
                    color: kTeal,
                  ),
                ),
                ...parsePdfFormulaSpans(substitution, formulaStyle),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 4),

        // Descripción conceptual
        pw.Text(
          description,
          style: pw.TextStyle(
            font: font,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 7.8,
            color: kTextSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Helper para filas de métricas con fórmulas e iconos
pw.Widget buildPdfMetricRow(String label, String value) {
  final font = PdfFonts.regular;
  final fontBold = PdfFonts.bold;
  final labelStyle = pw.TextStyle(
    font: font,
    fontFallback: PdfFonts.fontFallback,
    fontSize: 10.0,
    color: kTextSecondary,
  );

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 9),
    margin: const pw.EdgeInsets.only(bottom: 5),
    decoration: pw.BoxDecoration(
      color: kSurfaceAlt,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.RichText(
            text: pw.TextSpan(
              style: labelStyle,
              children: parsePdfFormulaSpans(label, labelStyle),
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontFallback: PdfFonts.fontFallback,
            fontSize: 10.5,
          ),
        ),
      ],
    ),
  );
}

/// Título de sección formal en mayúsculas
pw.Widget buildPdfSectionTitle(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 7),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        font: PdfFonts.bold,
        fontFallback: PdfFonts.fontFallback,
        fontSize: 11,
        color: kPrimary,
        letterSpacing: 0.5,
      ),
    ),
  );
}
