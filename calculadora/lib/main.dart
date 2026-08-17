import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/calculator/calculator_screen.dart';

void main() {
  runApp(const StatCalculatorApp());
}

class StatCalculatorApp extends StatelessWidget {
  const StatCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora Estadística',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const CalculatorScreen(),
    );
  }
}
