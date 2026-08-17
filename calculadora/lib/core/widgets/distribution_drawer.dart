import 'package:flutter/material.dart';
import '../../models/distribution_type.dart';
import '../../features/calculator/distribution_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Menú lateral (Drawer) para seleccionar la distribución de
/// probabilidad con la que se desea trabajar.
///
/// Al seleccionar una opción, se navega a su pantalla dedicada
/// ([DistributionScreen]) reemplazando la ruta actual, de forma que
/// siempre exista una única pantalla de distribución activa y el
/// icono de menú (hamburguesa) permanezca disponible en el AppBar.
class DistributionDrawer extends StatelessWidget {
  /// Distribución actualmente activa (null si se abre desde el inicio).
  final DistributionType? selected;

  const DistributionDrawer({super.key, this.selected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Text('DISTRIBUCIONES DISPONIBLES', style: AppTextStyles.label),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: DistributionType.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final type = DistributionType.values[index];
                  final isSelected = type == selected;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.surfaceAlt,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: Icon(
                      type.isDiscrete
                          ? Icons.bar_chart_rounded
                          : Icons.show_chart_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      type.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(type.natureLabel, style: AppTextStyles.subtitle),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(); // cierra el drawer
                      if (!isSelected) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => DistributionScreen(type: type),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}