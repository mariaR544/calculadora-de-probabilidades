import 'package:flutter/material.dart';
import '../../features/calculator/distribution_screen.dart';
import '../../features/queueing/queue_screen.dart';
import '../../models/distribution_type.dart';
import '../../models/queue_model_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Menú lateral (Drawer) único de la aplicación, con dos secciones:
///  - Módulo 1 · Probabilidades (Poisson, Exponencial)
///  - Módulo 2 · Líneas de espera (M/M/1 sin límite, M/M/1 con límite)
///
/// Reemplaza a `DistributionDrawer`. Al seleccionar una opción, navega
/// a su pantalla dedicada reemplazando la ruta actual (mismo criterio
/// que el Módulo 1: siempre una única pantalla de cálculo activa, con
/// el ícono de menú disponible en el AppBar).
class AppDrawer extends StatelessWidget {
  /// Distribución activa, si la pantalla actual pertenece al Módulo 1.
  final DistributionType? selectedDistribution;

  /// Modelo de colas activo, si la pantalla actual pertenece al Módulo 2.
  final QueueModelType? selectedQueueType;

  const AppDrawer({
    super.key,
    this.selectedDistribution,
    this.selectedQueueType,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Text('MÓDULO 1 · PROBABILIDADES', style: AppTextStyles.label),
            ),
            for (final type in DistributionType.values)
              _DrawerTile(
                icon: type.isDiscrete
                    ? Icons.bar_chart_rounded
                    : Icons.show_chart_rounded,
                title: type.label,
                subtitle: type.natureLabel,
                selected: type == selectedDistribution,
                onTap: () {
                  Navigator.of(context).pop();
                  if (type != selectedDistribution) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => DistributionScreen(type: type),
                      ),
                    );
                  }
                },
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
              child: Divider(height: 1),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Text('MÓDULO 2 · LÍNEAS DE ESPERA', style: AppTextStyles.label),
            ),
            for (final type in QueueModelType.values)
              _DrawerTile(
                icon: type.isFinite
                    ? Icons.block_rounded
                    : Icons.all_inclusive_rounded,
                title: type.label,
                subtitle: type.kendallNotation,
                selected: type == selectedQueueType,
                onTap: () {
                  Navigator.of(context).pop();
                  if (type != selectedQueueType) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QueueScreen(type: type),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.subtitle),
      trailing: selected
          ? const Icon(Icons.check_rounded, size: 18, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
