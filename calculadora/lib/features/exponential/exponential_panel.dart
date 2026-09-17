import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/distribution_graph_container.dart';
import '../../core/widgets/parameter_text_field.dart';
import '../../core/widgets/probability_type_selector.dart';
import '../../core/widgets/results_panel.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/stat_summary_grid.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../../utils/validators.dart';
import 'exponential_calculator.dart';
import '../../core/widgets/explanation_bottom_sheet.dart';
import '../calculator/probability_pdf_report.dart';
import 'exponential_stat_procedures.dart';

/// Panel del módulo Exponencial.
class ExponentialPanel extends StatefulWidget {
  const ExponentialPanel({super.key});

  @override
  State<ExponentialPanel> createState() => _ExponentialPanelState();
}

class _ExponentialPanelState extends State<ExponentialPanel> {
  final _formKey = GlobalKey<FormState>();
  final _lambdaController = TextEditingController(text: '0.5');
  final _xiController = TextEditingController(text: '2');
  final _xjController = TextEditingController(text: '4');

  ProbabilityType _probabilityType = ProbabilityType.menorOIgual;
  CalculationResult? _result;
  String? _errorMessage;
  bool _isExporting = false;

  @override
  void dispose() {
    _lambdaController.dispose();
    _xiController.dispose();
    _xjController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(Future<void> Function({
    required CalculationResult result,
    required DistributionType distributionType,
    required ProbabilityType probabilityType,
    double? upperX,
  }) action) async {
    if (_result == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await action(
        result: _result!,
        distributionType: DistributionType.exponential,
        probabilityType: _probabilityType,
        upperX: _probabilityType.requiresTwoInputs
            ? double.tryParse(_xjController.text)
            : null,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            'No se pudo generar el reporte PDF. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _calculate() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final double xi = double.parse(_xiController.text.replaceAll(',', '.'));
      final double? xj = _probabilityType.requiresTwoInputs
          ? double.parse(_xjController.text.replaceAll(',', '.'))
          : null;

      final result = ExponentialCalculator.calculate(
        lambda: double.parse(_lambdaController.text.replaceAll(',', '.')),
        xi: xi,
        xj: xj,
        type: _probabilityType,
      );
      setState(() => _result = result);
    } on ValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _result = null;
      });
    }
  }

  /// Limpia todos los campos de entrada y descarta el resultado
  /// calculado, devolviendo el panel a su estado inicial.
  void _resetAll() {
    setState(() {
      _lambdaController.clear();
      _xiController.clear();
      _xjController.clear();
      _result = null;
      _errorMessage = null;
    });
    _formKey.currentState?.reset();
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
                    Row(
                      children: [
                        const Expanded(
                          child: SectionTitle(
                            text: 'Parámetros de entrada',
                            icon: Icons.tune_rounded,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _resetAll,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _lambdaController,
                      label: 'λ (TASA DE FRECUENCIA)',
                      description:
                          'Tasa de frecuencia con la que ocurren los eventos '
                          '(número esperado de eventos por unidad de tiempo '
                          'o espacio). Debe ser mayor que 0.',
                      validator: (v) =>
                          Validators.positiveDouble(v, label: 'λ'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ParameterTextField(
                            controller: _xiController,
                            label: _probabilityType.requiresTwoInputs
                                ? 'xᵢ (LÍMITE INFERIOR)'
                                : 'xᵢ (VALOR A EVALUAR)',
                            description:
                                'Tiempo o espacio transcurrido que deseas evaluar. '
                                'Debe ser mayor o igual a 0.',
                            validator: (v) =>
                                Validators.nonNegativeDouble(v, label: 'xᵢ'),
                          ),
                        ),
                        if (_probabilityType.requiresTwoInputs) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ParameterTextField(
                              controller: _xjController,
                              label: 'xⱼ (LÍMITE SUPERIOR)',
                              description:
                                  'Límite superior del rango a evaluar. '
                                  'Debe ser mayor o igual a 0.',
                              validator: (v) =>
                                  Validators.nonNegativeDouble(v, label: 'xⱼ'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProbabilityTypeSelector(
                      distributionType: DistributionType.exponential,
                      value: _probabilityType,
                      onChanged: (v) => setState(() => _probabilityType = v),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate_rounded, size: 18),
                        label: const Text('Calcular probabilidad'),
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
              ResultsPanel(
                result: _result!,
                distributionType: DistributionType.exponential,
                probabilityType: _probabilityType,
                upperX: _probabilityType.requiresTwoInputs
                    ? double.tryParse(_xjController.text)
                    : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => ExplanationBottomSheet.show(
                    context,
                    result: _result!,
                    distributionType: DistributionType.exponential,
                    probabilityType: _probabilityType,
                    upperX: _probabilityType.requiresTwoInputs
                        ? double.tryParse(_xjController.text)
                        : null,
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
              const SizedBox(height: 8),
              StatSummaryGrid(
                result: _result!,
                procedures: ExponentialStatProcedures.build(_result!),
              ),
              const SizedBox(height: 16),
              DistributionGraphContainer(
                result: _result!,
                pointLabel: 'Densidad (PDF)',
                cumulativeLabel: 'Acumulativa (CDF)',
              ),
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
                : () => _exportPdf(ProbabilityPdfReport.print),
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
                : () => _exportPdf(ProbabilityPdfReport.share),
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