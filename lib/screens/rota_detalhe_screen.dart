import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/leitura_telemetria.dart';
import '../models/rota.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

/// Tela 6 - Detalhes da rota e leituras relacionadas (relacionamento 1:N).
class RotaDetalheScreen extends StatefulWidget {
  final String rotaId;
  const RotaDetalheScreen({super.key, required this.rotaId});

  @override
  State<RotaDetalheScreen> createState() => _RotaDetalheScreenState();
}

class _RotaDetalheScreenState extends State<RotaDetalheScreen> {
  Rota? _rota;
  List<LeituraTelemetria> _leituras = [];
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final deps = AppScope.of(context);
    final rota = await deps.rotas.buscarPorId(widget.rotaId);
    final leituras = await deps.telemetria.listarPorRota(widget.rotaId);
    if (!mounted) return;
    setState(() {
      _rota = rota;
      _leituras = leituras;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rota = _rota;
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (rota == null || rota.excluido) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rota')),
        body: const EmptyState(mensagem: 'Rota não encontrada.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(rota.id),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final salvou = await Navigator.pushNamed(context, AppRoutes.rotaForm, arguments: rota);
              if (salvou == true) _carregar();
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(
              child: DestaqueCard(
                sobretitulo: '${rota.id} · ${rota.ativa ? 'Ativa' : 'Inativa'}',
                titulo: '${rota.origem} → ${rota.destino}',
                trailing: SyncStatusIcon(sincronizado: rota.sincronizado),
                children: [
                  TrajetoOD(origem: rota.origem, destino: rota.destino, cor: AppColors.branco),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      DestaqueValor(valor: '${rota.distanciaKm.toStringAsFixed(1)} km', rotulo: 'Distância'),
                      DestaqueValor(valor: '${rota.tempoEstimadoMinutos.toStringAsFixed(0)} min', rotulo: 'Tempo estimado'),
                      DestaqueValor(valor: rota.calcularVelocidadeMedia().toStringAsFixed(0), rotulo: 'km/h médio'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: SecaoTitulo('Leituras nesta rota (${_leituras.length})')),
          ),
          if (_leituras.isEmpty)
            const SliverToBoxAdapter(child: EmptyState(mensagem: 'Nenhuma leitura vinculada.', icone: Icons.sensors_off))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.builder(
                itemCount: _leituras.length,
                itemBuilder: (context, i) {
                  final l = _leituras[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const IconTile(icone: Icons.sensors),
                      title: Text('${l.veiculoId} · ${l.velocidade.toStringAsFixed(0)} km/h'),
                      subtitle: Text('Bateria ${l.bateria.toStringAsFixed(0)}%'),
                      trailing: SyncStatusIcon(sincronizado: l.sincronizado),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.leituraDetalhe, arguments: l),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.leituraForm, arguments: rota.id);
          _carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova leitura'),
      ),
    );
  }
}
