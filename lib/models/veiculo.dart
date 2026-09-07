import 'dispositivo_movel.dart';

/// Classe base intermediária que especializa DispositivoMovel para veículos
/// terrestres inteligentes conectados a frotas urbanas.
abstract class Veiculo extends DispositivoMovel {
  bool conectado;
  double velocidadeAtual;
  String? rotaAtualId;
  DateTime? ultimaAtualizacao;

  Veiculo({
    required super.id,
    required super.modelo,
    super.nivelBateria,
    this.conectado = true,
    this.velocidadeAtual = 0.0,
    this.rotaAtualId,
    this.ultimaAtualizacao,
  });

  /// Atualiza o status em tempo real do veículo.
  void atualizarEstado({
    required double velocidade,
    required double bateria,
    required bool statusConexao,
  }) {
    velocidadeAtual = velocidade;
    nivelBateria = bateria;
    conectado = statusConexao;
    ultimaAtualizacao = DateTime.now();
  }

  @override
  String toString() {
    final statusConexao = conectado ? 'ONLINE' : 'OFFLINE';
    final rotaInfo = rotaAtualId != null ? ' | Rota: $rotaAtualId' : '';
    return '${super.toString()} | Vel: ${velocidadeAtual.toStringAsFixed(0)} km/h | Status: $statusConexao$rotaInfo';
  }
}
