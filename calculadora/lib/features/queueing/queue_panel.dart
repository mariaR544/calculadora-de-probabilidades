import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/parameter_text_field.dart';
import '../../core/widgets/section_title.dart';
import '../../models/queue_model_type.dart';
import '../../models/queue_result.dart';
import 'queue_calculator.dart';
import 'queue_distribution_table.dart';
import 'queue_graph_container.dart';
import 'queue_pdf_report.dart';
import 'queue_results_panel.dart';

/// Panel del módulo de colas: formulario de parámetros (λ, μ y, si
/// aplica, N), botón "Calcular" y, tras calcular, métricas, tabla de
/// probabilidades, gráfica deslizable y exportación a PDF.
class QueuePanel extends StatefulWidget {
  final QueueModelType type;

  const QueuePanel({super.key, required this.type});

  @override
  State<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<QueuePanel> {
  final _formKey = GlobalKey<FormState>();
  final _lambdaController = TextEditingController(text: '4');
  final _muController = TextEditingController(text: '6');
  final _capacityController = TextEditingController(text: '5');

  QueueResult? _result;
  String? _errorMessage;
  bool _isExporting = false;

  @override
  void dispose() {
    _lambdaController.dispose();
    _muController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = QueueCalculator.calculate(
        lambda: double.parse(_lambdaController.text.replaceAll(',', '.')),
        mu: double.parse(_muController.text.replaceAll(',', '.')),
        type: widget.type,
        capacity: widget.type.isFinite
            ? int.parse(_capacityController.text)
            : null,
      );
      setState(() => _result = result);
    } on QueueValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _result = null;
      });
    }
  }

  Future<void> _exportPdf(Future<void> Function(QueueResult) action) async {
    if (_result == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await action(_result!);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'No se pudo generar el PDF. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      text: 'Parámetros de entrada',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _lambdaController,
                      label: 'λ (TASA DE LLEGADA)',
                      description:
                          'Número promedio de clientes que llegan al '
                          'sistema por unidad de tiempo. Debe ser mayor '
                          'que 0.',
                      validator: (v) {
                        final parsed =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (parsed == null) return 'Ingresa un número válido';
                        if (parsed <= 0) return 'λ debe ser mayor que 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _muController,
                      label: 'μ (TASA DE SERVICIO)',
                      description:
                          'Número promedio de clientes que el servidor '
                          'puede atender por unidad de tiempo. Debe ser '
                          'mayor que 0.',
                      validator: (v) {
                        final parsed =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (parsed == null) return 'Ingresa un número válido';
                        if (parsed <= 0) return 'μ debe ser mayor que 0';
                        return null;
                      },
                    ),
                    if (widget.type.isFinite) ...[
                      const SizedBox(height: 14),
                      ParameterTextField(
                        controller: _capacityController,
                        label: 'N (CAPACIDAD MÁXIMA DEL SISTEMA)',
                        description:
                            'Número máximo de clientes que el sistema '
                            'puede contener (incluyendo al que está '
                            'siendo atendido). Entero ≥ 1.',
                        allowDecimal: false,
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          if (parsed == null) return 'Ingresa un entero';
                          if (parsed < 1) return 'N debe ser ≥ 1';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_rounded, size: 18),
                        label: const Text('Calcular'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              QueueResultsPanel(result: _result!),
              const SizedBox(height: 16),
              QueueGraphContainer(result: _result!),
              const SizedBox(height: 16),
              QueueDistributionTable(result: _result!),
              const SizedBox(height: 16),
              _buildExportButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _exportPdf(QueuePdfReport.print),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Imprimir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _exportPdf(QueuePdfReport.share),
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textOnPrimary),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(_isExporting ? 'Generando...' : 'Exportar PDF'),
          ),
        ),
      ],
    );
  }
}
