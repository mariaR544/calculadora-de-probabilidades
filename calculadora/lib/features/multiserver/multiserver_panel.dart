import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/parameter_text_field.dart';
import '../../core/widgets/section_title.dart';
import '../../models/multiserver_queue_model_type.dart';
import '../../models/multiserver_queue_result.dart';
import 'multiserver_calculator.dart';
import 'multiserver_distribution_table.dart';
import 'multiserver_explanation_bottom_sheet.dart';
import 'multiserver_graph_container.dart';
import 'multiserver_pdf_report.dart';
import 'multiserver_results_panel.dart';

/// Panel del módulo multicanal (M/M/c): formulario de parámetros (λ, μ, c y,
/// si aplica, N), botón "Calcular" y presentación de resultados operativos,
/// métricas de servidores, gráficos, tablas de estado y exportación a PDF.
class MultiserverPanel extends StatefulWidget {
  final MultiserverQueueModelType type;

  const MultiserverPanel({super.key, required this.type});

  @override
  State<MultiserverPanel> createState() => _MultiserverPanelState();
}

class _MultiserverPanelState extends State<MultiserverPanel> {
  final _formKey = GlobalKey<FormState>();
  final _lambdaController = TextEditingController(text: '8');
  final _muController = TextEditingController(text: '5');
  final _serversController = TextEditingController(text: '2');
  final _capacityController = TextEditingController(text: '6');

  MultiserverQueueResult? _result;
  String? _errorMessage;
  bool _isExporting = false;

  @override
  void dispose() {
    _lambdaController.dispose();
    _muController.dispose();
    _serversController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final lambda = double.parse(_lambdaController.text.replaceAll(',', '.'));
      final mu = double.parse(_muController.text.replaceAll(',', '.'));
      final servers = int.parse(_serversController.text);
      final capacity = widget.type.isFinite
          ? int.parse(_capacityController.text)
          : null;

      final result = MultiserverCalculator.calculate(
        lambda: lambda,
        mu: mu,
        servers: servers,
        type: widget.type,
        capacity: capacity,
      );
      setState(() => _result = result);
    } on MultiserverValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _result = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado al procesar los datos.';
        _result = null;
      });
    }
  }

  Future<void> _exportPdf(Future<void> Function(MultiserverQueueResult) action) async {
    if (_result == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await action(_result!);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'No se pudo generar el reporte PDF. Intenta nuevamente.');
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
                      text: 'Parámetros de entrada multicanal',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _lambdaController,
                      label: 'λ (TASA DE LLEGADA GLOBAL)',
                      description:
                          'Número promedio de clientes que llegan al '
                          'sistema por unidad de tiempo. Debe ser mayor que 0.',
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
                      label: 'μ (TASA DE SERVICIO POR SERVIDOR)',
                      description:
                          'Capacidad media de atención de cada servidor individual '
                          'por unidad de tiempo. Debe ser mayor que 0.',
                      validator: (v) {
                        final parsed =
                            double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (parsed == null) return 'Ingresa un número válido';
                        if (parsed <= 0) return 'μ debe ser mayor que 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _serversController,
                      label: 'c (NÚMERO DE SERVIDORES EN PARALELO)',
                      description:
                          'Cantidad de canales o servidores idénticos atendiendo simultáneamente. Entero ≥ 1.',
                      allowDecimal: false,
                      validator: (v) {
                        final parsed = int.tryParse(v ?? '');
                        if (parsed == null) return 'Ingresa un número entero';
                        if (parsed < 1) return 'c debe ser ≥ 1';
                        return null;
                      },
                    ),
                    if (widget.type.isFinite) ...[
                      const SizedBox(height: 14),
                      ParameterTextField(
                        controller: _capacityController,
                        label: 'N (CAPACIDAD MÁXIMA DEL SISTEMA)',
                        description:
                            'Número máximo total de clientes permitidos en el sistema '
                            '(c en atención + N − c en cola). Entero ≥ c.',
                        allowDecimal: false,
                        validator: (v) {
                          final parsed = int.tryParse(v ?? '');
                          if (parsed == null) return 'Ingresa un entero';
                          final c = int.tryParse(_serversController.text) ?? 1;
                          if (parsed < c) return 'N debe ser mayor o igual a c ($c)';
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
              MultiserverResultsPanel(result: _result!),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => MultiserverExplanationBottomSheet.show(
                    context,
                    result: _result!,
                  ),
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                  label: const Text('Interpretación'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              MultiserverGraphContainer(result: _result!),
              const SizedBox(height: 16),
              MultiserverDistributionTable(result: _result!),
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
                : () => _exportPdf(MultiserverPdfReport.print),
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
                : () => _exportPdf(MultiserverPdfReport.share),
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
