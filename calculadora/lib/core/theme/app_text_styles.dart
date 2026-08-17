import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto reutilizados en toda la aplicación, para mantener
/// consistencia tipográfica entre módulos.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const TextStyle formula = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
    fontFamily: 'monospace',
  );

  static const TextStyle label = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle resultValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDark,
  );

  static const TextStyle momentValue = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
