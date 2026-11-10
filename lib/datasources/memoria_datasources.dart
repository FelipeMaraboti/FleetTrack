import '../models/leitura_telemetria.dart';
import '../models/log_sincronizacao.dart';
import '../models/rota.dart';
import 'local_datasources.dart';

// Implementações em memória dos contratos locais.
// Usadas na versão Web (o sqflite não roda no navegador): os dados duram
// enquanto a aba estiver aberta.

class MemoriaRotaDatasource implements RotaLocalDatasource {
  final Map<String, Rota> _dados = {};

  MemoriaRotaDatasource([List<Rota> iniciais = const []]) {
    for (final r in iniciais) {
      _dados[r.id] = r;
    }
  }

  @override
  Future<void> salvarOuAtualizar(Rota rota) async => _dados[rota.id] = rota;

  @override
  Future<List<Rota>> listarTodas() async => _dados.values.where((r) => !r.excluido).toList();

  @override
  Future<Rota?> buscarPorId(String id) async => _dados[id];

  @override
  Future<List<Rota>> listarPendentes() async => _dados.values.where((r) => !r.sincronizado).toList();

  @override
  Future<void> removerPorId(String id) async => _dados.remove(id);
}

class MemoriaLeituraDatasource implements LeituraLocalDatasource {
  final Map<String, LeituraTelemetria> _dados = {};

  @override
  Future<void> salvarOuAtualizar(LeituraTelemetria l) async => _dados[l.id] = l;

  @override
  Future<List<LeituraTelemetria>> listarTodas() async => _dados.values.where((l) => !l.excluido).toList();

  @override
  Future<List<LeituraTelemetria>> listarPorRota(String rotaId) async =>
      _dados.values.where((l) => l.rotaId == rotaId && !l.excluido).toList();

  @override
  Future<List<LeituraTelemetria>> listarPendentes() async => _dados.values.where((l) => !l.sincronizado).toList();

  @override
  Future<void> removerPorId(String id) async => _dados.remove(id);
}

class MemoriaLogDatasource implements LogLocalDatasource {
  final List<LogSincronizacao> _logs = [];

  @override
  Future<void> registrar(LogSincronizacao log) async => _logs.add(log);

  @override
  Future<List<LogSincronizacao>> listarRecentes({int limite = 50}) async => _logs.reversed.take(limite).toList();

  @override
  Future<void> limpar() async => _logs.clear();
}
