/// Distribuciones de probabilidad soportadas por la calculadora.
///
/// Para agregar un nuevo módulo de distribución en el futuro, basta con
/// añadir un nuevo valor aquí y crear su carpeta correspondiente dentro
/// de `lib/features/`.
enum DistributionType { poisson, exponential }

extension DistributionTypeX on DistributionType {
  bool get isDiscrete => this == DistributionType.poisson;

  String get label {
    switch (this) {
      case DistributionType.poisson:
        return 'Poisson';
      case DistributionType.exponential:
        return 'Exponencial';
    }
  }

  String get natureLabel =>
      isDiscrete ? 'Distribución discreta' : 'Distribución continua';

  String get variableName => isDiscrete ? 'k' : 'x';

  String get description {
    switch (this) {
      case DistributionType.poisson:
        return 'Modela el número de ocurrencias de un evento dentro de un '
            'intervalo continuo (tiempo, área, volumen), dada una tasa '
            'promedio de ocurrencia λ.';
      case DistributionType.exponential:
        return 'Modela el tiempo o espacio transcurrido entre dos eventos '
            'consecutivos de un proceso de Poisson, dada una tasa λ.';
    }
  }
}
