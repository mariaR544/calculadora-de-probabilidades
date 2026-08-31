import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import 'database_sim_panel.dart';

/// Pantalla dedicada al Módulo 4: Simulación de Base de Datos.
class DatabaseSimScreen extends StatelessWidget {
  const DatabaseSimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quantis')),
      drawer: const AppDrawer(selectedDatabaseSim: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Simulación de Montecarlo', style: AppTextStyles.headline),
                const SizedBox(height: 2),
                Text(
                  'Generación de variables Poisson / Exponencial',
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: DatabaseSimPanel()),
        ],
      ),
    );
  }
}
