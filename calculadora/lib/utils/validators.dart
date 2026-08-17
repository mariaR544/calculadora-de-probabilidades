/// Validadores de campos de texto usados en los formularios de
/// parámetros. Devuelven `null` si el valor es válido, o un mensaje de
/// error listo para mostrar en el `TextFormField`.
class Validators {
  Validators._();

  static String? positiveDouble(String? value, {String label = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed <= 0) {
      return '$label debe ser mayor que 0';
    }
    return null;
  }

  static String? nonNegativeInt(String? value, {String label = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Ingresa un número entero';
    }
    if (parsed < 0) {
      return '$label debe ser ≥ 0';
    }
    return null;
  }

  static String? nonNegativeDouble(String? value, {String label = 'El valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label es obligatorio';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Ingresa un número válido';
    }
    if (parsed < 0) {
      return '$label debe ser ≥ 0';
    }
    return null;
  }
}
