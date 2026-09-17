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
import 'poisson_calculator.dart';
import '../../core/widgets/explanation_bottom_sheet.dart';
import '../calculator/probability_pdf_report.dart';
import 'poisson_stat_procedures.dart';

/// Panel del módulo Poisson.
class PoissonPanel extends StatefulWidget {
  const PoissonPanel({super.key});

  @override
  State<PoissonPanel> createState() => _PoissonPanelState();
}

class _PoissonPanelState extends State<PoissonPanel> {
  final _formKey = GlobalKey<FormState>();
  final _lambdaController = TextEditingController(text: '3');
  final _xController = TextEditingController(text: '2');
  final _x2Controller = TextEditingController(text: '5');

  ProbabilityType _probabilityType = ProbabilityType.puntual;
  CalculationResult? _result;
  String? _errorMessage;
  bool _isExporting = false;

  bool get _isRange => _probabilityType.requiresTwoInputs;

  @override
  void dispose() {
    _lambdaController.dispose();
    _xController.dispose();
    _x2Controller.dispose();
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
        distributionType: DistributionType.poisson,
        probabilityType: _probabilityType,
        upperX: _isRange ? double.tryParse(_x2Controller.text) : null,
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
      final result = PoissonCalculator.calculate(
        lambda: double.parse(_lambdaController.text.replaceAll(',', '.')),
        x: int.parse(_xController.text),
        x2: _isRange ? int.parse(_x2Controller.text) : null,
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
      _xController.clear();
      _x2Controller.clear();
      _result = null;
      _errorMessage = null;
    });
    _formKey.currentState?.reset();
  }

  String? _validateX2(String? v) {
    final base = Validators.nonNegativeInt(v, label: 'xⱼ');
    if (base != null) return base;
    final x1 = int.tryParse(_xController.text);
    final x2 = int.tryParse(v ?? '');
    if (x1 != null && x2 != null && x2 < x1) {
      return 'xⱼ debe ser mayor o igual que xᵢ';
    }
    return null;
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
                      label: 'λ (TASA PROMEDIO)',
                      description:
                          'Tasa promedio de ocurrencia del evento en el '
                          'intervalo. Debe ser mayor que 0.',
                      validator: (v) => Validators.positiveDouble(
                        v,
                        label: 'λ',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ParameterTextField(
                      controller: _xController,
                      label: _isRange
                          ? 'xᵢ (LÍMITE INFERIOR)'
                          : 'x (NÚMERO DE OCURRENCIAS)',
                      description: _isRange
                          ? 'Límite inferior del rango a evaluar. Entero ≥ 0.'
                          : 'Número de ocurrencias del evento que deseas '
                              'evaluar. Debe ser un entero mayor o igual a 0.',
                      allowDecimal: false,
                      // Revalida también xⱼ cuando xᵢ cambia, para
                      // mantener consistente la comparación entre ambos.
                      onChanged: () => _formKey.currentState?.validate(),
                      validator: (v) =>
                          Validators.nonNegativeInt(v, label: 'x'),
                    ),
                    if (_isRange) ...[
                      const SizedBox(height: 14),
                      ParameterTextField(
                        controller: _x2Controller,
                        label: 'xⱼ (LÍMITE SUPERIOR)',
                        description:
                            'Límite superior del rango a evaluar. Debe ser '
                            'mayor o igual que xᵢ.',
                        allowDecimal: false,
                        validator: _validateX2,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ProbabilityTypeSelector(
                      distributionType: DistributionType.poisson,
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
                distributionType: DistributionType.poisson,
                probabilityType: _probabilityType,
                upperX: _isRange ? double.tryParse(_x2Controller.text) : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => ExplanationBottomSheet.show(
                    context,
                    result: _result!,
                    distributionType: DistributionType.poisson,
                    probabilityType: _probabilityType,
                    upperX:
                        _isRange ? double.tryParse(_x2Controller.text) : null,
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
                procedures: PoissonStatProcedures.build(_result!),
              ),
              const SizedBox(height: 16),
              DistributionGraphContainer(
                result: _result!,
                pointLabel: 'Probabilidad (PMF)',
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