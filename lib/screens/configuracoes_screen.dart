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
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: deps.modoOffline,
            builder: (context, offline, _) => SwitchListTile(
              key: const Key('switch-offline'),
              secondary: Icon(offline ? Icons.wifi_off : Icons.wifi),
              title: const Text('Modo offline (simular queda de rede)'),
              subtitle: const Text('Bloqueia chamadas HTTP: tudo é gravado só no SQLite.'),
              value: offline,
              onChanged: (valor) async {
                await deps.definirModoOffline(valor);
                if (context.mounted) {
                  mostrarMensagem(context, valor ? 'Modo offline ativado.' : 'Modo online ativado. Sincronize as pendências.');
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API de telemetria (POST/DELETE)'),
            subtitle: Text('${FleetApiDatasource.endpointPadrao}/posts'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud),
            title: Text('API de clima (GET)'),
            subtitle: Text('https://api.open-meteo.com/v1/forecast'),
          ),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Banco local'),
            subtitle: Text('SQLite (sqflite) • fleet_track.db'),
          ),
        ],
      ),
    );
  }
}
