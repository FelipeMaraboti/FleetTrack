import '../exceptions/telemetria_exceptions.dart';

/// Contrato base e abstração principal para qualquer dispositivo móvel
/// ou veículo conectado monitorado pelo sistema FleetTrack.
abstract class DispositivoMovel {
  final String id;
  final String modelo;
  double _nivelBateria;

  DispositivoMovel({
    required this.id,
    required this.modelo,
    double nivelBateria = 100.0,
  }) : _nivelBateria = nivelBateria {
    if (nivelBateria < 0 || nivelBateria > 100) {
      throw DadosTelemetriaInvalidosException(
        'Nível inicial de bateria inválido: $nivelBateria%. Deve estar entre 0 e 100.',
      );
    }
  }

  /// Getter para leitura segura do nível de bateria encapsulado.
  double get nivelBateria => _nivelBateria;

  /// Setter com validação de limites físicos (0 a 100%).
  set nivelBateria(double valor) {
    if (valor < 0 || valor > 100) {
      throw DadosTelemetriaInvalidosException(
        'Tentativa de atribuir nível de bateria inválido: $valor%. Limites válidos: 0% a 100%.',
      );
    }
    _nivelBateria = valor;
  }

  /// Método polimórfico abstrato para processar consumo e esforço operacional.
  void processarCargaTrabalho(double intensidade);

  @override
  String toString() {
    return '$id - $modelo (Bateria: ${_nivelBateria.toStringAsFixed(1)}%)';
  }
}
