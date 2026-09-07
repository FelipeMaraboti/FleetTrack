import '../exceptions/telemetria_exceptions.dart';
import '../models/rota.dart';

/// Serviço responsável pelo gerenciamento, ativação e métricas das rotas urbanas.
class GerenciadorRotas {
  final List<Rota> _rotas = [];

  /// Cadastra uma nova rota na malha da frota.
  void cadastrar(Rota rota) {
    _rotas.add(rota);
  }

  /// Busca uma rota pelo seu identificador único.
  Rota buscarPorId(String id) {
    for (final rota in _rotas) {
      if (rota.id == id) return rota;
    }
    throw RotaInvalidaException('Rota com ID "$id" não encontrada.');
  }

  /// Ativa uma rota existente.
  void ativarRota(String id) {
    final rota = buscarPorId(id);
    rota.ativar();
  }

  /// Desativa uma rota existente.
  void desativarRota(String id) {
    final rota = buscarPorId(id);
    rota.desativar();
  }

  /// Retorna lista de rotas ativas utilizando o operador funcional .where().
  List<Rota> obterRotasAtivas() {
    return _rotas.where((rota) => rota.ativa).toList();
  }

  /// Calcula a soma total de quilometragem de todas as rotas ativas utilizando .fold().
  double calcularDistanciaTotalAtiva() {
    final rotasAtivas = obterRotasAtivas();
    return rotasAtivas.fold<double>(
      0.0,
      (acumulador, rota) => acumulador + rota.distanciaKm,
    );
  }

  /// Retorna um Set com os pontos únicos de origem e destino (demonstração de Set).
  Set<String> obterPontosAtendidos() {
    final Set<String> pontos = {};
    for (final rota in _rotas) {
      pontos.add(rota.origem);
      pontos.add(rota.destino);
    }
    return pontos;
  }

  /// Retorna uma cópia segura da lista de rotas utilizando Spread Operator (...).
  List<Rota> obterTodas() {
    return [..._rotas];
  }

  /// Quantidade total de rotas cadastradas.
  int get totalRotas => _rotas.length;
}
