/// Modelos de líneas de espera multicanal (múltiples servidores M/M/c)
/// soportados por el Módulo 3 de Quantis.
enum MultiserverQueueModelType { infinite, finite }

extension MultiserverQueueModelTypeX on MultiserverQueueModelType {
  bool get isFinite => this == MultiserverQueueModelType.finite;

  String get label => isFinite
      ? 'M/M/c con límite en cola'
      : 'M/M/c sin límite en cola';

  /// Notación de Kendall del modelo.
  String get kendallNotation =>
      isFinite ? 'M/M/c : DG/N/∞' : 'M/M/c : DG/∞/∞';

  String get natureLabel =>
      isFinite ? 'Capacidad finita (N)' : 'Capacidad infinita';

  String get description => isFinite
      ? 'Sistema de c servidores paralelos con disciplina FIFO y capacidad máxima '
          'N clientes en el sistema (c en atención y N - c en cola). '
          'Los clientes que llegan cuando el sistema está lleno son rechazados (pérdida).'
      : 'Sistema de c servidores paralelos idénticos con disciplina FIFO, sin '
          'límite de capacidad en la cola: todos los clientes que llegan ingresan '
          'y son eventualmente atendidos.';
}
