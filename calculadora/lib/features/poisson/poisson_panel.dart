import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/parameter_text_field.dart';
import '../../core/widgets/probability_type_selector.dart';
import '../../core/widgets/results_panel.dart';
import '../../core/widgets/section_title.dart';
import '../../models/calculation_result.dart';
import '../../models/distribution_type.dart';
import '../../models/probability_type.dart';
import '../../utils/validators.dart';
import 'poisson_calculator.dart';
import 'poisson_chart_painter.dart';

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

  ProbabilityType _probabilityType = ProbabilityType.puntual;
  CalculationResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _lambdaController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = PoissonCalculator.calculate(
        lambda: double.parse(_lambdaController.text.replaceAll(',', '.')),
        x: int.parse(_xController.text),
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
                      label: 'x (NÚMERO DE OCURRENCIAS)',
                      description:
                          'Número de ocurrencias del evento que deseas '
                          'evaluar. Debe ser un entero mayor o igual a 0.',
                      allowDecimal: false,
                      validator: (v) =>
                          Validators.nonNegativeInt(v, label: 'x'),
                    ),
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
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        text: 'Distribución P(X = x)',
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: PoissonChartPainter(
                            points: _result!.points,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _Legend(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(AppColors.highlightStrong),
        const SizedBox(width: 6),
        Text('Región evaluada', style: AppTextStyles.subtitle),
        const SizedBox(width: 16),
        _dot(AppColors.barBase),
        const SizedBox(width: 6),
        Text('Resto de la distribución', style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}