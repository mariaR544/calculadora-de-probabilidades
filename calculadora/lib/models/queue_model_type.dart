/// Modelos de líneas de espera (teoría de colas) soportados por el
/// Módulo 2 de Quantis.
///
/// Para agregar un nuevo modelo en el futuro (ej. M/M/c), basta con
/// añadir un valor aquí y su carpeta correspondiente dentro de
/// `lib/features/queueing/`.
enum QueueModelType { infinite, finite }

extension QueueModelTypeX on QueueModelType {
  bool get isFinite => this == QueueModelType.finite;

  String get label =>
      isFinite ? 'M/M/1 con límite en cola' : 'M/M/1 sin límite en cola';

  /// Notación de Kendall del modelo.
  String get kendallNotation =>
      isFinite ? 'M/M/1 : DG/N/∞' : 'M/M/1 : DG/∞/∞';

  String get natureLabel =>
      isFinite ? 'Capacidad finita (N)' : 'Capacidad infinita';

  String get description => isFinite
      ? 'Sistema de un servidor con disciplina FIFO y capacidad máxima '
          'N (incluyendo al cliente en servicio). Los clientes que '
          'llegan cuando el sistema está lleno se pierden: no entran '
          'a la cola ni son atendidos.'
      : 'Sistema de un servidor con disciplina FIFO, sin límite de '
          'capacidad en la cola ni en la población de llegada: todo '
          'cliente que llega eventualmente es atendido.';
}
