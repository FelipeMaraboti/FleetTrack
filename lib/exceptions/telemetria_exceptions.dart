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

// ===========================================================================
// AP2B - Exceções da camada de rede / sincronização Offline-First
// ===========================================================================

/// Disparada quando não há conectividade (socket, timeout, DNS ou modo
/// offline simulado). O repositório captura esta exceção e mantém o dado
/// salvo localmente como pendente.
class RedeIndisponivelException implements Exception {
  final String mensagem;

  RedeIndisponivelException(this.mensagem);

  @override
  String toString() => 'RedeIndisponivelException: $mensagem';
}

/// Disparada quando a API responde, porém com código HTTP fora da faixa 2xx
/// ou com payload inválido.
class SincronizacaoException implements Exception {
  final String mensagem;
  final int? statusCode;

  SincronizacaoException(this.mensagem, {this.statusCode});

  @override
  String toString() {
    final codigo = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'SincronizacaoException: $mensagem$codigo';
  }
}
