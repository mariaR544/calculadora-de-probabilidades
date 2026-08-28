import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora/main.dart';

void main() {
  testWidgets('La aplicación Quantis carga con la pantalla de inicio',
      (WidgetTester tester) async {
    // Construye la app y dispara un frame.
    await tester.pumpWidget(const StatCalculatorApp());

    // Verifica que el título de la app bar aparezca.
    expect(find.text('Quantis'), findsOneWidget);
    expect(find.text('¡Bienvenido a Quantis!'), findsOneWidget);
  });
}