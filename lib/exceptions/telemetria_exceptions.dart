/// Exceções customizadas de domínio para o sistema FleetTrack.

/// Disparada quando um recurso essencial (ex: bateria) atinge um nível crítico
/// que impede a continuidade segura da operação do veículo.
class RecursoCriticoException implements Exception {
  final String mensagem;
  final double? nivelBateria;

  RecursoCriticoException(this.mensagem, [this.nivelBateria]);

  @override
  String toString() {
    final bateria = nivelBateria;
    final detalhe = bateria != null
        ? ' (Nível: ${bateria.toStringAsFixed(1)}%)'
        : '';
    return 'RecursoCriticoException: $mensagem$detalhe';
  }
}

/// Disparada quando leituras de sensores (GPS, velocidade, bateria) contêm
/// valores fora dos limites físicos ou operacionais permitidos.
class DadosTelemetriaInvalidosException implements Exception {
  final String mensagem;

  DadosTelemetriaInvalidosException(this.mensagem);

  @override
  String toString() => 'DadosTelemetriaInvalidosException: $mensagem';
}

/// Disparada quando uma busca de veículo por identificador não encontra
/// correspondência na frota cadastrada.
class VeiculoNaoEncontradoException implements Exception {
  final String mensagem;

  VeiculoNaoEncontradoException(this.mensagem);

  @override
  String toString() => 'VeiculoNaoEncontradoException: $mensagem';
}

/// Disparada quando os parâmetros de uma rota (distância, tempo, coordenadas)
/// são inconsistentes ou a rota solicitada não existe.
class RotaInvalidaException implements Exception {
  final String mensagem;

  RotaInvalidaException(this.mensagem);

  @override
  String toString() => 'RotaInvalidaException: $mensagem';
}
