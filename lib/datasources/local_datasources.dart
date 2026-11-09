import '../models/leitura_telemetria.dart';
import '../models/log_sincronizacao.dart';
import '../models/rota.dart';

// ============================================================================
// Contratos das fontes de dados locais.
// Permitem inversão de dependência: em produção usamos SQLite/SharedPreferences
// e nos testes usamos implementações em memória (sem emulador).
// ============================================================================

abstract class RotaLocalDatasource {
  Future<void> salvarOuAtualizar(Rota rota);

  /// Lista apenas rotas visíveis (não excluídas logicamente).
  Future<List<Rota>> listarTodas();

  Future<Rota?> buscarPorId(String id);

  /// Rotas com `sincronizado = 0` (inclui exclusões lógicas pendentes).
  Future<List<Rota>> listarPendentes();

  /// Remoção física (após o DELETE ser confirmado pela API).
  Future<void> removerPorId(String id);
}

abstract class LeituraLocalDatasource {
  Future<void> salvarOuAtualizar(LeituraTelemetria leitura);

  Future<List<LeituraTelemetria>> listarTodas();

  Future<List<LeituraTelemetria>> listarPorRota(String rotaId);

  Future<List<LeituraTelemetria>> listarPendentes();

  Future<void> removerPorId(String id);
}

abstract class LogLocalDatasource {
  Future<void> registrar(LogSincronizacao log);

  Future<List<LogSincronizacao>> listarRecentes({int limite = 50});

  Future<void> limpar();
}

/// Preferências simples (chave/valor) - implementadas com shared_preferences.
abstract class PreferenciasDatasource {
  DateTime? get ultimaSincronizacao;
  Future<void> salvarUltimaSincronizacao(DateTime dataHora);

  /// Quando `true`, os repositórios não tentam acessar a rede
  /// (útil para demonstrar o modo avião na defesa técnica).
  bool get modoOfflineSimulado;
  Future<void> salvarModoOfflineSimulado(bool valor);

  String? lerCache(String chave);
  Future<void> salvarCache(String chave, String valor);
}
