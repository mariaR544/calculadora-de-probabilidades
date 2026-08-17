import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/distribution_drawer.dart';
import '../../core/widgets/formula_card.dart';
import '../../models/distribution_type.dart';
import '../exponential/exponential_panel.dart';
import '../poisson/poisson_panel.dart';

/// Pantalla dedicada exclusivamente a una distribución de probabilidad.
///
/// Estructura:
///  1. Encabezado simple: nombre de la distribución + botón "Fórmulas".
///  2. Cuerpo: panel de parámetros de entrada (lo primero que ve el
///     usuario), seguido del selector de probabilidad, botón
///     "Calcular" y, tras calcular, resultados y gráfica.
///
/// Las fórmulas, definiciones y restricciones NO se muestran en esta
/// pantalla junto a los parámetros: solo aparecen al pulsar el botón
/// "Fórmulas", dentro de un panel deslizable (bottom sheet).
class DistributionScreen extends StatelessWidget {
  final DistributionType type;

  const DistributionScreen({super.key, required this.type});

  void _showFormulas(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: FormulaCard(type: type),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Estadística'),
      ),
      drawer: DistributionDrawer(selected: type),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado simple: nombre de la distribución + acceso a fórmulas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label, style: AppTextStyles.headline),
                      const SizedBox(height: 2),
                      Text(type.natureLabel, style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showFormulas(context),
                  icon: const Icon(Icons.functions_rounded, size: 17),
                  label: const Text('Fórmulas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Cuerpo: parámetros de entrada primero, resultados y gráfica después
          Expanded(
            child: type == DistributionType.poisson
                ? const PoissonPanel()
                : const ExponentialPanel(),
          ),
        ],
      ),
    );
  }
}