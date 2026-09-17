import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// Widget que renderiza fórmulas matemáticas con soporte completo de:
///
///   - **Subíndices**   `_{contenido}` o `_c`
///   - **Superíndices** `^{contenido}` o `^c`
///   - **Sub + sup simultáneos** sobre el mismo token: `∑_{n=0}^{N}`
///   - **Recursividad** dentro de grupos: `_{n=0}^{c-1}` con expresiones
///   - **Letras griegas y símbolos** en Unicode directo: λ μ ρ σ γ κ √ ∑ ∞ ≤ ≥
///
/// ### DSL de fórmulas
/// ```
/// "ρ = λ / (c · μ)"          → texto plano con griegas Unicode
/// "γ_{1} = 1 / √λ"           → subíndice numérico
/// "λ^{2}"                    → superíndice
/// "∑_{n=0}^{c-1} r^{n}/n!"   → subíndice + superíndice simultáneos
/// "P_{0} = (1−ρ)/(1−ρ^{N+1})"→ expresiones complejas en grupos
/// ```
class FormulaText extends StatelessWidget {
  final String formula;

  /// Estilo base; si es null se usa [AppTextStyles.formula].
  final TextStyle? baseStyle;

  final TextAlign textAlign;

  const FormulaText(
    this.formula, {
    super.key,
    this.baseStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? AppTextStyles.formula;
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: style,
        children: _FormulaParser(formula, style).parse(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Parser interno
// ═══════════════════════════════════════════════════════════════════════════════

class _FormulaParser {
  final String src;
  final TextStyle base;
  int _pos = 0;

  _FormulaParser(this.src, this.base);

  // ── Tamaños de fuente ──────────────────────────────────────────────────────
  double get _baseFs => base.fontSize ?? 15.0;
  // Desplazamientos verticales en puntos lógicos

  // ── Punto de entrada ───────────────────────────────────────────────────────

  List<InlineSpan> parse() => _parseSegment(base, isNested: false);

  // ── Parser de segmento ─────────────────────────────────────────────────────

  List<InlineSpan> _parseSegment(TextStyle style, {bool isNested = false}) {
    final spans = <InlineSpan>[];
    final buf = StringBuffer();

    void flushBuf() {
      if (buf.isNotEmpty) {
        spans.add(TextSpan(text: buf.toString(), style: style));
        buf.clear();
      }
    }

    while (_pos < src.length) {
      final ch = src[_pos];

      // Salir al final de un grupo anidado
      if (isNested && ch == '}') break;

      if (ch == '_' || ch == '^') {
        flushBuf();
        // Recolectar todos los sub/sup consecutivos sobre el mismo "átomo"
        final mods = <({bool isSub, String content})>[];

        while (_pos < src.length && (src[_pos] == '_' || src[_pos] == '^')) {
          final isSub = src[_pos] == '_';
          _pos++; // consumir _ o ^
          final content = _readGroup();
          mods.add((isSub: isSub, content: content));
        }

        // Renderizar los modificadores
        for (final mod in mods) {
          spans.add(
            _buildScriptSpan(
              content: mod.content,
              isSub: mod.isSub,
              parentStyle: style,
            ),
          );
        }
      } else {
        buf.write(ch);
        _pos++;
      }
    }

    flushBuf();
    return spans;
  }

  // ── Leer grupo {…} o carácter único ──────────────────────────────────────

  String _readGroup() {
    if (_pos >= src.length) return '';

    if (src[_pos] == '{') {
      _pos++; // consumir '{'
      final start = _pos;
      int depth = 1;
      while (_pos < src.length && depth > 0) {
        if (src[_pos] == '{') depth++;
        if (src[_pos] == '}') depth--;
        if (depth > 0) {
          _pos++;
        } else {
          _pos++; // consumir '}'
        }
      }
      return src.substring(start, _pos - 1);
    }

    // Carácter único (incluyendo Unicode de múltiples unidades de código)
    final runes = src.runes.toList();
    // Buscar la runa en la posición _pos (índice de unidad de código)
    int runeIndex = 0;
    int codeUnitPos = 0;
    for (final r in runes) {
      if (codeUnitPos >= _pos) break;
      final str = String.fromCharCode(r);
      codeUnitPos += str.length;
      runeIndex++;
    }
    if (runeIndex < runes.length) {
      final ch = String.fromCharCode(runes[runeIndex]);
      _pos += ch.length;
      return ch;
    }
    return '';
  }

  // ── Construir span de sub/superíndice ─────────────────────────────────────

  InlineSpan _buildScriptSpan({
    required String content,
    required bool isSub,
    required TextStyle parentStyle,
  }) {
    final parentFs = parentStyle.fontSize ?? _baseFs;
    final scriptFs = (parentFs * 0.66).clamp(7.0, 12.0);
    final scriptStyle = parentStyle.copyWith(fontSize: scriptFs);

    final dy = isSub ? parentFs * 0.26 : -parentFs * 0.38;

    // Parsear el contenido del script recursivamente (puede tener sub/sup anidados)
    final innerSrc = content;
    final innerSpans = _FormulaParser(innerSrc, scriptStyle).parse();
    // _pos no cambia porque usamos un parser independiente para el contenido

    return WidgetSpan(
      alignment: isSub ? PlaceholderAlignment.bottom : PlaceholderAlignment.top,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: RichText(
          text: TextSpan(style: scriptStyle, children: innerSpans),
        ),
      ),
    );
  }
}
