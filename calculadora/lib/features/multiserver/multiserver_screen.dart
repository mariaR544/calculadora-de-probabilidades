import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_drawer.dart';
import '../../models/multiserver_queue_model_type.dart';
import 'multiserver_formula_card.dart';
import 'multiserver_panel.dart';

/// Pantalla dedicada exclusivamente a un modelo de colas multicanal
/// (M/M/c sin límite o M/M/c con límite N). Misma arquitectura y estética
/// que las pantallas de los módulos 1 y 2.
class MultiserverScreen extends StatelessWidget {
  final MultiserverQueueModelType type;

  const MultiserverScreen({super.key, required this.type});

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
                  child: MultiserverFormulaCard(type: type),
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
      drawer: AppDrawer(selectedMultiserverType: type),
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
          Expanded(
            child: MultiserverPanel(type: type),
          ),
        ],
      ),
    );
  }
}
