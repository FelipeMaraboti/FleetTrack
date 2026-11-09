import '../datasources/local_datasources.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/log_sincronizacao.dart';
import 'rota_repository.dart';
import 'telemetria_repository.dart';

/// Resultado de um ciclo completo de sincronização.
class ResumoSincronizacao {
  final int rotasEnviadas;
  final int leiturasEnviadas;
  final bool online;
  final String? erro;

  const ResumoSincronizacao({
    this.rotasEnviadas = 0,
    this.leiturasEnviadas = 0,
    this.online = true,
    this.erro,
  });

  int get total => rotasEnviadas + leiturasEnviadas;

  String get mensagem {
    if (!online) return 'Sem conexão: dados mantidos localmente (${erro ?? ''}).';
    if (total == 0) return 'Tudo sincronizado. Nenhuma pendência.';
    return 'Sincronizados: $rotasEnviadas rota(s) e $leiturasEnviadas leitura(s).';
  }
}

/// Orquestra a sincronização de todas as entidades e expõe o diagnóstico.
class SincronizacaoRepository {
  final RotaRepository _rotas;
  final TelemetriaRepository _telemetria;
  final PreferenciasDatasource _prefs;
  final LogLocalDatasource _logs;

  SincronizacaoRepository({
    required RotaRepository rotas,
    required TelemetriaRepository telemetria,
    required PreferenciasDatasource preferencias,
    required LogLocalDatasource logs,
  })  : _rotas = rotas,
        _telemetria = telemetria,
        _prefs = preferencias,
        _logs = logs;

  Future<ResumoSincronizacao> sincronizarTudo() async {
    try {
      final rotas = await _rotas.sincronizarPendentes();
      final leituras = await _telemetria.sincronizarLote();
      await _prefs.salvarUltimaSincronizacao(DateTime.now());
      return ResumoSincronizacao(rotasEnviadas: rotas, leiturasEnviadas: leituras);
    } on RedeIndisponivelException catch (e) {
      return ResumoSincronizacao(online: false, erro: e.mensagem);
    }
  }

  Future<int> contarPendentes() async =>
      await _rotas.contarPendentes() + await _telemetria.contarPendentes();

  DateTime? get ultimaSincronizacao => _prefs.ultimaSincronizacao;

  Future<List<LogSincronizacao>> historico() => _logs.listarRecentes();

  Future<void> limparHistorico() => _logs.limpar();
}
