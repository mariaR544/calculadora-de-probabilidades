import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora/main.dart';

void main() {
  testWidgets('La calculadora carga con el modulo Poisson seleccionado',
      (WidgetTester tester) async {
    // Construye la app y dispara un frame.
    await tester.pumpWidget(const StatCalculatorApp());

    // Verifica que el titulo de la app bar aparezca.
    expect(find.text('Calculadora Estadística'), findsOneWidget);

    // Poisson debe estar seleccionado por defecto.
    expect(find.text('Poisson'), findsOneWidget);
    expect(find.text('Exponencial'), findsOneWidget);

    // El boton de calcular del panel Poisson debe estar visible.
    expect(find.text('Calcular probabilidad'), findsOneWidget);
  });
}