import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../routes/app_routes.dart';
import '../widgets/comuns.dart';

/// Tela 1 - Painel principal com métricas da frota e status de sincronização.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalRotas = 0;
  int _totalLeituras = 0;
  int _pendentes = 0;
  bool _carregando = true;
  bool _sincronizando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  /// Leitura imediata local: os números vêm do SQLite, nunca da rede.
  Future<void> _carregar() async {
    final deps = AppScope.of(context);
    final rotas = await deps.rotas.listar();
    final leituras = await deps.telemetria.listar();
    final pendentes = await deps.sincronizacao.contarPendentes();
    if (!mounted) return;
    setState(() {
      _totalRotas = rotas.length;
      _totalLeituras = leituras.length;
      _pendentes = pendentes;
      _carregando = false;
    });
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    final resumo = await AppScope.of(context).sincronizacao.sincronizarTudo();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    mostrarMensagem(context, resumo.mensagem, erro: !resumo.online);
    _carregar();
  }

  Future<void> _abrir(String rota) async {
    await Navigator.pushNamed(context, rota);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final frota = AppScope.of(context).frota;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FleetTrack'),
        actions: [
          IconButton(
            key: const Key('botao-sincronizar'),
            tooltip: 'Sincronizar agora',
            onPressed: _sincronizando ? null : _sincronizar,
            icon: _sincronizando
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Badge(
                    isLabelVisible: _pendentes > 0,
                    label: Text('$_pendentes'),
                    child: const Icon(Icons.sync),
                  ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Layout responsivo: 2 colunas no celular, 4 em telas largas.
                        final colunas = constraints.maxWidth > 700 ? 4 : 2;
                        return GridView.count(
                          padding: const EdgeInsets.all(12),
                          crossAxisCount: colunas,
                          childAspectRatio: 1.4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          children: [
                            MetricCard(titulo: 'Veículos na frota', valor: '${frota.totalVeiculos}', icone: Icons.directions_car, onTap: () => _abrir(AppRoutes.veiculos)),
                            MetricCard(titulo: 'Rotas cadastradas', valor: '$_totalRotas', icone: Icons.alt_route, onTap: () => _abrir(AppRoutes.rotas)),
                            MetricCard(titulo: 'Leituras de telemetria', valor: '$_totalLeituras', icone: Icons.sensors, onTap: () => _abrir(AppRoutes.leituras)),
                            MetricCard(titulo: 'Pendentes de envio', valor: '$_pendentes', icone: Icons.cloud_upload_outlined, onTap: () => _abrir(AppRoutes.sincronizacao)),
                            MetricCard(titulo: 'Bateria média', valor: '${frota.calcularMediaBateria().toStringAsFixed(0)}%', icone: Icons.battery_charging_full),
                            MetricCard(titulo: 'Bateria baixa (<20%)', valor: '${frota.obterVeiculosComBateriaBaixa().length}', icone: Icons.battery_alert),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(AppRoutes.leituraForm),
        icon: const Icon(Icons.add),
        label: const Text('Nova leitura'),
      ),
    );
  }
}
