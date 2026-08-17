import 'package:flutter/material.dart';

/// Paleta de colores centralizada de la aplicación.
///
/// Se utiliza una gama de azules suaves y poco saturados para transmitir
/// calma y claridad, apropiada para una herramienta de cálculo técnico.
class AppColors {
  AppColors._();

  // Colores principales de marca
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4FBB);
  static const Color primaryLight = Color(0xFF7EA6F5);

  // Fondos
  static const Color background = Color(0xFFF3F6FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEAF1FC);

  // Resaltados (para regiones seleccionadas en las gráficas)
  static const Color highlight = Color(0xFF9CC2FA);
  static const Color highlightStrong = Color(0xFF4C86F0);
  static const Color barBase = Color(0xFFD8E4FA);

  // Textos
  static const Color textPrimary = Color(0xFF1C2B45);
  static const Color textSecondary = Color(0xFF62728A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Bordes y líneas
  static const Color border = Color(0xFFDCE6F5);
  static const Color axis = Color(0xFFB7C6E0);

  // Estados
  static const Color error = Color(0xFFD64545);
  static const Color success = Color(0xFF2FA36B);
}
