import 'distribution_type.dart';

/// Tipo de probabilidad que el usuario desea evaluar.
///
/// [puntual] únicamente tiene sentido para distribuciones discretas
/// (aplica a Poisson). Las distribuciones continuas (Exponencial) solo
/// admiten probabilidad acumulada inferior o superior.
enum ProbabilityType { // Puntual (Solo Poisson)
  puntual, // P(X = x)

  // Un solo límite (Poisson y Exponencial)
  mayorQue, // P(X > xᵢ)
  menorQue, // P(X < xᵢ)
  mayorOIgual, // P(X ≥ xᵢ)
  menorOIgual, // P(X ≤ xᵢ)

  // Rangos (Poisson y Exponencial)
  estrictoRango, // P(xᵢ < X < xⱼ)
  cerradoRango, // P(xᵢ ≤ X ≤ xⱼ)
  izqCerradoDerAbierto, // P(xᵢ ≤ X < xⱼ)
  izqAbiertoDerCerrado, // P(xᵢ < X ≤ xⱼ)
 }

extension ProbabilityTypeX on ProbabilityType {
String get shortLabel {
    switch (this) {
      case ProbabilityType.puntual:
        return 'P(X = x)';
      case ProbabilityType.mayorQue:
        return 'P(X > xᵢ)';
      case ProbabilityType.menorQue:
        return 'P(X < xᵢ)';
      case ProbabilityType.mayorOIgual:
        return 'P(X ≥ xᵢ)';
      case ProbabilityType.menorOIgual:
        return 'P(X ≤ xᵢ)';
      case ProbabilityType.estrictoRango:
        return 'P(xᵢ < X < xⱼ)';
      case ProbabilityType.cerradoRango:
        return 'P(xᵢ ≤ X ≤ xⱼ)';
      case ProbabilityType.izqCerradoDerAbierto:
        return 'P(xᵢ ≤ X < xⱼ)';
      case ProbabilityType.izqAbiertoDerCerrado:
        return 'P(xᵢ < X ≤ xⱼ)';
    }
}

/// Devuelve true si la opción seleccionada requiere dos campos de entrada (xᵢ y xⱼ)
bool get requiresTwoInputs {
    switch (this) {
      case ProbabilityType.estrictoRango:
      case ProbabilityType.cerradoRango:
      case ProbabilityType.izqCerradoDerAbierto:
      case ProbabilityType.izqAbiertoDerCerrado:
        return true;
      default:
        return false;
    }
  }

  /// Fórmula visible con el nombre de variable correcto según la
  /// distribución (k para discretas, x para continuas).
String formulaFor(DistributionType type) {
    switch (this) {
      case ProbabilityType.puntual:
        return 'P(X = x)';
      case ProbabilityType.mayorQue:
        return 'P(X > xᵢ)';
      case ProbabilityType.menorQue:
        return 'P(X < xᵢ)';
      case ProbabilityType.mayorOIgual:
        return 'P(X ≥ xᵢ)';
      case ProbabilityType.menorOIgual:
        return 'P(X ≤ xᵢ)';
      case ProbabilityType.estrictoRango:
        return 'P(xᵢ < X < xⱼ)';
      case ProbabilityType.cerradoRango:
        return 'P(xᵢ ≤ X ≤ xⱼ)';
      case ProbabilityType.izqCerradoDerAbierto:
        return 'P(xᵢ ≤ X < xⱼ)';
      case ProbabilityType.izqAbiertoDerCerrado:
        return 'P(xᵢ < X ≤ xⱼ)';
    }
  }

static List<ProbabilityType> optionsFor(DistributionType type) {
    if (type.isDiscrete) {
      // Poisson (Discreta): Admite las 9 opciones solicitadas en la guía
      return const [
        ProbabilityType.puntual,
        ProbabilityType.mayorQue,
        ProbabilityType.menorQue,
        ProbabilityType.mayorOIgual,
        ProbabilityType.menorOIgual,
        ProbabilityType.estrictoRango,
        ProbabilityType.cerradoRango,
        ProbabilityType.izqCerradoDerAbierto,
        ProbabilityType.izqAbiertoDerCerrado,
      ];
    }

    // Exponencial (Continua): Solo admite los 3 casos especificados en la guía
    return const [
      ProbabilityType.mayorOIgual,
      ProbabilityType.menorOIgual,
      ProbabilityType.cerradoRango,
    ];
  }
}
