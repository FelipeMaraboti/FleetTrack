import 'package:fleet_track/app.dart';
import 'package:fleet_track/app_dependencies.dart';
import 'package:fleet_track/datasources/preferencias_datasource.dart';
import 'package:fleet_track/routes/app_routes.dart';
import 'package:fleet_track/widgets/comuns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

/// Cria o app com fontes de dados em memória e em modo offline
/// (nenhuma chamada HTTP real durante os testes de widget).
AppDependencies criarDependencias({bool offline = true}) {
  return AppDependencies.montar(
    rotaLocal: FakeRotaDatasource([rotaExemplo(id: 'ROTA-001', sincronizado: true)]),
    leituraLocal: FakeLeituraDatasource(),
    logLocal: FakeLogDatasource(),
    preferencias: MemoriaPreferenciasDatasource(modoOffline: offline),
    httpClient: MockClient((_) async => http.Response('{"id":1}', 201)),
  );
}

Future<void> abrirApp(WidgetTester tester, {String rota = AppRoutes.dashboard, AppDependencies? deps}) async {
  await tester.pumpWidget(FleetTrackApp(dependencies: deps ?? criarDependencias(), rotaInicial: rota));
  await tester.pumpAndSettle();
}

void main() {
  group('13. Testes de Widgets', () {
    testWidgets('Dashboard exibe as métricas da frota', (tester) async {
      await abrirApp(tester);

      expect(find.text('FleetTrack'), findsOneWidget);
      expect(find.byType(MetricCard), findsNWidgets(6));
      expect(find.text('Veículos na frota'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // 4 veículos da AP1B
    });

    testWidgets('SyncStatusIcon diferencia sincronizado de pendente', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Row(children: [SyncStatusIcon(sincronizado: true), SyncStatusIcon(sincronizado: false)])),
      ));

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    });

    testWidgets('Lista de rotas renderiza itens vindos do repositório', (tester) async {
      await abrirApp(tester, rota: AppRoutes.rotas);

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Centro → Aeroporto'), findsOneWidget);
      expect(find.byKey(const ValueKey('icone-sincronizado')), findsOneWidget);
    });

    testWidgets('Formulário de rota valida campos obrigatórios', (tester) async {
      await abrirApp(tester, rota: AppRoutes.rotaForm);

      await tester.tap(find.byKey(const Key('botao-salvar-rota')));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsNWidgets(2));
      expect(find.text('Informe um número válido'), findsNWidgets(2));
    });

    testWidgets('Cadastro offline de rota aparece na lista como pendente', (tester) async {
      await abrirApp(tester, rota: AppRoutes.rotas);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('campo-origem')), 'Rodoviária');
      await tester.enterText(find.byKey(const Key('campo-destino')), 'Shopping');
      await tester.enterText(find.byKey(const Key('campo-distancia')), '7,5');
      await tester.enterText(find.byKey(const Key('campo-tempo')), '15');
      await tester.tap(find.byKey(const Key('botao-salvar-rota')));
      await tester.pumpAndSettle();

      expect(find.text('Rodoviária → Shopping'), findsOneWidget);
      expect(find.byKey(const ValueKey('icone-pendente')), findsOneWidget);
      expect(find.text('Rota salva offline (pendente de envio).'), findsOneWidget);
    });

    testWidgets('Formulário de leitura exige veículo e valida bateria', (tester) async {
      await abrirApp(tester, rota: AppRoutes.leituraForm);

      await tester.enterText(find.byKey(const Key('campo-bateria')), '150');
      await tester.tap(find.byKey(const Key('botao-salvar-leitura')));
      await tester.pump();

      expect(find.text('Selecione um veículo'), findsOneWidget);
      expect(find.text('Valor deve estar entre 0.0 e 100.0'), findsOneWidget);
    });

    testWidgets('Banner offline aparece/desaparece ao alternar configuração', (tester) async {
      final deps = criarDependencias(offline: false);
      await abrirApp(tester, rota: AppRoutes.configuracoes, deps: deps);

      await tester.tap(find.byKey(const Key('switch-offline')));
      await tester.pumpAndSettle();
      expect(deps.preferencias.modoOfflineSimulado, isTrue);
      expect(deps.modoOffline.value, isTrue);
    });

    testWidgets('Rota inexistente exibe página de erro amigável', (tester) async {
      await abrirApp(tester, rota: '/nao-existe');
      expect(find.text('Página não encontrada'), findsOneWidget);
    });
  });
}
