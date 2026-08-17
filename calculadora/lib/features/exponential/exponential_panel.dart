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
import 'exponential_calculator.dart';
import 'exponential_chart_painter.dart';

/// Panel del módulo Exponencial.
///
/// Muestra primero el formulario de parámetros de entrada; las
/// fórmulas y la teoría se acceden desde el botón "Fórmulas" de
/// [DistributionScreen] y no se repiten aquí. Al pulsar "Calcular" se
/// muestran los resultados (probabilidad, E[X], Var(X)) y la gráfica.

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

  @override
  void dispose() {
    _lambdaController.dispose();
    _xiController.dispose();
    _xjController.dispose();
    super.dispose();
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
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        text: 'Densidad f(x)',
                        icon: Icons.show_chart_rounded,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ExponentialChartPainter(
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
        _dot(AppColors.highlight),
        const SizedBox(width: 6),
        Text('Área evaluada', style: AppTextStyles.subtitle),
        const SizedBox(width: 16),
        Container(width: 14, height: 2, color: AppColors.primaryDark),
        const SizedBox(width: 6),
        Text('f(x)', style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}