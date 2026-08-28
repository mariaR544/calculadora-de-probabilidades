import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/queue_model_type.dart';
import 'queue_formula_card.dart';
import 'queue_panel.dart';

/// Pantalla dedicada exclusivamente a un modelo de colas (M/M/1 sin
/// límite o M/M/1 con límite N). Mismo patrón que `DistributionScreen`
/// del Módulo 1: encabezado simple + botón "Fórmulas" + panel de
/// parámetros como lo primero que ve el usuario.
class QueueScreen extends StatelessWidget {
  final QueueModelType type;

  const QueueScreen({super.key, required this.type});

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
                  child: QueueFormulaCard(type: type),
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
        title: const Text('Quantis'),
      ),
      drawer: AppDrawer(selectedQueueType: type),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: QueuePanel(type: type)),
        ],
      ),
    );
  }
}
