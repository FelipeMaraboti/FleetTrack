import '../exceptions/telemetria_exceptions.dart';

/// Representa uma rota urbana planejada para os veículos da frota.
class Rota {
  final String id;
  final String origem;
  final String destino;
  final double distanciaKm;
  final double tempoEstimadoMinutos;
  bool _ativa;

  Rota({
    required this.id,
    required this.origem,
    required this.destino,
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    bool ativa = true,
  }) : _ativa = ativa {
    if (id.trim().isEmpty || origem.trim().isEmpty || destino.trim().isEmpty) {
      throw RotaInvalidaException(
        'Id, origem e destino da rota são obrigatórios e não podem ser vazios.',
      );
    }

    if (distanciaKm < 0.0) {
      throw RotaInvalidaException(
        'Distância da rota não pode ser negativa: $distanciaKm km',
      );
    }

    if (tempoEstimadoMinutos <= 0.0) {
      throw RotaInvalidaException(
        'Tempo estimado da rota deve ser positivo: $tempoEstimadoMinutos min',
      );
    }
  }

  /// Getter para verificação do status da rota.
  bool get ativa => _ativa;

  /// Ativa a rota para operação.
  void ativar() => _ativa = true;

  /// Desativa temporariamente a rota.
  void desativar() => _ativa = false;

  /// Calcula a velocidade média planejada da rota em km/h.
  double calcularVelocidadeMedia() {
    final horas = tempoEstimadoMinutos / 60.0;
    return distanciaKm / horas;
  }

  @override
  String toString() {
    final status = _ativa ? 'ATIVA' : 'INATIVA';
    return '$id - $origem -> $destino (${distanciaKm.toStringAsFixed(1)} km, ${tempoEstimadoMinutos.toStringAsFixed(0)} min, $status)';
  }
}
