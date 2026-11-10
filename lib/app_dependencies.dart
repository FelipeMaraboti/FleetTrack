import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'datasources/local_datasources.dart';
import 'datasources/memoria_datasources.dart';
import 'datasources/preferencias_datasource.dart';
import 'datasources/remote_datasources.dart';
import 'datasources/sqlite_datasources.dart';
import 'models/carro_combustao.dart';
import 'models/carro_eletrico.dart';
import 'repositories/clima_repository.dart';
import 'repositories/rota_repository.dart';
import 'repositories/sincronizacao_repository.dart';
import 'repositories/telemetria_repository.dart';
import 'services/gerenciador_frota.dart';
import 'services/servico_telemetria.dart';

/// Container de dependências do app (composição manual, sem bibliotecas mágicas).
/// Em produção usa SQLite + HTTP real; nos testes recebe fakes em memória.
class AppDependencies {
  final RotaRepository rotas;
  final TelemetriaRepository telemetria;
  final ClimaRepository clima;
  final SincronizacaoRepository sincronizacao;
  final PreferenciasDatasource preferencias;
  final GerenciadorFrota frota;
  final ServicoTelemetria servicoTelemetria;

  /// Estado observável do modo offline (atualiza o banner em todas as telas).
  final ValueNotifier<bool> modoOffline;

  AppDependencies._({
    required this.rotas,
    required this.telemetria,
    required this.clima,
    required this.sincronizacao,
    required this.preferencias,
    required this.frota,
    required this.servicoTelemetria,
  }) : modoOffline = ValueNotifier(preferencias.modoOfflineSimulado);

  /// Monta o grafo de dependências a partir das fontes de dados informadas.
  factory AppDependencies.montar({
    required RotaLocalDatasource rotaLocal,
    required LeituraLocalDatasource leituraLocal,
    required LogLocalDatasource logLocal,
    required PreferenciasDatasource preferencias,
    required http.Client httpClient,
    Uri? apiEndpoint,
  }) {
    final api = FleetApiDatasource(client: httpClient, baseUrl: apiEndpoint);
    final rotas = RotaRepository(local: rotaLocal, api: api, preferencias: preferencias, logs: logLocal);
    final telemetria = TelemetriaRepository(local: leituraLocal, api: api, preferencias: preferencias, logs: logLocal);
    return AppDependencies._(
      rotas: rotas,
      telemetria: telemetria,
      clima: ClimaRepository(api: ClimaApiDatasource(client: httpClient), preferencias: preferencias, logs: logLocal),
      sincronizacao: SincronizacaoRepository(rotas: rotas, telemetria: telemetria, preferencias: preferencias, logs: logLocal),
      preferencias: preferencias,
      frota: criarFrotaInicial(),
      servicoTelemetria: ServicoTelemetria(),
    );
  }

  /// Configuração de produção: SQLite (sqflite) + shared_preferences + HTTP.
  static Future<AppDependencies> criarPadrao() async {
    // Web: o sqflite não roda no navegador, então os dados ficam em memória.
    if (kIsWeb) {
      return AppDependencies.montar(
        rotaLocal: MemoriaRotaDatasource(),
        leituraLocal: MemoriaLeituraDatasource(),
        logLocal: MemoriaLogDatasource(),
        preferencias: await SharedPrefsDatasource.carregar(),
        httpClient: http.Client(),
      );
    }
    final helper = DatabaseHelper();
    return AppDependencies.montar(
      rotaLocal: SqliteRotaDatasource(helper),
      leituraLocal: SqliteLeituraDatasource(helper),
      logLocal: SqliteLogDatasource(helper),
      preferencias: await SharedPrefsDatasource.carregar(),
      httpClient: http.Client(),
    );
  }

  Future<void> definirModoOffline(bool valor) async {
    await preferencias.salvarModoOfflineSimulado(valor);
    modoOffline.value = valor;
  }
}

/// Frota base herdada da AP1B (domínio em Dart puro reaproveitado).
GerenciadorFrota criarFrotaInicial() {
  final frota = GerenciadorFrota();
  frota.cadastrar(CarroEletrico(
    id: 'VEI-001',
    modelo: 'BYD Dolphin EV',
    capacidadeBateriaKwh: 60.0,
    nivelBateria: 85.0,
    rotaAtualId: 'ROTA-001',
  ));
  frota.cadastrar(CarroCombustao(
    id: 'VEI-002',
    modelo: 'Toyota Corolla 2.0',
    capacidadeTanqueLitros: 50.0,
    nivelCombustivelLitros: 35.0,
    nivelBateria: 18.0,
    rotaAtualId: 'ROTA-002',
  ));
  frota.cadastrar(CarroEletrico.economico(
    id: 'VEI-003',
    modelo: 'Renault Kwid E-Tech',
  )..rotaAtualId = 'ROTA-003');
  frota.cadastrar(CarroEletrico.fromMap({
    'id': 'VEI-004',
    'modelo': 'Volvo XC40 Recharge',
    'bateria': 92.0,
    'capacidadeBateriaKwh': 78.0,
    'conectado': true,
  }));
  return frota;
}

/// Disponibiliza as dependências para toda a árvore de widgets.
class AppScope extends InheritedWidget {
  final AppDependencies dependencies;

  const AppScope({super.key, required this.dependencies, required super.child});

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore de widgets.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => dependencies != oldWidget.dependencies;
}
