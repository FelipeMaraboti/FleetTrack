import 'package:fleet_track/datasources/local_datasources.dart';
import 'package:fleet_track/models/leitura_telemetria.dart';
import 'package:fleet_track/models/log_sincronizacao.dart';
import 'package:fleet_track/models/rota.dart';

// Implementações em memória dos contratos locais: permitem testar os
// repositórios e as telas sem SQLite/emulador.

class FakeRotaDatasource implements RotaLocalDatasource {
  final Map<String, Rota> storage = {};

  FakeRotaDatasource([List<Rota> iniciais = const []]) {
    for (final r in iniciais) {
      storage[r.id] = r;
    }
  }

  @override
  Future<void> salvarOuAtualizar(Rota rota) async => storage[rota.id] = rota;

  @override
  Future<List<Rota>> listarTodas() async => storage.values.where((r) => !r.excluido).toList();

  @override
  Future<Rota?> buscarPorId(String id) async => storage[id];

  @override
  Future<List<Rota>> listarPendentes() async => storage.values.where((r) => !r.sincronizado).toList();

  @override
  Future<void> removerPorId(String id) async => storage.remove(id);
}

class FakeLeituraDatasource implements LeituraLocalDatasource {
  final Map<String, LeituraTelemetria> storage = {};

  @override
  Future<void> salvarOuAtualizar(LeituraTelemetria l) async => storage[l.id] = l;

  @override
  Future<List<LeituraTelemetria>> listarTodas() async => storage.values.where((l) => !l.excluido).toList();

  @override
  Future<List<LeituraTelemetria>> listarPorRota(String rotaId) async =>
      storage.values.where((l) => l.rotaId == rotaId && !l.excluido).toList();

  @override
  Future<List<LeituraTelemetria>> listarPendentes() async => storage.values.where((l) => !l.sincronizado).toList();

  @override
  Future<void> removerPorId(String id) async => storage.remove(id);
}

class FakeLogDatasource implements LogLocalDatasource {
  final List<LogSincronizacao> logs = [];

  @override
  Future<void> registrar(LogSincronizacao log) async => logs.add(log);

  @override
  Future<List<LogSincronizacao>> listarRecentes({int limite = 50}) async => logs.reversed.take(limite).toList();

  @override
  Future<void> limpar() async => logs.clear();
}

LeituraTelemetria leituraExemplo({String id = 'LEI-01', String? rotaId, double bateria = 80}) {
  return LeituraTelemetria(
    id: id,
    veiculoId: 'VEI-001',
    rotaId: rotaId,
    latitude: -20.67,
    longitude: -41.31,
    velocidade: 50,
    bateria: bateria,
  );
}

Rota rotaExemplo({String id = 'ROTA-T1', bool sincronizado = false}) {
  return Rota(
    id: id,
    origem: 'Centro',
    destino: 'Aeroporto',
    distanciaKm: 20,
    tempoEstimadoMinutos: 30,
    sincronizado: sincronizado,
  );
}
