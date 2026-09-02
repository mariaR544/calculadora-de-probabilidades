import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:calculadora/core/utils/pdf_formula_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfFonts loads fonts successfully and renders Greek & math symbols', () async {
    await PdfFonts.load();
    expect(PdfFonts.regular, isNotNull);
    expect(PdfFonts.bold, isNotNull);
    expect(PdfFonts.math, isNotNull);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: PdfFonts.regular,
          bold: PdfFonts.bold,
          fontFallback: [PdfFonts.math, PdfFonts.regular, PdfFonts.bold],
        ),
        build: (context) {
          return pw.Column(
            children: [
              pw.Text('Prueba de caracteres griegos: λ, μ, ρ, σ, P₀, Lₛ, Lᵩ, Wₛ, Wᵩ, λ_eff, ∑, ≤, ≥, √, ∞'),
              pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(font: PdfFonts.regular, fontSize: 12),
                  children: [
                    pw.TextSpan(text: 'L'),
                    pw.WidgetSpan(
                      child: pw.Transform.translate(
                        offset: const PdfPoint(0, -3),
                        child: pw.Text('q', style: pw.TextStyle(font: PdfFonts.regular, fontSize: 8)),
                      ),
                    ),
                    pw.TextSpan(text: ' = '),
                    pw.TextSpan(text: 'e'),
                    pw.WidgetSpan(
                      child: pw.Transform.translate(
                        offset: const PdfPoint(0, 4),
                        child: pw.Text('-λ', style: pw.TextStyle(font: PdfFonts.regular, fontSize: 8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    expect(bytes.isNotEmpty, isTrue);
  });
}
