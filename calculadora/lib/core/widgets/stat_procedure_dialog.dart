import 'package:flutter/material.dart';
import '../../models/stat_procedure.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'formula_text.dart';

/// Dialog modal que muestra el procedimiento paso a paso utilizado para
/// calcular un estadístico descriptivo.
///
/// Formato:
///   1. Fórmula simbólica (letras griegas, sub/superíndices correctos).
///   2. Sustitución de valores reales en esa fórmula.
///   3. Resultado final destacado.
///   4. Descripción conceptual breve.
///   5. Botón "¡Entendido!" azul/blanco que cierra el modal.
///
/// Se invoca con [StatProcedureDialog.show].
class StatProcedureDialog extends StatelessWidget {
  final StatProcedure procedure;

  const StatProcedureDialog({super.key, required this.procedure});

  // ── Punto de entrada ─────────────────────────────────────────────────────

  /// Muestra el dialog con animación de escala suave.
  static Future<void> show(
    BuildContext context, {
    required StatProcedure procedure,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar procedimiento',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => StatProcedureDialog(procedure: procedure),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(procedure: procedure),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              _StepSection(
                stepNumber: '1',
                stepColor: AppColors.primary,
                stepLabel: 'FÓRMULA',
                child: _FormulaBox(
                  text: procedure.formula,
                  bgColor: AppColors.primary.withValues(alpha: 0.06),
                  borderColor: AppColors.primary.withValues(alpha: 0.22),
                  textStyle: AppTextStyles.formula.copyWith(
                    fontSize: 16,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _StepSection(
                stepNumber: '2',
                stepColor: const Color(0xFF00897B),
                stepLabel: 'SUSTITUCIÓN',
                child: _FormulaBox(
                  text: procedure.substitution,
                  bgColor: AppColors.surfaceAlt,
                  borderColor: AppColors.border,
                  textStyle: AppTextStyles.formula.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ResultBanner(procedure: procedure),
              const SizedBox(height: 12),
              FormulaText(
                procedure.description,
                baseStyle: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 20),
              _UnderstoodButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final StatProcedure procedure;
  const _Header({required this.procedure});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.functions_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROCEDIMIENTO',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 2),
              FormulaText(
                procedure.statLabel,
                baseStyle: AppTextStyles.title.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
        // Botón X sutil para cerrar
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 18),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(32, 32),
          ),
          tooltip: 'Cerrar',
        ),
      ],
    );
  }
}

class _StepSection extends StatelessWidget {
  final String stepNumber;
  final Color stepColor;
  final String stepLabel;
  final Widget child;

  const _StepSection({
    required this.stepNumber,
    required this.stepColor,
    required this.stepLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: stepColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              stepLabel,
              style: AppTextStyles.label.copyWith(
                color: stepColor,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

/// Caja que contiene la fórmula o la sustitución, con borde y fondo.
class _FormulaBox extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color borderColor;
  final TextStyle textStyle;

  const _FormulaBox({
    required this.text,
    required this.bgColor,
    required this.borderColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: FormulaText(text, baseStyle: textStyle),
    );
  }
}

/// Banner azul con el resultado final.
class _ResultBanner extends StatelessWidget {
  final StatProcedure procedure;
  const _ResultBanner({required this.procedure});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta "RESULTADO" + nombre del estadístico
          Text(
            'RESULTADO',
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          FormulaText(
            procedure.statLabel,
            baseStyle: AppTextStyles.subtitle.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          // Valor del resultado — ocupa todo el ancho disponible
          Text(
            procedure.resultText,
            style: AppTextStyles.momentValue.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

/// Botón "¡Entendido!" — azul sólido, texto blanco.
class _UnderstoodButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _UnderstoodButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          '¡Entendido!',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
