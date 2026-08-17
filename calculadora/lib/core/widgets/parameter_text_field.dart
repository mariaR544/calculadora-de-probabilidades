import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Campo de entrada de parámetro numérico con validación en tiempo
/// real. Si se provee [description], esta se muestra debajo del campo
/// únicamente mientras el usuario lo tiene seleccionado (enfocado),
/// explicando qué representa ese parámetro dentro de la fórmula.
class ParameterTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? description;
  final String? suffixText;
  final String? Function(String?) validator;
  final bool allowDecimal;
  final VoidCallback? onChanged;

  const ParameterTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.description,
    this.suffixText,
    this.allowDecimal = true,
    this.onChanged,
  });

  @override
  State<ParameterTextField> createState() => _ParameterTextFieldState();
}

class _ParameterTextFieldState extends State<ParameterTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _focused = _focusNode.hasFocus);
      });
    // Redibuja para mostrar u ocultar el ícono de borrado individual
    // según el campo tenga o no contenido.
    widget.controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _clearField() {
    widget.controller.clear();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType:
              TextInputType.numberWithOptions(decimal: widget.allowDecimal),
          inputFormatters: [
            if (widget.allowDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*$'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (_) => widget.onChanged?.call(),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: widget.suffixText,
            suffixIcon: widget.controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    color: AppColors.textSecondary,
                    splashRadius: 16,
                    tooltip: 'Borrar campo',
                    onPressed: _clearField,
                  ),
          ),
        ),
        if (widget.description != null)
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _focused
                ? Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.description!,
                            style: AppTextStyles.subtitle,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
      ],
    );
  }
}