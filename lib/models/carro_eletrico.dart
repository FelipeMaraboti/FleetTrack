import '../exceptions/telemetria_exceptions.dart';
import 'veiculo.dart';

/// Representa um veículo 100% elétrico (EV) integrado à frota.
class CarroEletrico extends Veiculo {
  final double capacidadeBateriaKwh;
  double autonomiaRestanteKm;

  /// Construtor gerativo padrão com argumentos nomeados obrigatórios e opcionais.
  CarroEletrico({
    required super.id,
    required super.modelo,
    super.nivelBateria,
    super.conectado,
    super.velocidadeAtual,
    super.rotaAtualId,
    super.ultimaAtualizacao,
    this.capacidadeBateriaKwh = 60.0,
    double? autonomiaInicialKm,
  }) : autonomiaRestanteKm = autonomiaInicialKm ??
            (capacidadeBateriaKwh * 6.5 * (nivelBateria / 100));

  /// Construtor nomeado para configuração de veículo em Modo Econômico.
  /// Define capacidade padrão otimizada e parametrização para baixo consumo urbano.
  CarroEletrico.economico({
    required String id,
    required String modelo,
    double nivelBateria = 100.0,
  })  : capacidadeBateriaKwh = 45.0,
        autonomiaRestanteKm = 45.0 * 7.0 * (nivelBateria / 100),
        super(
          id: id,
          modelo: '$modelo [ECO]',
          nivelBateria: nivelBateria,
          conectado: true,
          velocidadeAtual: 0.0,
        );

  /// Construtor factory para instanciação segura a partir de Map (ex: JSON/API).
  /// Aplica Sound Null Safety sem operadores forçados (!), validando entradas.
  factory CarroEletrico.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'];
    final rawModelo = map['modelo'];

    if (rawId == null || rawId is! String || rawId.trim().isEmpty) {
      throw DadosTelemetriaInvalidosException(
        'Falha ao instanciar CarroEletrico: Campo "id" é obrigatório e deve ser String válida.',
      );
    }

    if (rawModelo == null || rawModelo is! String || rawModelo.trim().isEmpty) {
      throw DadosTelemetriaInvalidosException(
        'Falha ao instanciar CarroEletrico: Campo "modelo" é obrigatório e deve ser String válida.',
      );
    }

    final rawBateria = map['bateria'];
    final double bateria = (rawBateria is num) ? rawBateria.toDouble() : 100.0;

    final rawCapacidade = map['capacidadeBateriaKwh'];
    final double capacidade =
        (rawCapacidade is num) ? rawCapacidade.toDouble() : 60.0;

    final rawConectado = map['conectado'];
    final bool conectado = (rawConectado is bool) ? rawConectado : true;

    final rawVelocidade = map['velocidade'];
    final double velocidade =
        (rawVelocidade is num) ? rawVelocidade.toDouble() : 0.0;

    final String? rotaId = map['rotaAtualId'] as String?;

    return CarroEletrico(
      id: rawId,
      modelo: rawModelo,
      nivelBateria: bateria,
      capacidadeBateriaKwh: capacidade,
      conectado: conectado,
      velocidadeAtual: velocidade,
      rotaAtualId: rotaId,
    );
  }

  /// Processamento polimórfico de carga de trabalho para veículos elétricos.
  /// Reduz o nível da bateria de acordo com a intensidade da aceleração/terreno
  /// e recalcula a autonomia estimada em km.
  @override
  void processarCargaTrabalho(double intensidade) {
    if (intensidade <= 0) return;

    final consumoPercentual =
        (intensidade * 12.0) / (capacidadeBateriaKwh / 50.0);
    final novoNivel = (nivelBateria - consumoPercentual).clamp(0.0, 100.0);

    nivelBateria = novoNivel;
    autonomiaRestanteKm = (capacidadeBateriaKwh * 6.5) * (nivelBateria / 100);
  }

  @override
  String toString() {
    return '[ELÉTRICO] ${super.toString()} | Autonomia: ${autonomiaRestanteKm.toStringAsFixed(1)} km (${capacidadeBateriaKwh.toStringAsFixed(0)} kWh)';
  }
}
