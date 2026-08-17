import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/distribution_drawer.dart';

/// Pantalla de inicio de la calculadora.
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Estadística'),
        elevation: 0,
      ),
      drawer: const DistributionDrawer(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo oficial de la app sin contenedor circular y de mayor tamaño
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Image.asset(
                    'lib/image/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.bar_chart_rounded,
                        size: 80,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Saludo de bienvenida
                Text(
                  '¡Bienvenido!',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculadora de Distribución de Probabilidades',
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 16,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Card explicativa con la acción requerida
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Para comenzar a realizar tus cálculos seleccione una distribución.',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Botón principal
                      Builder(
                        builder: (context) => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Seleccione una distribución',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}