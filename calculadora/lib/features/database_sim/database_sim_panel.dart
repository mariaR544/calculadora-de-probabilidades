import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/distribution_toggle.dart';
import '../../core/widgets/parameter_text_field.dart';
import '../../core/widgets/section_title.dart';
import '../../models/database_simulation.dart';
import '../../models/distribution_type.dart';
import 'database_simulator.dart';
import 'database_summary_panel.dart';
import 'database_table_view.dart';
import 'database_sim_pdf_report.dart';

/// Panel del Módulo 4: elige distribución (Poisson/Exponencial),
/// parámetro λ, número de variables y de observaciones; genera la
/// "base de datos" simulada y permite exportarla a PDF.
class DatabaseSimPanel extends StatefulWidget {
  const DatabaseSimPanel({super.key});

  @override
  State<DatabaseSimPanel> createState() => _DatabaseSimPanelState();
}

class _DatabaseSimPanelState extends State<DatabaseSimPanel> {
  final _formKey = GlobalKey<FormState>();
  final _lambdaController = TextEditingController(text: '4');
  final _numVariablesController = TextEditingController(text: '3');
  final _numObservationsController = TextEditingController(text: '20');

  DistributionType _distributionType = DistributionType.poisson;
  SimulationResult? _result;
  String? _errorMessage;
  bool _isExporting = false;

  @override
  void dispose() {
    _lambdaController.dispose();
    _numVariablesController.dispose();
    _numObservationsController.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = DatabaseSimulator.generate(
        distributionType: _distributionType,
        lambda: double.parse(_lambdaController.text.replaceAll(',', '.')),
        numVariables: int.parse(_numVariablesController.text),
        numObservations: int.parse(_numObservationsController.text),
      );
      setState(() => _result = result);
    } on SimulationValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _result = null;
      });
    }
  }

  Future<void> _exportPdf(Future<void> Function(SimulationResult) action) async {
    if (_result == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await action(_result!);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo generar el PDF. Intenta nuevamente.');
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
                      text: 'Parámetros de la simulación',
                      icon: Icons.tune_rounded,
                    ),
                    const SizedBox(height: 14),
                    Text('DISTRIBUCIÓN A SIMULAR', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    DistributionToggle(
                      value: _distributionType,
                      onChanged: (v) => setState(() => _distributionType = v),
                    ),
                    const SizedBox(height: 16),
                    ParameterTextField(
                      controller: _lambdaController,
                      label: 'λ (PARÁMETRO DE LA DISTRIBUCIÓN)',
                      description: _distributionType.isDiscrete
                          ? 'Tasa promedio de ocurrencia (Poisson). Debe ser mayor que 0.'
                          : 'Tasa de frecuencia (Exponencial). Debe ser mayor que 0.',
                      validator: (v) {
                        final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (parsed == null) return 'Ingresa un número válido';
                        if (parsed <= 0) return 'λ debe ser mayor que 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ParameterTextField(
                            controller: _numVariablesController,
                            label: 'N° DE VARIABLES',
                            description:
                                'Cuántas columnas independientes se simulan '
                                'a la vez (1 a ${DatabaseSimulator.maxVariables}).',
                            allowDecimal: false,
                            validator: (v) {
                              final parsed = int.tryParse(v ?? '');
                              if (parsed == null) return 'Ingresa un entero';
                              if (parsed < 1 || parsed > DatabaseSimulator.maxVariables) {
                                return '1 a ${DatabaseSimulator.maxVariables}';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ParameterTextField(
                            controller: _numObservationsController,
                            label: 'N° DE OBSERVACIONES',
                            description:
                                'Tamaño de la muestra por variable (1 a '
                                '${DatabaseSimulator.maxObservations}).',
                            allowDecimal: false,
                            validator: (v) {
                              final parsed = int.tryParse(v ?? '');
                              if (parsed == null) return 'Ingresa un entero';
                              if (parsed < 1 || parsed > DatabaseSimulator.maxObservations) {
                                return '1 a ${DatabaseSimulator.maxObservations}';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Generar base de datos'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              DatabaseSummaryPanel(result: _result!),
              const SizedBox(height: 16),
              DatabaseTableView(result: _result!),
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
            onPressed: _isExporting ? null : () => _exportPdf(DatabaseSimPdfReport.print),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Imprimir'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : () => _exportPdf(DatabaseSimPdfReport.share),
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
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
