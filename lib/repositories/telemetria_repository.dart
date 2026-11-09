import '../datasources/local_datasources.dart';
import '../datasources/remote_datasources.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/leitura_telemetria.dart';
import 'repositorio_base.dart';

/// Repositório Offline-First das leituras de telemetria.
/// As leituras pendentes são enviadas em LOTE (um único POST).
class TelemetriaRepository extends RepositorioBase {
  final LeituraLocalDatasource _local;
  final FleetApiDatasource _api;

  TelemetriaRepository({
    required LeituraLocalDatasource local,
    required FleetApiDatasource api,
    required super.preferencias,
    required super.logs,
  })  : _local = local,
        _api = api;

  Future<List<LeituraTelemetria>> listar() => _local.listarTodas();

  Future<List<LeituraTelemetria>> listarPorRota(String rotaId) => _local.listarPorRota(rotaId);

  /// Grava imediatamente no banco local e tenta sincronizar em seguida.
  Future<LeituraTelemetria> registrar(LeituraTelemetria nova) async {
    final pendente = nova.copyWith(sincronizado: false);
    await _local.salvarOuAtualizar(pendente);

    try {
      garantirOnline();
      await _api.enviarLoteLeituras([pendente]);
      final confirmada = pendente.copyWith(sincronizado: true);
      await _local.salvarOuAtualizar(confirmada);
      await registrarHistorico(entidade: 'LEITURA', operacao: 'POST', sucesso: true, mensagem: '${nova.id} enviada.');
      return confirmada;
    } on RedeIndisponivelException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'POST', sucesso: false, mensagem: '${nova.id}: ${e.mensagem}');
    } on SincronizacaoException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'POST', sucesso: false, mensagem: '${nova.id}: $e');
    }
    return pendente;
  }

  /// Exclusão lógica + DELETE remoto. Retorna `true` se confirmada na API.
  Future<bool> excluir(LeituraTelemetria leitura) async {
    final marcada = leitura.copyWith(excluido: true, sincronizado: false);
    await _local.salvarOuAtualizar(marcada);
    try {
      garantirOnline();
      await _api.excluir(leitura.id);
      await _local.removerPorId(leitura.id);
      await registrarHistorico(entidade: 'LEITURA', operacao: 'DELETE', sucesso: true, mensagem: '${leitura.id} excluída.');
      return true;
    } on RedeIndisponivelException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'DELETE', sucesso: false, mensagem: e.mensagem);
    } on SincronizacaoException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'DELETE', sucesso: false, mensagem: '$e');
    }
    return false;
  }

  /// Envia todas as leituras pendentes em um único lote e processa exclusões.
  /// Retorna a quantidade de registros confirmados.
  Future<int> sincronizarLote() async {
    final pendentes = await _local.listarPendentes();
    if (pendentes.isEmpty) return 0;

    final exclusoes = pendentes.where((l) => l.excluido).toList();
    final envios = pendentes.where((l) => !l.excluido).toList();
    var confirmados = 0;

    try {
      garantirOnline();
      for (final leitura in exclusoes) {
        await _api.excluir(leitura.id);
        await _local.removerPorId(leitura.id);
        confirmados++;
      }
      if (envios.isNotEmpty) {
        await _api.enviarLoteLeituras(envios);
        for (final leitura in envios) {
          await _local.salvarOuAtualizar(leitura.copyWith(sincronizado: true));
        }
        confirmados += envios.length;
      }
      await registrarHistorico(entidade: 'LEITURA', operacao: 'POST', sucesso: true, mensagem: 'Lote com $confirmados registro(s) sincronizado.');
      return confirmados;
    } on SincronizacaoException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'POST', sucesso: false, mensagem: 'Lote recusado: $e');
      return confirmados;
    } on RedeIndisponivelException catch (e) {
      await registrarHistorico(entidade: 'LEITURA', operacao: 'SYNC', sucesso: false, mensagem: e.mensagem);
      rethrow;
    }
  }

  Future<int> contarPendentes() async => (await _local.listarPendentes()).length;
}
