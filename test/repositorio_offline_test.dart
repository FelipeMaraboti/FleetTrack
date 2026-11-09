import 'dart:convert';

import 'package:fleet_track/datasources/preferencias_datasource.dart';
import 'package:fleet_track/datasources/remote_datasources.dart';
import 'package:fleet_track/exceptions/telemetria_exceptions.dart';
import 'package:fleet_track/repositories/clima_repository.dart';
import 'package:fleet_track/repositories/rota_repository.dart';
import 'package:fleet_track/repositories/sincronizacao_repository.dart';
import 'package:fleet_track/repositories/telemetria_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

/// Monta todos os repositórios sobre fakes em memória e um MockClient.
class Cenario {
  final rotasLocal = FakeRotaDatasource();
  final leiturasLocal = FakeLeituraDatasource();
  final logs = FakeLogDatasource();
  final prefs = MemoriaPreferenciasDatasource();
  final List<http.Request> requisicoes = [];
  late final RotaRepository rotas;
  late final TelemetriaRepository telemetria;
  late final SincronizacaoRepository sync;
  late final ClimaRepository clima;

  Cenario(Future<http.Response> Function(http.Request) handler, {Duration timeout = const Duration(seconds: 8)}) {
    final client = MockClient((req) {
      requisicoes.add(req);
      return handler(req);
    });
    final api = FleetApiDatasource(client: client, timeout: timeout);
    rotas = RotaRepository(local: rotasLocal, api: api, preferencias: prefs, logs: logs);
    telemetria = TelemetriaRepository(local: leiturasLocal, api: api, preferencias: prefs, logs: logs);
    sync = SincronizacaoRepository(rotas: rotas, telemetria: telemetria, preferencias: prefs, logs: logs);
    clima = ClimaRepository(api: ClimaApiDatasource(client: client), preferencias: prefs, logs: logs);
  }
}

Future<http.Response> ok201(http.Request _) async => http.Response('{"id": 101}', 201);
Future<http.Response> erro500(http.Request _) async => http.Response('Erro', 500);
Future<http.Response> semRede(http.Request _) async => throw http.ClientException('Failed host lookup');

