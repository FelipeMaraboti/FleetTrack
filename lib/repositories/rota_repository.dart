import '../datasources/local_datasources.dart';
import '../datasources/remote_datasources.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/rota.dart';
import 'repositorio_base.dart';

/// Repositório Offline-First de rotas.
///
/// Regra de ouro: o SQLite é a fonte única da verdade. Toda escrita vai
/// primeiro para o banco local com `sincronizado = false`; só depois tentamos
/// a API. Se a rede falhar, o dado continua salvo e pendente.
class RotaRepository extends RepositorioBase {
  final RotaLocalDatasource _local;
  final FleetApiDatasource _api;

  RotaRepository({
    required RotaLocalDatasource local,
    required FleetApiDatasource api,
    required super.preferencias,
    required super.logs,
  })  : _local = local,
        _api = api;

  Future<List<Rota>> listar() => _local.listarTodas();

  Future<Rota?> buscarPorId(String id) => _local.buscarPorId(id);

  /// Cria ou edita uma rota (escrita resiliente).
  Future<Rota> salvar(Rota rota) async {
    final pendente = rota.copyWith(sincronizado: false, atualizadoEm: DateTime.now());
    await _local.salvarOuAtualizar(pendente);

    try {
      return await _enviar(pendente);
    } on RedeIndisponivelException catch (e) {
      await registrarHistorico(entidade: 'ROTA', operacao: 'POST', sucesso: false, mensagem: '${rota.id}: ${e.mensagem}');
    } on SincronizacaoException catch (e) {
      await registrarHistorico(entidade: 'ROTA', operacao: 'POST', sucesso: false, mensagem: '${rota.id}: $e');
    }
    return pendente;
  }

  /// Exclusão lógica + tentativa de DELETE remoto.
  /// Retorna `true` se a API confirmou a exclusão.
  Future<bool> excluir(String id) async {
    final rota = await _local.buscarPorId(id);
    if (rota == null) {
      throw RotaInvalidaException('Rota "$id" não encontrada para exclusão.');
    }
    final marcada = rota.copyWith(excluido: true, sincronizado: false);
    await _local.salvarOuAtualizar(marcada);

    try {
      await _enviar(marcada);
      return true;
    } on RedeIndisponivelException catch (e) {
      await registrarHistorico(entidade: 'ROTA', operacao: 'DELETE', sucesso: false, mensagem: '$id: ${e.mensagem}');
    } on SincronizacaoException catch (e) {
      await registrarHistorico(entidade: 'ROTA', operacao: 'DELETE', sucesso: false, mensagem: '$id: $e');
    }
    return false;
  }

  /// Reenvia todas as pendências. Retorna quantas foram confirmadas.
  /// Se a rede cair no meio do processo, a exceção é propagada (rethrow)
  /// para o orquestrador de sincronização exibir o aviso ao usuário.
  Future<int> sincronizarPendentes() async {
    final pendentes = await _local.listarPendentes();
    var enviados = 0;
    for (final rota in pendentes) {
      try {
        await _enviar(rota);
        enviados++;
      } on SincronizacaoException catch (e) {
        // Erro de um item específico (ex.: HTTP 500): segue para o próximo.
        await registrarHistorico(entidade: 'ROTA', operacao: rota.excluido ? 'DELETE' : 'POST', sucesso: false, mensagem: '${rota.id}: $e');
      } on RedeIndisponivelException catch (e) {
        await registrarHistorico(entidade: 'ROTA', operacao: 'SYNC', sucesso: false, mensagem: e.mensagem);
        rethrow;
      }
    }
    return enviados;
  }

  Future<int> contarPendentes() async => (await _local.listarPendentes()).length;

  /// Envia um único item para a API e atualiza o estado local.
  Future<Rota> _enviar(Rota rota) async {
    garantirOnline();
    if (rota.excluido) {
      await _api.excluir(rota.id);
      await _local.removerPorId(rota.id);
      await registrarHistorico(entidade: 'ROTA', operacao: 'DELETE', sucesso: true, mensagem: '${rota.id} excluída no servidor.');
      return rota;
    }
    await _api.enviarRota(rota);
    final confirmada = rota.copyWith(sincronizado: true);
    await _local.salvarOuAtualizar(confirmada);
    await registrarHistorico(entidade: 'ROTA', operacao: 'POST', sucesso: true, mensagem: '${rota.id} sincronizada.');
    return confirmada;
  }
}
