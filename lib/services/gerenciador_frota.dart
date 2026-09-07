import '../exceptions/telemetria_exceptions.dart';
import '../models/veiculo.dart';

/// Serviço central de gerenciamento da frota de veículos conectados.
/// Demonstra extensivamente manipulações funcionais de coleções e Sound Null Safety.
class GerenciadorFrota {
  final List<Veiculo> _veiculos = [];

  /// Cadastra um veículo na frota.
  void cadastrar(Veiculo veiculo) {
    if (_veiculos.any((v) => v.id == veiculo.id)) {
      throw DadosTelemetriaInvalidosException(
        'Veículo com ID "${veiculo.id}" já está cadastrado na frota.',
      );
    }
    _veiculos.add(veiculo);
  }

  /// Remove um veículo da frota pelo ID.
  void remover(String id) {
    final index = _veiculos.indexWhere((v) => v.id == id);
    if (index == -1) {
      throw VeiculoNaoEncontradoException(
        'Impossível remover: Veículo "$id" não encontrado.',
      );
    }
    _veiculos.removeAt(index);
  }

  /// Busca um veículo pelo ID ou lança exceção customizada caso não exista.
  Veiculo buscarPorId(String id) {
    try {
      return _veiculos.firstWhere((v) => v.id == id);
    } catch (_) {
      throw VeiculoNaoEncontradoException(
        'Veículo com identificador "$id" não foi localizado na frota.',
      );
    }
  }

  /// Retorna uma cópia defensiva da lista de veículos usando Spread Operator (...).
  List<Veiculo> obterTodos() {
    return [..._veiculos];
  }

  /// Retorna veículos conectados via filtragem funcional .where().
  List<Veiculo> obterVeiculosConectados() {
    return _veiculos.where((v) => v.conectado).toList();
  }

  /// Retorna veículos com nível de bateria abaixo de um limiar usando .where().
  List<Veiculo> obterVeiculosComBateriaBaixa({double limite = 20.0}) {
    return _veiculos.where((v) => v.nivelBateria < limite).toList();
  }

  /// Calcula a média aritmética da bateria de todos os veículos usando .fold().
  double calcularMediaBateria() {
    if (_veiculos.isEmpty) return 0.0;
    final somaBateria = _veiculos.fold<double>(
      0.0,
      (acumulador, v) => acumulador + v.nivelBateria,
    );
    return somaBateria / _veiculos.length;
  }

  /// Calcula a velocidade média dos veículos em movimento/conectados usando .fold().
  double calcularVelocidadeMedia() {
    final conectados = obterVeiculosConectados();
    if (conectados.isEmpty) return 0.0;
    final somaVelocidade = conectados.fold<double>(
      0.0,
      (acumulador, v) => acumulador + v.velocidadeAtual,
    );
    return somaVelocidade / conectados.length;
  }

  /// Verifica se existe algum veículo em estado de bateria crítica usando .any().
  bool existeVeiculoCritico({double limiteCritico = 5.0}) {
    return _veiculos.any((v) => v.nivelBateria <= limiteCritico);
  }

  /// Verifica se TODOS os veículos estão aptos para operação (conectados e com bateria >= 20%) usando .every().
  bool todosAptosParaOperacao({double limiteMinimo = 20.0}) {
    if (_veiculos.isEmpty) return false;
    return _veiculos.every((v) => v.conectado && v.nivelBateria >= limiteMinimo);
  }

  /// Transforma a lista de veículos em uma lista de strings informativas usando .map().
  List<String> obterResumoModelos() {
    return _veiculos.map((v) => '${v.id} -> ${v.modelo} (${v.nivelBateria.toStringAsFixed(0)}%)').toList();
  }

  /// Mapeia a frota em um Map<String, Veiculo> indexado pelo ID do veículo (demonstração de Map).
  Map<String, Veiculo> mapearPorId() {
    return {for (final v in _veiculos) v.id: v};
  }

  /// Gera relatório detalhado utilizando Collection-For, Collection-If e Spread Operators (... e ...?).
  List<String> gerarRelatorioFormatado({List<String>? avisosAdicionais}) {
    return [
      '=== PAINEL DE MONITORAMENTO DE FROTA ===',
      for (final veiculo in _veiculos) ...[
        'Veículo ${veiculo.id}: ${veiculo.modelo} | Bateria: ${veiculo.nivelBateria.toStringAsFixed(1)}% | Status: ${veiculo.conectado ? "ONLINE" : "OFFLINE"}',
        if (veiculo.nivelBateria < 20.0)
          '   [ALERTA DE SISTEMA] Bateria baixa detectada no veículo ${veiculo.id}!',
        if (!veiculo.conectado)
          '   [ALERTA DE SISTEMA] Veículo ${veiculo.id} está desconectado da central telemetria!',
      ],
      ...?avisosAdicionais,
      '========================================',
    ];
  }

  /// Demonstração de Null Safety: operadores `?.`, `??` e `??=` no contexto de rotas de veículos.
  String obterDescricaoRotaOuPadrao(String veiculoId, {String? rotaPadrao}) {
    final veiculo = buscarPorId(veiculoId);
    String? rotaIdentificada = veiculo.rotaAtualId;
    rotaPadrao ??= 'ROTA-DEFAULT-CENTRO';
    return rotaIdentificada ?? 'Sem rota atribuída (Padrão: $rotaPadrao)';
  }

  /// Total de veículos na frota.
  int get totalVeiculos => _veiculos.length;
}
