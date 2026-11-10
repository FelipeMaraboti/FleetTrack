import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../datasources/remote_datasources.dart';
import '../widgets/comuns.dart';

/// Tela 11 - Configurações (modo offline simulado para demonstração).
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const SecaoTitulo('Rede'),
          ValueListenableBuilder<bool>(
            valueListenable: deps.modoOffline,
            builder: (context, offline, _) => SwitchLinha(
              key: const Key('switch-offline'),
              icone: offline ? Icons.wifi_off : Icons.wifi,
              titulo: 'Modo offline (simular queda de rede)',
              subtitulo: 'Bloqueia chamadas HTTP: tudo é gravado só no SQLite.',
              valor: offline,
              onChanged: (valor) async {
                await deps.definirModoOffline(valor);
                if (context.mounted) {
                  mostrarMensagem(context, valor ? 'Modo offline ativado.' : 'Modo online ativado. Sincronize as pendências.');
                }
              },
            ),
          ),
          const SecaoTitulo('Integrações'),
          Bloco(children: [
            InfoLinha(icone: Icons.api, rotulo: 'API de telemetria (POST/DELETE)', valor: '${FleetApiDatasource.endpointPadrao}/posts'),
            const InfoLinha(icone: Icons.cloud_outlined, rotulo: 'API de clima (GET)', valor: 'https://api.open-meteo.com/v1/forecast'),
            const InfoLinha(icone: Icons.storage, rotulo: 'Banco local', valor: 'SQLite (sqflite) · fleet_track.db'),
          ]),
        ],
      ),
    );
  }
}