void main() {
  group('10. Repositório de Telemetria - Offline-First', () {
    test('Deve manter registro salvo localmente quando API retornar erro 500', () async {
      final c = Cenario(erro500);
      final resultado = await c.telemetria.registrar(leituraExemplo());

      expect(resultado.sincronizado, isFalse);
      expect(c.leiturasLocal.storage.length, 1);
      expect(c.leiturasLocal.storage['LEI-01']!.sincronizado, isFalse);
    });

    test('Deve marcar como sincronizado quando API retornar 201', () async {
      final c = Cenario(ok201);
      final resultado = await c.telemetria.registrar(leituraExemplo());

      expect(resultado.sincronizado, isTrue);
      expect(c.leiturasLocal.storage['LEI-01']!.sincronizado, isTrue);
      expect(c.requisicoes.single.method, 'POST');
    });

    test('Falha de socket/DNS não quebra o app e mantém pendência', () async {
      final c = Cenario(semRede);
      final resultado = await c.telemetria.registrar(leituraExemplo());

      expect(resultado.sincronizado, isFalse);
      expect(await c.telemetria.contarPendentes(), 1);
      expect(c.logs.logs.last.sucesso, isFalse);
    });

    test('Modo offline simulado não dispara nenhuma requisição HTTP', () async {
      final c = Cenario(ok201);
      await c.prefs.salvarModoOfflineSimulado(true);
      await c.telemetria.registrar(leituraExemplo());

      expect(c.requisicoes, isEmpty);
      expect(await c.telemetria.contarPendentes(), 1);
    });

    test('sincronizarLote envia todas as pendências em um único POST', () async {
      final c = Cenario(ok201);
      await c.prefs.salvarModoOfflineSimulado(true);
      await c.telemetria.registrar(leituraExemplo(id: 'A'));
      await c.telemetria.registrar(leituraExemplo(id: 'B'));
      await c.telemetria.registrar(leituraExemplo(id: 'C'));
      await c.prefs.salvarModoOfflineSimulado(false);

      final enviados = await c.telemetria.sincronizarLote();

      expect(enviados, 3);
      expect(c.requisicoes.length, 1);
      final corpo = jsonDecode(c.requisicoes.single.body) as Map<String, dynamic>;
      expect(corpo['quantidade'], 3);
      expect(await c.telemetria.contarPendentes(), 0);
    });

    test('Timeout configurado é convertido em RedeIndisponivelException', () async {
      final c = Cenario(
        (_) => Future.delayed(const Duration(milliseconds: 200), () => http.Response('{}', 201)),
        timeout: const Duration(milliseconds: 20),
      );
      final api = FleetApiDatasource(
        client: MockClient((_) => Future.delayed(const Duration(milliseconds: 200), () => http.Response('{}', 201))),
        timeout: const Duration(milliseconds: 20),
      );

      expect(() => api.enviarLoteLeituras([leituraExemplo()]), throwsA(isA<RedeIndisponivelException>()));
      final r = await c.telemetria.registrar(leituraExemplo());
      expect(r.sincronizado, isFalse);
    });
  });

  group('11. Repositório de Rotas - CRUD Offline-First', () {
    test('Rota criada offline é enviada depois em sincronizarPendentes', () async {
      final c = Cenario(ok201);
      await c.prefs.salvarModoOfflineSimulado(true);
      final salva = await c.rotas.salvar(rotaExemplo());
      expect(salva.sincronizado, isFalse);

      await c.prefs.salvarModoOfflineSimulado(false);
      final enviados = await c.rotas.sincronizarPendentes();

      expect(enviados, 1);
      expect(c.rotasLocal.storage['ROTA-T1']!.sincronizado, isTrue);
    });

    test('Exclusão offline é lógica e vira DELETE na próxima sincronização', () async {
      final c = Cenario(ok201);
      c.rotasLocal.storage['ROTA-T1'] = rotaExemplo(sincronizado: true);
      await c.prefs.salvarModoOfflineSimulado(true);

      final confirmado = await c.rotas.excluir('ROTA-T1');
      expect(confirmado, isFalse);
      expect(await c.rotas.listar(), isEmpty); // some da UI
      expect(c.rotasLocal.storage.containsKey('ROTA-T1'), isTrue); // mas continua no banco

      await c.prefs.salvarModoOfflineSimulado(false);
      await c.rotas.sincronizarPendentes();

      expect(c.requisicoes.single.method, 'DELETE');
      expect(c.rotasLocal.storage.containsKey('ROTA-T1'), isFalse);
    });

    test('Excluir rota inexistente lança RotaInvalidaException', () async {
      final c = Cenario(ok201);
      expect(() => c.rotas.excluir('NAO-EXISTE'), throwsA(isA<RotaInvalidaException>()));
    });

    test('sincronizarPendentes propaga (rethrow) RedeIndisponivelException', () async {
      final c = Cenario(semRede);
      c.rotasLocal.storage['ROTA-T1'] = rotaExemplo();
      expect(() => c.rotas.sincronizarPendentes(), throwsA(isA<RedeIndisponivelException>()));
    });

    test('Erro HTTP 500 em sincronizarPendentes mantém item pendente sem lançar', () async {
      final c = Cenario(erro500);
      c.rotasLocal.storage['ROTA-T1'] = rotaExemplo();
      final enviados = await c.rotas.sincronizarPendentes();
      expect(enviados, 0);
      expect(await c.rotas.contarPendentes(), 1);
    });
  });

  group('12. Orquestração da sincronização e clima', () {
    test('sincronizarTudo offline retorna online=false e não grava data', () async {
      final c = Cenario(semRede);
      c.rotasLocal.storage['ROTA-T1'] = rotaExemplo();
      final resumo = await c.sync.sincronizarTudo();

      expect(resumo.online, isFalse);
      expect(c.prefs.ultimaSincronizacao, isNull);
      expect(await c.sync.contarPendentes(), 1);
    });

    test('sincronizarTudo online envia tudo e registra a data da última sync', () async {
      final c = Cenario(ok201);
      c.rotasLocal.storage['ROTA-T1'] = rotaExemplo();
      c.leiturasLocal.storage['LEI-01'] = leituraExemplo();

      final resumo = await c.sync.sincronizarTudo();

      expect(resumo.rotasEnviadas, 1);
      expect(resumo.leiturasEnviadas, 1);
      expect(c.prefs.ultimaSincronizacao, isNotNull);
      expect(await c.sync.contarPendentes(), 0);
    });

    test('ClimaRepository usa o cache local quando fica offline', () async {
      final c = Cenario((_) async => http.Response(
            jsonEncode({'current_weather': {'temperature': 25.0, 'windspeed': 5.0, 'weathercode': 1, 'time': '2026-11-09T10:00'}}),
            200,
          ));
      final online = await c.clima.obterClima(-20.84, -41.11);
      expect(online.doCache, isFalse);

      await c.prefs.salvarModoOfflineSimulado(true);
      final offline = await c.clima.obterClima(-20.84, -41.11);
      expect(offline.doCache, isTrue);
      expect(offline.temperatura, 25.0);
    });

    test('ClimaRepository sem cache e sem rede propaga RedeIndisponivelException', () async {
      final c = Cenario(semRede);
      expect(() => c.clima.obterClima(0, 0), throwsA(isA<RedeIndisponivelException>()));
    });
  });
}
