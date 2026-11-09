import '../datasources/local_datasources.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../mixins/log_auditoria_mixin.dart';
import '../models/log_sincronizacao.dart';

/// Comportamento comum aos repositórios Offline-First:
/// verificação de conectividade (modo offline simulado) e histórico de sync.
abstract class RepositorioBase with LogAuditoriaMixin {
  final PreferenciasDatasource preferencias;
  final LogLocalDatasource logs;

  RepositorioBase({required this.preferencias, required this.logs});

  /// Lança [RedeIndisponivelException] se o app estiver em modo offline.
  void garantirOnline() {
    if (preferencias.modoOfflineSimulado) {
      throw RedeIndisponivelException('Modo offline ativado nas configurações.');
    }
  }

  /// Persiste uma entrada no histórico de sincronização. Falhas ao gravar o
  /// log nunca devem interromper o fluxo principal.
  Future<void> registrarHistorico({
    required String entidade,
    required String operacao,
    required bool sucesso,
    required String mensagem,
  }) async {
    registrarLog('[$entidade/$operacao] ${sucesso ? 'OK' : 'FALHA'} - $mensagem');
    try {
      await logs.registrar(LogSincronizacao(
        entidade: entidade,
        operacao: operacao,
        sucesso: sucesso,
        mensagem: mensagem,
      ));
    } catch (_) {
      // Histórico é auxiliar: ignoramos falhas de escrita.
    }
  }
}
